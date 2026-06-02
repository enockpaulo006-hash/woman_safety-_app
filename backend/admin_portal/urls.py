from django.shortcuts import redirect
from django.urls import path

from .views import (
    briefs_export_view,
    briefs_view,
    dashboard_view,
    hotspot_map_view,
    moderation_view,
    portal_login_view,
    portal_logout_view,
    privacy_view,
    update_report_status_view,
)


urlpatterns = [
    path("login/", portal_login_view, name="admin-login"),
    path("logout/", portal_logout_view, name="admin-logout"),
    path("", dashboard_view, name="admin-dashboard"),
    path("moderation/", moderation_view, name="admin-moderation"),
    path(
        "moderation/<uuid:report_id>/status/",
        update_report_status_view,
        name="admin-report-status-update",
    ),
    path("hotspot-map/", hotspot_map_view, name="admin-hotspot-map"),
    path("briefs/", briefs_view, name="admin-briefs"),
    path("briefs/export.csv/", briefs_export_view, name="admin-briefs-export"),
    path("privacy/", privacy_view, name="admin-privacy"),
    path("brief/", lambda request: redirect("admin-briefs"), name="admin-brief"),
    path("berief/", lambda request: redirect("admin-briefs"), name="admin-brief-typo"),
]
