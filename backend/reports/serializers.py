import uuid

from django.contrib.gis.geos import Point
from django.utils import timezone
from rest_framework import serializers

from .models import IncidentCategory, IncidentReport, LocationType


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
    location_type_id = serializers.UUIDField()
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

        try:
            attrs["location_type"] = LocationType.objects.get(
                id=attrs["location_type_id"],
                is_active=True,
            )
        except LocationType.DoesNotExist as exc:
            raise serializers.ValidationError({"location_type_id": "Invalid location type."}) from exc

        return attrs

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
            ward_or_district=validated_data.get("ward_or_district"),
            language_code=validated_data.get("language_code", "en"),
            consent_acknowledged=validated_data["consent_acknowledged"],
            status=IncidentReport.Status.SUBMITTED,
            created_at=now,
            updated_at=now,
        )
        return report
