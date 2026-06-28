from functools import wraps

from django.shortcuts import render


class PortalRole:
    ADMIN = "portal_admin"
    MODERATOR = "moderator"
    GIS_ANALYST = "gis_analyst"
    POLICY_OFFICER = "policy_officer"
    POLICE_PARTNER = "police_partner"
    TAWLA_PARTNER = "tawla_partner"
    RESEARCHER = "researcher"


ROLE_LABELS = {
    PortalRole.ADMIN: "Administrator",
    PortalRole.MODERATOR: "Report reviewer",
    PortalRole.GIS_ANALYST: "Map analyst",
    PortalRole.POLICY_OFFICER: "Policy officer",
    PortalRole.POLICE_PARTNER: "Police partner",
    PortalRole.TAWLA_PARTNER: "TAWLA partner",
    PortalRole.RESEARCHER: "Researcher",
}


WORKFLOW_STEPS = [
    {
        "key": "dashboard",
        "label": "Start",
        "title": "Dashboard",
        "description": "Choose the right task and see the latest report totals.",
        "url_name": "admin-dashboard",
        "roles": set(ROLE_LABELS),
    },
    {
        "key": "moderation",
        "label": "Review",
        "title": "Review reports",
        "description": "Check new reports and decide what can be used.",
        "url_name": "admin-moderation",
        "roles": {PortalRole.ADMIN, PortalRole.MODERATOR},
    },
    {
        "key": "hotspot_map",
        "label": "Map",
        "title": "Map hotspots",
        "description": "View approved incidents by place, category, and time.",
        "url_name": "admin-hotspot-map",
        "roles": {
            PortalRole.ADMIN,
            PortalRole.GIS_ANALYST,
            PortalRole.POLICY_OFFICER,
            PortalRole.POLICE_PARTNER,
            PortalRole.TAWLA_PARTNER,
            PortalRole.RESEARCHER,
        },
    },
    {
        "key": "briefs",
        "label": "Brief",
        "title": "Create brief",
        "description": "Prepare monthly summaries for partners and leaders.",
        "url_name": "admin-briefs",
        "roles": {
            PortalRole.ADMIN,
            PortalRole.POLICY_OFFICER,
            PortalRole.POLICE_PARTNER,
            PortalRole.TAWLA_PARTNER,
            PortalRole.RESEARCHER,
        },
    },
    {
        "key": "privacy",
        "label": "Privacy",
        "title": "Check privacy",
        "description": "Confirm data is safe before sharing or exporting.",
        "url_name": "admin-privacy",
        "roles": {
            PortalRole.ADMIN,
            PortalRole.MODERATOR,
            PortalRole.POLICY_OFFICER,
            PortalRole.TAWLA_PARTNER,
            PortalRole.RESEARCHER,
        },
    },
]


def user_portal_roles(user):
    if not user.is_authenticated:
        return set()
    if user.is_superuser:
        return set(ROLE_LABELS)

    group_names = set(user.groups.values_list("name", flat=True))
    roles = {role for role in ROLE_LABELS if role in group_names}

    return roles


def user_can_access_step(user, step):
    roles = user_portal_roles(user)
    return bool(roles.intersection(step["roles"]))


def allowed_workflow_steps(user):
    return [
        step
        for step in WORKFLOW_STEPS
        if user_can_access_step(user, step)
    ]


def role_required(*allowed_roles):
    def decorator(view_func):
        @wraps(view_func)
        def wrapped_view(request, *args, **kwargs):
            if not set(allowed_roles).intersection(user_portal_roles(request.user)):
                return render(
                    request,
                    "admin_portal/access_denied.html",
                    {
                        **portal_context(request, "access_denied"),
                        "page_title": "Access Denied",
                        "page_kicker": "Role Permission Required",
                        "page_summary": (
                            "Your account can sign in, but this page is hidden for "
                            "your assigned portal role."
                        ),
                    },
                    status=403,
                )
            return view_func(request, *args, **kwargs)

        return wrapped_view

    return decorator


def portal_context(request, page_name):
    steps = allowed_workflow_steps(request.user)
    current_index = next(
        (index for index, step in enumerate(steps) if step["key"] == page_name),
        None,
    )
    current_step = steps[current_index] if current_index is not None else None
    previous_step = steps[current_index - 1] if current_index and current_index > 0 else None
    next_step = (
        steps[current_index + 1]
        if current_index is not None and current_index + 1 < len(steps)
        else None
    )
    roles = user_portal_roles(request.user)

    return {
        "page_name": page_name,
        "portal_steps": steps,
        "current_step": current_step,
        "previous_step": previous_step,
        "next_step": next_step,
        "portal_roles": roles,
        "portal_role_labels": [ROLE_LABELS[role] for role in sorted(roles)],
        "key": "settings",
         "title": "Settings",
         "url_name": "admin-settings",

    }
