from django.http import JsonResponse
from django.utils import timezone
from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView
from .models import EmergencySOS
from .serializers import EmergencySOSCreateSerializer
from .models import IncidentCategory, LocationType, IncidentReport
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

class EmergencySOSCreateAPIView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, *args, **kwargs):
        serializer = EmergencySOSCreateSerializer(
            data=request.data,
            context={"request": request},
        )

        serializer.is_valid(raise_exception=True)
        emergency = serializer.save()

        return Response(
            {
                "id": str(emergency.id),
                "reference_number": emergency.reference_number,
                "status": emergency.status,
                "message": "Emergency SOS sent successfully.",
            },
            status=status.HTTP_201_CREATED,
        )


class HotspotAPIView(APIView):
    permission_classes = [permissions.AllowAny]

    def get(self, request, *args, **kwargs):
        category = request.GET.get("category", "all")

        reports = IncidentReport.objects.select_related(
            "category",
            "location_type",
        ).filter(status=IncidentReport.Status.APPROVED)

        if category != "all":
            reports = reports.filter(category_id=category)

        hotspot_data = []
        area_counts = {}
        category_counts = {}
        time_counts = {
            "morning": 0,
            "afternoon": 0,
            "evening": 0,
            "night": 0,
        }

        for report in reports[:500]:
            if not report.geom:
                continue

            lat = float(report.geom.y)
            lng = float(report.geom.x)

            hour = report.occurred_at.hour
            if 5 <= hour < 12:
                bucket = "morning"
            elif 12 <= hour < 17:
                bucket = "afternoon"
            elif 17 <= hour < 21:
                bucket = "evening"
            else:
                bucket = "night"

            time_counts[bucket] += 1

            area = (
                report.ward_or_district
                or report.approx_area_name
                or "Unknown"
            )

            area = (
                area.replace(" Municipal", "")
                .strip()
                .title()
            )

            if area.startswith("Gps"):
                continue

            area_counts[area] = area_counts.get(area, 0) + 1

            category_counts[report.category.name] = (
                category_counts.get(report.category.name, 0) + 1
            )

            hotspot_data.append(
                {
                    "id": str(report.id),
                    "public_reference": report.public_reference,
                    "category": report.category.name,
                    "location_type": report.location_type.name,
                    "area": area,
                    "occurred_at": report.occurred_at.isoformat(),
                    "latitude": lat,
                    "longitude": lng,
                    "time_bucket": bucket,
                }
            )

        top_areas = sorted(
            area_counts.items(),
            key=lambda item: item[1],
            reverse=True,
        )[:4]

        top_categories = sorted(
            category_counts.items(),
            key=lambda item: item[1],
            reverse=True,
        )[:4]

        return Response(
            {
                "reports": hotspot_data,
                "total": len(hotspot_data),
                "top_areas": [
                    {"label": label, "count": count}
                    for label, count in top_areas
                ],
                "top_categories": [
                    {"label": label, "count": count}
                    for label, count in top_categories
                ],
                "time_distribution": time_counts,
            }
        )