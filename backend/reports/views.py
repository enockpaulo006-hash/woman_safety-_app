from itertools import count

from django.http import JsonResponse
from django.utils import timezone
from django.shortcuts import get_object_or_404
from datetime import timedelta
from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView
from .models import EmergencySOS
from rest_framework.authentication import TokenAuthentication
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
    authentication_classes = [TokenAuthentication]
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, *args, **kwargs):
        print("========== REQUEST ==========")
        print("Authorization:", request.headers.get("Authorization"))
        print("User:", request.user)
        print("Auth:", request.auth)
        print("REQUEST DATA:", request.data)

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

class EmergencySOSStatusAPIView(APIView):
    authentication_classes = [TokenAuthentication]
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, emergency_id, *args, **kwargs):

        emergency = get_object_or_404(
            EmergencySOS,
            id=emergency_id,
        )

        return Response(
            {
                "id": str(emergency.id),
                "reference_number": emergency.reference_number,
                "status": emergency.status,
                "assigned_officer": emergency.assigned_officer,
                "assigned_at": emergency.assigned_at,
                "dispatched_at": emergency.dispatched_at,
                "arrived_at": emergency.arrived_at,
                "resolved_at": emergency.resolved_at,
                "updated_at": emergency.updated_at,
            }
        )

class EmergencySOSCancelAPIView(APIView):
    authentication_classes = [TokenAuthentication]
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, emergency_id, *args, **kwargs):

        emergency = get_object_or_404(
            EmergencySOS,
            id=emergency_id,
        )

        # Already finished?
        if emergency.status in [
            EmergencySOS.Status.RESOLVED,
            EmergencySOS.Status.CANCELLED,
        ]:
            return Response(
                {
                    "detail": "Emergency already closed."
                },
                status=status.HTTP_400_BAD_REQUEST,
            )

        # More than five minutes?
       
        created_at = emergency.created_at

        if timezone.is_naive(created_at):
                created_at = timezone.make_aware(
                    created_at,
                    timezone.get_current_timezone(),
        )   

        if timezone.now() > created_at + timedelta(minutes=5):
            return Response(
         {
            "detail": "Cancellation period has expired."
            },
        status=status.HTTP_400_BAD_REQUEST,
    )

        emergency.status = EmergencySOS.Status.CANCELLED
        emergency.updated_at = timezone.now()
        emergency.is_active = False
        emergency.save()

        return Response(
            {
                "status": emergency.status,
                "message": "Emergency cancelled successfully.",
            }
        )

class HotspotAPIView(APIView):
    permission_classes = [permissions.AllowAny]

    def get(self, request, *args, **kwargs):

        category = request.GET.get("category", "all")

        reports = IncidentReport.objects.select_related(
            "category",
            "location_type",
        ).filter(
            status=IncidentReport.Status.APPROVED
        )

        if category != "all":
            reports = reports.filter(category_id=category)

        area_counts = {}
        area_locations = {}
        category_counts = {}

        time_counts = {
            "morning": 0,
            "afternoon": 0,
            "evening": 0,
            "night": 0,
        }

        # -------------------------
        # Collect statistics
        # -------------------------

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

            if area not in area_locations:
                area_locations[area] = (lat, lng)

            category_name = report.category.name

            category_counts[category_name] = (
                category_counts.get(category_name, 0) + 1
            )

        # -------------------------
        # Build hotspot data
        # -------------------------

        hotspot_data = []

        for area, count in area_counts.items():

            lat, lng = area_locations[area]

            if count >= 6:
                radius = 150
                color = "#dc2626"
                risk = "High"

            elif count >= 3:
                radius = 90
                color = "#f97316"
                risk = "Medium"

            else:
                radius = 50
                color = "#facc15"
                risk = "Low"

            hotspot_data.append({
                "area": area,
                "latitude": lat,
                "longitude": lng,
                "report_count": count,
                "radius": radius,
                "color": color,
                "risk_level": risk,
            })

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
                    {
                        "label": label,
                        "count": count,
                    }
                    for label, count in top_areas
                ],
                "top_categories": [
                    {
                        "label": label,
                        "count": count,
                    }
                    for label, count in top_categories
                ],
                "time_distribution": time_counts,
            }
        )