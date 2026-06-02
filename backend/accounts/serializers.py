import json
from urllib import error as urllib_error
from urllib import parse as urllib_parse
from urllib import request as urllib_request

from django.conf import settings
from django.contrib.auth import authenticate, get_user_model
from django.db import transaction
from rest_framework import serializers
from rest_framework.authtoken.models import Token

from .models import GoogleAccount


User = get_user_model()
GOOGLE_ISSUERS = {"accounts.google.com", "https://accounts.google.com"}


def _normalized_email(value: str) -> str:
    return value.strip().lower()


def _is_truthy(value) -> bool:
    if isinstance(value, bool):
        return value
    return str(value).strip().lower() == "true"


def _google_client_ids() -> list[str]:
    return [
        value.strip()
        for value in getattr(settings, "GOOGLE_OAUTH_CLIENT_IDS", [])
        if value and value.strip()
    ]


def _verify_google_id_token(token: str) -> dict:
    client_ids = _google_client_ids()
    if not client_ids:
        raise serializers.ValidationError(
            "Google sign-in is not configured on the server."
        )

    query = urllib_parse.urlencode({"id_token": token})
    tokeninfo_url = f"https://oauth2.googleapis.com/tokeninfo?{query}"

    try:
        with urllib_request.urlopen(tokeninfo_url, timeout=8) as response:
            payload = json.loads(response.read().decode("utf-8"))
    except (urllib_error.HTTPError, urllib_error.URLError, json.JSONDecodeError):
        raise serializers.ValidationError(
            "Could not verify the Google account. Please try again."
        ) from None

    audience = str(payload.get("aud", "")).strip()
    issuer = str(payload.get("iss", "")).strip()
    email = _normalized_email(str(payload.get("email", "")))
    subject = str(payload.get("sub", "")).strip()

    if audience not in client_ids:
        raise serializers.ValidationError("Google token audience is not allowed.")
    if issuer not in GOOGLE_ISSUERS:
        raise serializers.ValidationError("Google token issuer is invalid.")
    if not _is_truthy(payload.get("email_verified")):
        raise serializers.ValidationError("Google account email is not verified.")
    if not email or not subject:
        raise serializers.ValidationError(
            "Google account did not return enough profile information."
        )

    payload["email"] = email
    payload["sub"] = subject
    return payload


def _display_name_from_google(payload: dict) -> str:
    candidates = [
        payload.get("name"),
        payload.get("given_name"),
        payload.get("email"),
    ]
    for candidate in candidates:
        value = str(candidate or "").strip()
        if value:
            return value[:150]
    return "Google User"


class AuthenticatedUserSerializer(serializers.ModelSerializer):
    full_name = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = ("id", "full_name", "email")

    def get_full_name(self, obj) -> str:
        return (obj.first_name or obj.get_full_name() or obj.username).strip()


class RegisterSerializer(serializers.Serializer):
    full_name = serializers.CharField(max_length=150)
    email = serializers.EmailField()
    password = serializers.CharField(min_length=6, max_length=128, write_only=True)

    def validate_full_name(self, value):
        full_name = value.strip()
        if len(full_name) < 3:
            raise serializers.ValidationError("Full name is too short.")
        return full_name

    def validate_email(self, value):
        email = _normalized_email(value)
        if User.objects.filter(username__iexact=email).exists():
            raise serializers.ValidationError("An account with this email already exists.")
        return email

    def create(self, validated_data):
        user = User.objects.create_user(
            username=validated_data["email"],
            email=validated_data["email"],
            first_name=validated_data["full_name"],
            password=validated_data["password"],
        )
        token, _ = Token.objects.get_or_create(user=user)
        return {"token": token.key, "user": user}


class SignInSerializer(serializers.Serializer):
    email = serializers.EmailField()
    password = serializers.CharField(max_length=128, write_only=True)

    def validate_email(self, value):
        return _normalized_email(value)

    def validate(self, attrs):
        request = self.context.get("request")
        user = authenticate(
            request=request,
            username=attrs["email"],
            password=attrs["password"],
        )
        if user is None:
            raise serializers.ValidationError("Invalid email or password.")
        if not user.is_active:
            raise serializers.ValidationError("This account is inactive.")
        attrs["user"] = user
        return attrs

    def create(self, validated_data):
        token, _ = Token.objects.get_or_create(user=validated_data["user"])
        return {"token": token.key, "user": validated_data["user"]}


class GoogleSignInSerializer(serializers.Serializer):
    id_token = serializers.CharField(max_length=4096, write_only=True)

    def validate_id_token(self, value):
        token = value.strip()
        if not token:
            raise serializers.ValidationError("Google token is required.")
        return token

    def validate(self, attrs):
        attrs["google_payload"] = _verify_google_id_token(attrs["id_token"])
        return attrs

    @transaction.atomic
    def create(self, validated_data):
        google_payload = validated_data["google_payload"]
        email = google_payload["email"]
        subject = google_payload["sub"]
        display_name = _display_name_from_google(google_payload)
        picture_url = str(google_payload.get("picture", "")).strip()

        account = GoogleAccount.objects.select_related("user").filter(
            subject=subject
        ).first()

        if account is not None:
            user = account.user
        else:
            user = User.objects.filter(username__iexact=email).first()
            if user is not None:
                linked_account = getattr(user, "google_account", None)
                if linked_account is not None and linked_account.subject != subject:
                    raise serializers.ValidationError(
                        "This account is already linked to another Google profile."
                    )
            else:
                user = User(
                    username=email,
                    email=email,
                    first_name=display_name,
                )
                user.set_unusable_password()
                user.save()

            account = GoogleAccount.objects.create(
                user=user,
                subject=subject,
                email=email,
                picture_url=picture_url,
            )

        user_changed = False
        if user.email != email:
            user.email = email
            user_changed = True
        if display_name and user.first_name != display_name:
            user.first_name = display_name
            user_changed = True
        if not user.username:
            user.username = email
            user_changed = True
        if user_changed:
            user.save()

        account_changed = False
        if account.email != email:
            account.email = email
            account_changed = True
        if account.picture_url != picture_url:
            account.picture_url = picture_url
            account_changed = True
        if account.user_id != user.id:
            account.user = user
            account_changed = True
        if account_changed:
            account.save()

        token, _ = Token.objects.get_or_create(user=user)
        return {"token": token.key, "user": user}
