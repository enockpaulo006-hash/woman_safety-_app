from django.contrib import admin
from .models import IncidentCategory, IncidentReport, LocationType


@admin.register(IncidentCategory)
class IncidentCategoryAdmin(admin.ModelAdmin):
    list_display = ("code", "name", "is_active", "sort_order")
    list_filter = ("is_active",)
    search_fields = ("code", "name")
    ordering = ("sort_order", "name")


@admin.register(LocationType)
class LocationTypeAdmin(admin.ModelAdmin):
    list_display = ("code", "name", "is_active", "sort_order")
    list_filter = ("is_active",)
    search_fields = ("code", "name")
    ordering = ("sort_order", "name")


@admin.register(IncidentReport)
class IncidentReportAdmin(admin.ModelAdmin):
    list_display = (
        "public_reference",
        "category",
        "location_type",
        "status",
        "occurred_at",
        "reported_at",
    )
    list_filter = ("status", "category", "location_type", "language_code")
    search_fields = (
        "public_reference",
        "description",
        "approx_area_name",
        "ward_or_district",
    )
    autocomplete_fields = ("category", "location_type", "duplicate_of_report")
    ordering = ("-reported_at",)
