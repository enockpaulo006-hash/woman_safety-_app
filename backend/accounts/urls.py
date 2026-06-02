from django.urls import path

from .views import (
    CurrentUserAPIView,
    GoogleSignInAPIView,
    RegisterAPIView,
    SignInAPIView,
)


urlpatterns = [
    path("register/", RegisterAPIView.as_view(), name="auth-register"),
    path("sign-in/", SignInAPIView.as_view(), name="auth-sign-in"),
    path("google/", GoogleSignInAPIView.as_view(), name="auth-google-sign-in"),
    path("me/", CurrentUserAPIView.as_view(), name="auth-me"),
]
