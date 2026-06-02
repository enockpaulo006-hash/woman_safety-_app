from django import forms
from django.contrib.auth.forms import AuthenticationForm


class PortalAuthenticationForm(AuthenticationForm):
    username = forms.CharField(
        label="Email or username",
        widget=forms.TextInput(
            attrs={
                "autofocus": True,
                "autocomplete": "username",
                "placeholder": "Enter your username",
            }
        ),
    )
    password = forms.CharField(
        label="Password",
        strip=False,
        widget=forms.PasswordInput(
            attrs={
                "autocomplete": "current-password",
                "placeholder": "Enter your password",
            }
        ),
    )

    error_messages = {
        **AuthenticationForm.error_messages,
        "inactive": "This portal account is inactive.",
        "invalid_login": (
            "Enter a valid staff username and password. Both fields are case-sensitive."
        ),
    }

    def confirm_login_allowed(self, user):
        super().confirm_login_allowed(user)
        if not user.is_staff:
            raise forms.ValidationError(
                "This account does not have portal access.",
                code="portal_access_denied",
            )
