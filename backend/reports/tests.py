from types import SimpleNamespace
from unittest.mock import patch
import uuid

from django.test import SimpleTestCase
from django.utils import timezone

from .location_enrichment import LocationContext, resolve_location_context
from .models import IncidentReport
from .serializers import IncidentReportCreateSerializer


class LocationEnrichmentTests(SimpleTestCase):
    @patch("reports.location_enrichment._fetch_reverse_geocode_payload")
    def test_resolves_ward_and_street_context_from_reverse_geocode(self, fetch_payload):
        fetch_payload.return_value = {
            "class": "highway",
            "type": "primary",
            "display_name": "Mtaa Street, Kariakoo, Ilala",
            "address": {
                "road": "Mtaa Street",
                "ward": "Kariakoo",
                "city_district": "Ilala",
            },
        }

        context = resolve_location_context(-6.817, 39.28)

        self.assertEqual(context.ward_or_district, "Kariakoo")
        self.assertEqual(context.location_type_code, "STREET")

    @patch("reports.location_enrichment._fetch_reverse_geocode_payload")
    def test_uses_gps_fallback_when_reverse_geocode_has_no_area(self, fetch_payload):
        fetch_payload.return_value = {}

        context = resolve_location_context(-6.817234, 39.280456)

        self.assertEqual(context.ward_or_district, "GPS -6.81723, 39.28046")
        self.assertEqual(context.location_type_code, "STREET")


class IncidentReportCreateSerializerTests(SimpleTestCase):
    @patch("reports.serializers.IncidentReport.objects.create")
    @patch("reports.serializers.LocationType.objects.get")
    @patch("reports.serializers.IncidentCategory.objects.get")
    @patch("reports.serializers.resolve_location_context")
    def test_server_overwrites_client_location_fields(
        self,
        resolve_context,
        get_category,
        get_location_type,
        create_report,
    ):
        category = SimpleNamespace(id=uuid.uuid4(), code="VERBAL", name="Verbal")
        location_type = SimpleNamespace(id=uuid.uuid4(), code="STREET")
        get_category.return_value = category
        get_location_type.return_value = location_type
        resolve_context.return_value = LocationContext(
            ward_or_district="Kariakoo",
            location_type_code="STREET",
        )
        report_id = uuid.uuid4()
        create_report.return_value = SimpleNamespace(
            id=report_id,
            public_reference="P17-TEST",
            status=IncidentReport.Status.SUBMITTED,
        )

        serializer = IncidentReportCreateSerializer(
            data={
                "category_id": str(category.id),
                "location_type_id": str(uuid.uuid4()),
                "occurred_at": timezone.now().isoformat(),
                "description": "Client tried to set wrong location values.",
                "latitude": -6.817,
                "longitude": 39.28,
                "approx_area_name": "Near the market",
                "ward_or_district": "Client typed district",
                "consent_acknowledged": True,
            }
        )

        self.assertTrue(serializer.is_valid(), serializer.errors)
        serializer.save()

        created_kwargs = create_report.call_args.kwargs
        self.assertEqual(created_kwargs["location_type"], location_type)
        self.assertEqual(created_kwargs["ward_or_district"], "Kariakoo")
        self.assertEqual(created_kwargs["approx_area_name"], "Near the market")
        resolve_context.assert_called_once_with(-6.817, 39.28)
