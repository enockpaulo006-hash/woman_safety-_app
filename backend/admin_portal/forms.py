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

class EmergencyAssignmentForm(forms.Form):

    team_leader = forms.CharField(
        max_length=150,
        label="Team Leader",
    )

    patrol_vehicle = forms.CharField(
        max_length=50,
        label="Patrol Vehicle",
    )

    officer_count = forms.IntegerField(
        min_value=1,
        initial=2,
        label="Number of Officers",
    )

    dispatch_notes = forms.CharField(
        required=False,
        widget=forms.Textarea(attrs={"rows": 4}),
        label="Dispatch Notes",
    )