from datetime import timedelta
from uuid import uuid4

from django.contrib.auth import get_user_model
from django.contrib.auth.models import Group
from django.contrib.gis.geos import Point
from django.utils import timezone

from admin_portal.roles import PortalRole
from reports.models import IncidentCategory, IncidentReport, LocationType


User = get_user_model()


def get_first(queryset, code, fallback_index=0):
    item = queryset.filter(code=code).first()
    if item is not None:
        return item
    return queryset.order_by("sort_order", "name")[fallback_index]


def ensure_demo_staff():
    username = "demo.admin"
    user, created = User.objects.get_or_create(
        username=username,
        defaults={
            "email": "demo.admin@example.com",
            "first_name": "Demo Admin",
            "is_staff": True,
            "is_superuser": True,
        },
    )
    user.email = "demo.admin@example.com"
    user.first_name = "Demo Admin"
    user.is_staff = True
    user.is_superuser = True
    user.set_password("Admin@12345")
    user.save()
    portal_admin_group, _ = Group.objects.get_or_create(name=PortalRole.ADMIN)
    user.groups.add(portal_admin_group)
    return created


def ensure_demo_reports():
    now = timezone.now()
    categories = IncidentCategory.objects.filter(is_active=True)
    locations = LocationType.objects.filter(is_active=True)
    verbal = get_first(categories, "VERBAL")
    stalking = get_first(categories, "STALKING")
    touching = get_first(categories, "TOUCHING")
    threat = get_first(categories, "THREAT")
    bus_stop = get_first(locations, "BUS_STOP")
    market = get_first(locations, "MARKET")
    street = get_first(locations, "STREET")
    transport = get_first(locations, "PUBLIC_TRANSPORT")

    demo_rows = [
        {
            "reference": "P17-DEMO-001",
            "category": verbal,
            "location_type": bus_stop,
            "hours_ago": 3,
            "coords": (39.2695, -6.8235),
            "area": "Kariakoo",
            "district": "Ilala",
            "description": "Demo report: repeated verbal harassment near a bus stop.",
            "status": IncidentReport.Status.APPROVED,
        },
        {
            "reference": "P17-DEMO-002",
            "category": stalking,
            "location_type": market,
            "hours_ago": 20,
            "coords": (39.2803, -6.8194),
            "area": "Kivukoni Market",
            "district": "Ilala",
            "description": "Demo report: persistent following around a busy market area.",
            "status": IncidentReport.Status.APPROVED,
        },
        {
            "reference": "P17-DEMO-003",
            "category": touching,
            "location_type": transport,
            "hours_ago": 30,
            "coords": (39.2427, -6.7924),
            "area": "Magomeni",
            "district": "Kinondoni",
            "description": "Demo report: unwanted touching in public transport.",
            "status": IncidentReport.Status.APPROVED,
        },
        {
            "reference": "P17-DEMO-004",
            "category": threat,
            "location_type": street,
            "hours_ago": 52,
            "coords": (39.2182, -6.7741),
            "area": "Sinza",
            "district": "Kinondoni",
            "description": "Demo report: physical intimidation on a poorly lit street.",
            "status": IncidentReport.Status.UNDER_REVIEW,
        },
    ]

    created = 0
    updated = 0
    for row in demo_rows:
        occurred_at = now - timedelta(hours=row["hours_ago"])
        report, was_created = IncidentReport.objects.update_or_create(
            public_reference=row["reference"],
            defaults={
                "id": uuid4(),
                "category": row["category"],
                "location_type": row["location_type"],
                "occurred_at": occurred_at,
                "reported_at": occurred_at + timedelta(minutes=12),
                "description": row["description"],
                "geom": Point(row["coords"][0], row["coords"][1], srid=4326),
                "approx_area_name": row["area"],
                "ward_or_district": row["district"],
                "language_code": "en",
                "consent_acknowledged": True,
                "status": row["status"],
                "created_at": occurred_at + timedelta(minutes=12),
                "updated_at": now,
            },
        )
        if was_created:
            created += 1
        else:
            updated += 1

    return created, updated


staff_created = ensure_demo_staff()
created, updated = ensure_demo_reports()
print(f"demo_staff_created={staff_created}")
print(f"demo_reports_created={created}")
print(f"demo_reports_updated={updated}")
print(f"total_reports={IncidentReport.objects.count()}")
print(f"approved_reports={IncidentReport.objects.filter(status=IncidentReport.Status.APPROVED).count()}")
