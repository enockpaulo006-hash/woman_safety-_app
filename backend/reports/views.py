from django.http import JsonResponse
from django.utils import timezone
from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import IncidentCategory, LocationType
from .serializers import (
    IncidentCategorySerializer,
    IncidentReportCreateSerializer,
    LocationTypeSerializer,
)


def api_home(request):
    return JsonResponse(
        {
            "message": "Women Safety backend is running.",
            "routes": {
                "admin": "/admin/",
                "health": "/api/v1/health/",
                "auth_register": "/api/v1/auth/register/",
                "auth_sign_in": "/api/v1/auth/sign-in/",
                "auth_me": "/api/v1/auth/me/",
                "incident_categories": "/api/v1/taxonomies/incident-categories/",
                "location_types": "/api/v1/taxonomies/location-types/",
                "submit_report": "/api/v1/reports/",
            },
        }
    )


class HealthCheckAPIView(APIView):
    permission_classes = [permissions.AllowAny]

    def get(self, request, *args, **kwargs):
        return Response(
            {
                "status": "ok",
                "service": "women_safety_backend",
                "timestamp": timezone.now().isoformat(),
            }
        )


class IncidentCategoryListAPIView(generics.ListAPIView):
    permission_classes = [permissions.AllowAny]
    serializer_class = IncidentCategorySerializer
    queryset = IncidentCategory.objects.filter(is_active=True).order_by("sort_order", "name")


class LocationTypeListAPIView(generics.ListAPIView):
    permission_classes = [permissions.AllowAny]
    serializer_class = LocationTypeSerializer
    queryset = LocationType.objects.filter(is_active=True).order_by("sort_order", "name")


class IncidentReportCreateAPIView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request, *args, **kwargs):
        serializer = IncidentReportCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        report = serializer.save()
        return Response(
            {
                "id": str(report.id),
                "public_reference": report.public_reference,
                "status": report.status,
                "message": "Report submitted successfully.",
            },
            status=status.HTTP_201_CREATED,
        )
