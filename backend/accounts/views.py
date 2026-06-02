from rest_framework import permissions, status
from rest_framework.authentication import TokenAuthentication
from rest_framework.response import Response
from rest_framework.views import APIView

from .serializers import (
    AuthenticatedUserSerializer,
    GoogleSignInSerializer,
    RegisterSerializer,
    SignInSerializer,
)


def _auth_response_payload(*, token: str, user, message: str) -> dict:
    return {
        "token": token,
        "user": AuthenticatedUserSerializer(user).data,
        "message": message,
    }


class RegisterAPIView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request, *args, **kwargs):
        serializer = RegisterSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        payload = serializer.save()
        return Response(
            _auth_response_payload(
                token=payload["token"],
                user=payload["user"],
                message="Account created successfully.",
            ),
            status=status.HTTP_201_CREATED,
        )


class SignInAPIView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request, *args, **kwargs):
        serializer = SignInSerializer(data=request.data, context={"request": request})
        serializer.is_valid(raise_exception=True)
        payload = serializer.save()
        return Response(
            _auth_response_payload(
                token=payload["token"],
                user=payload["user"],
                message="Signed in successfully.",
            ),
        )


class GoogleSignInAPIView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request, *args, **kwargs):
        serializer = GoogleSignInSerializer(data=request.data, context={"request": request})
        serializer.is_valid(raise_exception=True)
        payload = serializer.save()
        return Response(
            _auth_response_payload(
                token=payload["token"],
                user=payload["user"],
                message="Google sign-in completed successfully.",
            ),
        )


class CurrentUserAPIView(APIView):
    authentication_classes = [TokenAuthentication]
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, *args, **kwargs):
        return Response(
            {
                "user": AuthenticatedUserSerializer(request.user).data,
            }
        )
