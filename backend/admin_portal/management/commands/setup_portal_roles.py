from django.contrib.auth import get_user_model
from django.contrib.auth.models import Group
from django.core.management.base import BaseCommand

from admin_portal.roles import ROLE_LABELS


DEMO_USERS = {
    "portal_admin": {
        "username": "portal.admin",
        "email": "portal.admin@example.com",
        "password": "Admin@12345",
        "first_name": "Portal",
        "last_name": "Admin",
    },
    "moderator": {
        "username": "moderator.user",
        "email": "moderator@example.com",
        "password": "Moderator@12345",
        "first_name": "Report",
        "last_name": "Moderator",
    },
    "gis_analyst": {
        "username": "gis.analyst",
        "email": "gis.analyst@example.com",
        "password": "Gis@12345",
        "first_name": "GIS",
        "last_name": "Analyst",
    },
    "policy_officer": {
        "username": "policy.officer",
        "email": "policy.officer@example.com",
        "password": "Policy@12345",
        "first_name": "Policy",
        "last_name": "Officer",
    },
    "police_partner": {
        "username": "police.partner",
        "email": "police.partner@example.com",
        "password": "Police@12345",
        "first_name": "Police",
        "last_name": "Partner",
    },
    "tawla_partner": {
        "username": "tawla.partner",
        "email": "tawla.partner@example.com",
        "password": "Tawla@12345",
        "first_name": "TAWLA",
        "last_name": "Partner",
    },
    "researcher": {
        "username": "researcher.user",
        "email": "researcher@example.com",
        "password": "Researcher@12345",
        "first_name": "ARU",
        "last_name": "Researcher",
    },
}


class Command(BaseCommand):
    help = "Create admin portal role groups and optional demo staff users."

    def add_arguments(self, parser):
        parser.add_argument(
            "--demo-users",
            action="store_true",
            help="Create one staff user for each portal role.",
        )

    def handle(self, *args, **options):
        groups = {}
        for role, label in ROLE_LABELS.items():
            group, created = Group.objects.get_or_create(name=role)
            groups[role] = group
            status = "created" if created else "exists"
            self.stdout.write(f"{status}: {role} - {label}")

        if not options["demo_users"]:
            self.stdout.write(self.style.SUCCESS("Portal role groups are ready."))
            return

        User = get_user_model()
        for role, details in DEMO_USERS.items():
            user, created = User.objects.get_or_create(
                username=details["username"],
                defaults={
                    "email": details["email"],
                    "first_name": details["first_name"],
                    "last_name": details["last_name"],
                    "is_staff": True,
                    "is_active": True,
                },
            )
            user.email = details["email"]
            user.first_name = details["first_name"]
            user.last_name = details["last_name"]
            user.is_staff = True
            user.is_active = True
            user.set_password(details["password"])
            user.save()
            user.groups.set([groups[role]])

            status = "created" if created else "updated"
            self.stdout.write(
                f"{status}: {details['username']} -> {role} "
                f"(password: {details['password']})"
            )

        self.stdout.write(self.style.SUCCESS("Portal demo users are ready."))
