from django.urls import path
from .views import (
    HealthCheckAPIView,
    IncidentCategoryListAPIView,
    IncidentReportCreateAPIView,
    EmergencySOSCreateAPIView,
    EmergencySOSStatusAPIView,
    EmergencySOSCancelAPIView,
    LocationTypeListAPIView,
    HotspotAPIView,
)


urlpatterns = [
    path(
        "health/",
        HealthCheckAPIView.as_view(),
        name="health-check",
    ),
    path(
        "taxonomies/incident-categories/",
        IncidentCategoryListAPIView.as_view(),
        name="incident-category-list",
    ),
    path(
        "taxonomies/location-types/",
        LocationTypeListAPIView.as_view(),
        name="location-type-list",
    ),
    path(
        "reports/",
        IncidentReportCreateAPIView.as_view(),
        name="incident-report-create",
    ),
    path(
    "emergency/sos/",
    EmergencySOSCreateAPIView.as_view(),
    name="emergency-sos-create",
    ),
    path(
        "hotspots/",
        HotspotAPIView.as_view(),
        name="hotspot-data",
    ),
    path(
    "emergency/sos/<uuid:emergency_id>/status/",
    EmergencySOSStatusAPIView.as_view(),
    name="emergency-sos-status",
    ),
    
    path(
    "emergency/sos/<uuid:emergency_id>/cancel/",
    EmergencySOSCancelAPIView.as_view(),
    name="emergency-sos-cancel",
    ),
]
