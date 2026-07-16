import uuid

from django.contrib.gis.geos import Point
from django.utils import timezone
from rest_framework import serializers

from .location_enrichment import resolve_location_context
from .models import (
    IncidentCategory,
    LocationType,
    IncidentReport,
    EmergencySOS,
    EmergencyStatusHistory,
)

class IncidentCategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = IncidentCategory
        fields = ("id", "code", "name", "description", "sort_order")


class LocationTypeSerializer(serializers.ModelSerializer):
    class Meta:
        model = LocationType
        fields = ("id", "code", "name", "description", "sort_order")


class IncidentReportCreateSerializer(serializers.Serializer):
    category_id = serializers.UUIDField()
    location_type_id = serializers.UUIDField(required=False, allow_null=True)
    occurred_at = serializers.DateTimeField()
    description = serializers.CharField(required=False, allow_blank=True, allow_null=True)
    latitude = serializers.FloatField()
    longitude = serializers.FloatField()
    approx_area_name = serializers.CharField(required=False, allow_blank=True, allow_null=True)
    ward_or_district = serializers.CharField(required=False, allow_blank=True, allow_null=True)
    language_code = serializers.CharField(required=False, max_length=10, default="en")
    consent_acknowledged = serializers.BooleanField()

    def validate_occurred_at(self, value):
        if value > timezone.now():
            raise serializers.ValidationError("Occurred time cannot be in the future.")
        return value

    def validate_latitude(self, value):
        if not -90 <= value <= 90:
            raise serializers.ValidationError("Latitude must be between -90 and 90.")
        return value

    def validate_longitude(self, value):
        if not -180 <= value <= 180:
            raise serializers.ValidationError("Longitude must be between -180 and 180.")
        return value

    def validate(self, attrs):
        if attrs["consent_acknowledged"] is not True:
            raise serializers.ValidationError(
                {"consent_acknowledged": "Consent must be acknowledged before submission."}
            )

        try:
            attrs["category"] = IncidentCategory.objects.get(
                id=attrs["category_id"],
                is_active=True,
            )
        except IncidentCategory.DoesNotExist as exc:
            raise serializers.ValidationError({"category_id": "Invalid incident category."}) from exc

        location_context = resolve_location_context(
            attrs["latitude"],
            attrs["longitude"],
        )
        attrs["resolved_ward_or_district"] = location_context.ward_or_district
        attrs["location_type"] = self._system_location_type(
            location_context.location_type_code,
        )

        return attrs

    def _system_location_type(self, code):
        fallback_codes = (code, "STREET", "OTHER")
        for fallback_code in fallback_codes:
            try:
                return LocationType.objects.get(
                    code=fallback_code,
                    is_active=True,
                )
            except LocationType.DoesNotExist:
                continue

        location_type = LocationType.objects.filter(is_active=True).order_by(
            "sort_order",
            "name",
        ).first()
        if location_type is None:
            raise serializers.ValidationError(
                {"location_type": "No active location type is configured."}
            )
        return location_type

    def create(self, validated_data):
        now = timezone.now()
        report = IncidentReport.objects.create(
            id=uuid.uuid4(),
            public_reference=f"P17-{now:%Y%m%d}-{uuid.uuid4().hex[:6].upper()}",
            category=validated_data["category"],
            location_type=validated_data["location_type"],
            occurred_at=validated_data["occurred_at"],
            reported_at=now,
            description=validated_data.get("description"),
            geom=Point(validated_data["longitude"], validated_data["latitude"], srid=4326),
            approx_area_name=validated_data.get("approx_area_name"),
            ward_or_district=validated_data["resolved_ward_or_district"],
            language_code=validated_data.get("language_code", "en"),
            consent_acknowledged=validated_data["consent_acknowledged"],
            status=IncidentReport.Status.SUBMITTED,
            created_at=now,
            updated_at=now,
        )
        return report

class EmergencySOSCreateSerializer(serializers.Serializer):
    latitude = serializers.FloatField()
    longitude = serializers.FloatField()
    accuracy = serializers.FloatField(required=False, allow_null=True)
    phone_number = serializers.CharField(
        required=False,
        allow_blank=True,
        allow_null=True,
        max_length=20,
    )
    def create(self, validated_data):
        request = self.context["request"]
        now = timezone.now()
        reference_number = (
            f"SOS-{now:%Y%m%d}-"
            f"{uuid.uuid4().hex[:6].upper()}"
        )
        emergency = EmergencySOS.objects.create(
            id=uuid.uuid4(),
            reference_number=reference_number,
            victim_id=request.user.id,
            phone_number=validated_data.get("phone_number"),
            latitude=validated_data["latitude"],
            longitude=validated_data["longitude"],
            accuracy=validated_data.get("accuracy"),
            status=EmergencySOS.Status.NEW,
            created_at=now,
            updated_at=now,
            is_active=True,
        )
        EmergencyStatusHistory.objects.create(
            id=uuid.uuid4(),
            emergency=emergency,
            previous_status=None,
            new_status=EmergencySOS.Status.NEW,
            note="Emergency SOS created.",
            changed_by=request.user.username,
            changed_at=now,
        )
        return emergency