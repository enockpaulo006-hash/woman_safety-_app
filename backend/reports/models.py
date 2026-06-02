import uuid

from django.contrib.gis.db import models


class IncidentCategory(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    code = models.TextField(unique=True)
    name = models.TextField(unique=True)
    description = models.TextField(blank=True, null=True)
    is_active = models.BooleanField(default=True)
    sort_order = models.IntegerField(default=0)
    created_at = models.DateTimeField()

    class Meta:
        db_table = "incident_categories"
        managed = False
        ordering = ["sort_order", "name"]

    def __str__(self) -> str:
        return self.name


class LocationType(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    code = models.TextField(unique=True)
    name = models.TextField(unique=True)
    description = models.TextField(blank=True, null=True)
    is_active = models.BooleanField(default=True)
    sort_order = models.IntegerField(default=0)
    created_at = models.DateTimeField()

    class Meta:
        db_table = "location_types"
        managed = False
        ordering = ["sort_order", "name"]

    def __str__(self) -> str:
        return self.name


class IncidentReport(models.Model):
    class Status(models.TextChoices):
        SUBMITTED = "submitted", "Submitted"
        UNDER_REVIEW = "under_review", "Under review"
        APPROVED = "approved", "Approved"
        REJECTED = "rejected", "Rejected"
        ARCHIVED = "archived", "Archived"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    public_reference = models.TextField(unique=True)
    category = models.ForeignKey(
        IncidentCategory,
        on_delete=models.DO_NOTHING,
        db_column="category_id",
        related_name="reports",
    )
    location_type = models.ForeignKey(
        LocationType,
        on_delete=models.DO_NOTHING,
        db_column="location_type_id",
        related_name="reports",
    )
    occurred_at = models.DateTimeField()
    reported_at = models.DateTimeField()
    description = models.TextField(blank=True, null=True)
    geom = models.PointField(srid=4326)
    approx_area_name = models.TextField(blank=True, null=True)
    ward_or_district = models.TextField(blank=True, null=True)
    language_code = models.CharField(max_length=10, default="en")
    consent_acknowledged = models.BooleanField()
    status = models.CharField(
        max_length=20,
        choices=Status.choices,
        default=Status.SUBMITTED,
    )
    duplicate_of_report = models.ForeignKey(
        "self",
        on_delete=models.DO_NOTHING,
        db_column="duplicate_of_report_id",
        related_name="duplicate_reports",
        blank=True,
        null=True,
    )
    created_at = models.DateTimeField()
    updated_at = models.DateTimeField()

    class Meta:
        db_table = "incident_reports"
        managed = False
        ordering = ["-reported_at"]

    def __str__(self) -> str:
        return self.public_reference


class ReportStatusHistory(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    report = models.ForeignKey(
        IncidentReport,
        on_delete=models.CASCADE,
        db_column="report_id",
        related_name="status_history",
    )
    previous_status = models.CharField(
        max_length=20,
        choices=IncidentReport.Status.choices,
        blank=True,
        null=True,
    )
    new_status = models.CharField(
        max_length=20,
        choices=IncidentReport.Status.choices,
    )
    moderation_note = models.TextField(blank=True, null=True)
    changed_by_admin_id = models.UUIDField(blank=True, null=True)
    changed_at = models.DateTimeField()

    class Meta:
        db_table = "report_status_history"
        managed = False
        ordering = ["-changed_at"]

    def __str__(self) -> str:
        return f"{self.report.public_reference}: {self.previous_status} -> {self.new_status}"
