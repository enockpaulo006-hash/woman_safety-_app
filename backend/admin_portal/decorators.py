from functools import wraps

from django.contrib.auth.views import redirect_to_login
from django.shortcuts import render

from .roles import portal_context


def portal_access_required(view_func):
    @wraps(view_func)
    def wrapped_view(request, *args, **kwargs):
        if not request.user.is_authenticated:
            return redirect_to_login(request.get_full_path(), login_url="/portal/login/")

        if not request.user.is_active or not request.user.is_staff:
            response = render(
                request,
                "admin_portal/access_denied.html",
                {
                    **portal_context(request, "access_denied"),
                    "page_title": "Access Denied",
                    "page_kicker": "Portal Access Required",
                    "page_summary": (
                        "You signed in successfully, but this account does not have "
                        "permission to use the Women Safety admin portal."
                    ),
                },
                status=403,
            )
            return response

        return view_func(request, *args, **kwargs)

    return wrapped_view
