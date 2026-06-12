import csv
from datetime import date, timedelta

from django.contrib import messages
from django.contrib.auth import login, logout
from django.db import DatabaseError
from django.db.models import Q
from django.http import HttpResponse
from django.shortcuts import get_object_or_404, redirect, render
from django.urls import reverse
from django.utils import timezone
from django.utils.dateparse import parse_date
from django.utils.http import url_has_allowed_host_and_scheme
from django.views.decorators.http import require_POST

from .decorators import portal_access_required
from .forms import PortalAuthenticationForm
from .roles import PortalRole, portal_context, role_required
from reports.models import IncidentCategory, IncidentReport, LocationType, ReportStatusHistory


def public_hotspot_map_view(request):
    return render(request, "admin_portal/public_hotspot_map.html", {
        "page_title": "Incident Hotspots",
    })


def _time_bucket(occurred_at):
    hour = occurred_at.hour
    if 5 <= hour < 12:
        return "morning"
    if 12 <= hour < 17:
        return "afternoon"
    if 17 <= hour < 21:
        return "evening"
    return "night"


def _top_items(items, limit=5):
    counts = {}
    for item in items:
        label = item or "Unspecified"
        counts[label] = counts.get(label, 0) + 1
    return [
        {"label": label, "count": count}
        for label, count in sorted(counts.items(), key=lambda entry: entry[1], reverse=True)[:limit]
    ]


def _with_percentages(items, total):
    if total <= 0:
        return [
            {
                **item,
                "percent": 0,
                "bar_width": 0,
            }
            for item in items
        ]
    return [
        {
            **item,
            "percent": round((item["count"] / total) * 100),
            "bar_width": max(round((item["count"] / total) * 100), 4),
        }
        for item in items
    ]


def _time_chart(time_counts, total):
    labels = {
        "morning": "Morning",
        "afternoon": "Afternoon",
        "evening": "Evening",
        "night": "Night",
    }
    return _with_percentages(
        [
            {"label": labels[key], "count": count}
            for key, count in time_counts.items()
        ],
        total,
    )


def _month_window(month_value):
    today = timezone.localdate()
    if month_value:
        try:
            year_text, month_text = month_value.split("-", 1)
            month_start = date(int(year_text), int(month_text), 1)
        except (TypeError, ValueError):
            month_start = date(today.year, today.month, 1)
    else:
        month_start = date(today.year, today.month, 1)

    if month_start.month == 12:
        next_month = date(month_start.year + 1, 1, 1)
    else:
        next_month = date(month_start.year, month_start.month + 1, 1)
    return month_start, next_month - timedelta(days=1)


def _brief_sentence(total_reports, top_categories, top_areas, time_counts, month_label):
    if total_reports == 0:
        return (
            f"No approved incidents are available for {month_label}. Moderation should "
            "continue so the next brief can rely on verified reports."
        )

    top_category = top_categories[0]["label"] if top_categories else "reported safety incidents"
    top_area = top_areas[0]["label"] if top_areas else "mapped public spaces"
    peak_time = max(time_counts, key=time_counts.get)
    return (
        f"In {month_label}, {total_reports} approved incident report"
        f"{'' if total_reports == 1 else 's'} were available for policy review. "
        f"The leading category was {top_category}, with the strongest location signal "
        f"around {top_area}. The busiest time window was {peak_time}, indicating where "
        "targeted patrols, lighting checks, and community outreach should be prioritised."
    )


def portal_login_view(request):
    if request.user.is_authenticated and request.user.is_staff:
        return redirect("admin-dashboard")

    form = PortalAuthenticationForm(request, data=request.POST or None)
    next_url = request.GET.get("next") or request.POST.get("next") or ""

    if request.method == "POST" and form.is_valid():
        login(request, form.get_user())
        if next_url and url_has_allowed_host_and_scheme(
            next_url,
            allowed_hosts={request.get_host()},
            require_https=request.is_secure(),
        ):
            return redirect(next_url)
        return redirect("admin-dashboard")

    return render(
        request,
        "admin_portal/login.html",
        {
            "page_title": "Portal Sign In",
            "page_name": "login",
            "form": form,
            "next_url": next_url,
        },
    )


@require_POST
def portal_logout_view(request):
    logout(request)
    return redirect("admin-login")


@portal_access_required
def dashboard_view(request):
    status_counts = {
        status_value: IncidentReport.objects.filter(status=status_value).count()
        for status_value, _ in IncidentReport.Status.choices
    }
    total_reports = sum(status_counts.values())
    approved_reports = (
        IncidentReport.objects.select_related("category", "location_type")
        .filter(status=IncidentReport.Status.APPROVED)
        .order_by("-reported_at")
    )
    recent_reports = (
        IncidentReport.objects.select_related("category", "location_type")
        .order_by("-reported_at")[:6]
    )
    approved_rows = [
        {
            "area": report.approx_area_name or report.ward_or_district or "Area context missing",
            "category": report.category.name,
            "location_type": report.location_type.name,
            "time_bucket": _time_bucket(report.occurred_at),
        }
        for report in approved_reports[:250]
    ]
    top_areas = _top_items([row["area"] for row in approved_rows], limit=4)
    top_categories = _top_items([row["category"] for row in approved_rows], limit=4)
    top_location_types = _top_items([row["location_type"] for row in approved_rows], limit=4)
    time_counts = {
        "morning": 0,
        "afternoon": 0,
        "evening": 0,
        "night": 0,
    }
    for row in approved_rows:
        time_counts[row["time_bucket"]] += 1

    return render(
        request,
        "admin_portal/dashboard.html",
        {
            **portal_context(request, "dashboard"),
            "page_title": "Dashboard",
            "page_kicker": "Start here",
            "page_summary": (
                "Use this page to choose your next task. The portal only shows "
                "the tools that match your assigned role."
            ),
            "status_counts": status_counts,
            "total_reports": total_reports,
            "approved_total": status_counts.get(IncidentReport.Status.APPROVED, 0),
            "pending_total": status_counts.get(IncidentReport.Status.SUBMITTED, 0)
            + status_counts.get(IncidentReport.Status.UNDER_REVIEW, 0),
            "rejected_total": status_counts.get(IncidentReport.Status.REJECTED, 0),
            "archived_total": status_counts.get(IncidentReport.Status.ARCHIVED, 0),
            "top_areas": top_areas,
            "top_categories": top_categories,
            "top_location_types": top_location_types,
            "time_chart": _time_chart(time_counts, len(approved_rows)),
            "recent_reports": recent_reports,
        },
    )


@portal_access_required
@role_required(PortalRole.ADMIN, PortalRole.MODERATOR)
def moderation_view(request):
    selected_status = request.GET.get("status", "all")
    selected_category = request.GET.get("category", "all")
    selected_location_type = request.GET.get("location_type", "all")
    quality_filter = request.GET.get("quality", "all")
    review_mode = request.GET.get("view", "single")

    reports = IncidentReport.objects.select_related("category", "location_type")

    if selected_status != "all":
        reports = reports.filter(status=selected_status)
    if selected_category != "all":
        reports = reports.filter(category_id=selected_category)
    if selected_location_type != "all":
        reports = reports.filter(location_type_id=selected_location_type)
    if quality_filter == "needs_context":
        reports = reports.filter(
            Q(approx_area_name__isnull=True) | Q(approx_area_name=""),
            Q(ward_or_district__isnull=True) | Q(ward_or_district=""),
        )

    status_counts = {
        status_value: IncidentReport.objects.filter(status=status_value).count()
        for status_value, _ in IncidentReport.Status.choices
    }
    total_reports = sum(status_counts.values())
    missing_context_count = IncidentReport.objects.filter(
        Q(approx_area_name__isnull=True) | Q(approx_area_name=""),
        Q(ward_or_district__isnull=True) | Q(ward_or_district=""),
    ).count()
    review_reports = list(reports.order_by("-reported_at")[:75])
    selected_report_id = request.GET.get("report", "")
    selected_report = review_reports[0] if review_reports else None
    selected_report_index = 0

    if selected_report_id:
        for index, report in enumerate(review_reports):
            if str(report.id) == selected_report_id:
                selected_report = report
                selected_report_index = index
                break

    def report_queue_url(report):
        query = request.GET.copy()
        if "view" in query:
            del query["view"]
        query["report"] = str(report.id)
        return f"{reverse('admin-moderation')}?{query.urlencode()}"

    review_all_query = request.GET.copy()
    if "report" in review_all_query:
        del review_all_query["report"]
    review_all_query["view"] = "all"
    review_all_url = f"{reverse('admin-moderation')}?{review_all_query.urlencode()}"

    single_review_query = request.GET.copy()
    if "view" in single_review_query:
        del single_review_query["view"]
    if selected_report is not None:
        single_review_query["report"] = str(selected_report.id)
    single_review_url = f"{reverse('admin-moderation')}?{single_review_query.urlencode()}"

    previous_report_url = ""
    next_report_url = ""
    if selected_report is not None:
        if selected_report_index > 0:
            previous_report_url = report_queue_url(review_reports[selected_report_index - 1])
        if selected_report_index + 1 < len(review_reports):
            next_report_url = report_queue_url(review_reports[selected_report_index + 1])

    return render(
        request,
        "admin_portal/moderation.html",
        {
            **portal_context(request, "moderation"),
            "page_title": "Review reports",
            "page_kicker": "Report decisions",
            "page_summary": (
                "Check submitted incident reports, record a clear decision, and "
                "approve only the records that should feed maps and briefs."
            ),
            "review_reports": review_reports,
            "show_all_reports": review_mode == "all",
            "review_all_url": review_all_url,
            "single_review_url": single_review_url,
            "selected_report": selected_report,
            "selected_report_position": selected_report_index + 1 if selected_report else 0,
            "review_reports_total": len(review_reports),
            "previous_report_url": previous_report_url,
            "next_report_url": next_report_url,
            "status_choices": IncidentReport.Status.choices,
            "status_counts": status_counts,
            "total_reports": total_reports,
            "missing_context_count": missing_context_count,
            "categories": IncidentCategory.objects.filter(is_active=True),
            "location_types": LocationType.objects.filter(is_active=True),
            "selected_status": selected_status,
            "selected_category": selected_category,
            "selected_location_type": selected_location_type,
            "quality_filter": quality_filter,
            "next_url": request.get_full_path(),
        },
    )


@require_POST
@portal_access_required
@role_required(PortalRole.ADMIN, PortalRole.MODERATOR)
def update_report_status_view(request, report_id):
    report = get_object_or_404(IncidentReport, id=report_id)
    new_status = request.POST.get("status")
    moderation_note = request.POST.get("moderation_note", "").strip()
    next_url = request.POST.get("next") or reverse("admin-moderation")
    valid_statuses = {status_value for status_value, _ in IncidentReport.Status.choices}

    if new_status not in valid_statuses:
        messages.error(request, "Choose a valid moderation status.")
        return redirect(next_url)

    previous_status = report.status
    if previous_status == new_status:
        messages.info(request, f"{report.public_reference} is already {report.get_status_display()}.")
        return redirect(next_url)

    report.status = new_status
    report.updated_at = timezone.now()
    report.save(update_fields=["status", "updated_at"])

    try:
        ReportStatusHistory.objects.create(
            report=report,
            previous_status=previous_status,
            new_status=new_status,
            moderation_note=moderation_note,
            changed_at=timezone.now(),
        )
    except DatabaseError:
        messages.warning(
            request,
            "Status updated, but the moderation history table could not be written.",
        )
    else:
        messages.success(
            request,
            f"{report.public_reference} moved to {report.get_status_display()}.",
        )

    return redirect(f"{reverse('admin-moderation')}?status={new_status}&report={report.id}")


@portal_access_required
@role_required(
    PortalRole.ADMIN,
    PortalRole.GIS_ANALYST,
    PortalRole.POLICY_OFFICER,
    PortalRole.POLICE_PARTNER,
    PortalRole.TAWLA_PARTNER,
    PortalRole.RESEARCHER,
)
def hotspot_map_view(request):
    selected_category = request.GET.get("category", "all")
    selected_location_type = request.GET.get("location_type", "all")
    selected_time_bucket = request.GET.get("time_bucket", "all")
    selected_date_from = request.GET.get("date_from", "")
    selected_date_to = request.GET.get("date_to", "")

    reports = IncidentReport.objects.select_related("category", "location_type").filter(
        status=IncidentReport.Status.APPROVED,
    )

    if selected_category != "all":
        reports = reports.filter(category_id=selected_category)
    if selected_location_type != "all":
        reports = reports.filter(location_type_id=selected_location_type)

    date_from = parse_date(selected_date_from) if selected_date_from else None
    date_to = parse_date(selected_date_to) if selected_date_to else None
    if date_from:
        reports = reports.filter(occurred_at__date__gte=date_from)
    if date_to:
        reports = reports.filter(occurred_at__date__lte=date_to)

    hotspot_reports = []
    for report in reports[:250]:
        if not report.geom:
            continue
        bucket = _time_bucket(report.occurred_at)
        if selected_time_bucket != "all" and bucket != selected_time_bucket:
            continue

        hotspot_reports.append(
            {
                "reference": report.public_reference,
                "category": report.category.name,
                "location_type": report.location_type.name,
                "area": report.approx_area_name or report.ward_or_district or "Area context missing",
                "occurred_at": report.occurred_at.strftime("%b %d, %Y %H:%M"),
                "latitude": float(report.geom.y),
                "longitude": float(report.geom.x),
                "time_bucket": bucket,
            }
        )

    time_counts = {
        "morning": 0,
        "afternoon": 0,
        "evening": 0,
        "night": 0,
    }
    for report in hotspot_reports:
        time_counts[report["time_bucket"]] += 1

    return render(
        request,
        "admin_portal/hotspot_map.html",
        {
            **portal_context(request, "hotspot_map"),
            "page_title": "Map hotspots",
            "page_kicker": "Approved report map",
            "page_summary": (
                "Explore approved reports by location, incident type, place type, "
                "and time period so response teams can see where attention is needed."
            ),
            "categories": IncidentCategory.objects.filter(is_active=True),
            "location_types": LocationType.objects.filter(is_active=True),
            "selected_category": selected_category,
            "selected_location_type": selected_location_type,
            "selected_time_bucket": selected_time_bucket,
            "selected_date_from": selected_date_from,
            "selected_date_to": selected_date_to,
            "hotspot_reports": hotspot_reports,
            "hotspot_total": len(hotspot_reports),
            "top_areas": _top_items([report["area"] for report in hotspot_reports]),
            "top_categories": _top_items([report["category"] for report in hotspot_reports]),
            "time_counts": time_counts,
        },
    )


def _build_brief_context(request):
    selected_month = request.GET.get("month", "")
    audience = request.GET.get("audience", "city_ngo")
    month_start, month_end = _month_window(selected_month)
    month_value = f"{month_start:%Y-%m}"
    month_label = f"{month_start:%B %Y}"

    reports = list(
        IncidentReport.objects.select_related("category", "location_type")
        .filter(
            status=IncidentReport.Status.APPROVED,
            occurred_at__date__gte=month_start,
            occurred_at__date__lte=month_end,
        )
        .order_by("occurred_at")
    )

    report_rows = []
    time_counts = {
        "morning": 0,
        "afternoon": 0,
        "evening": 0,
        "night": 0,
    }
    for report in reports:
        bucket = _time_bucket(report.occurred_at)
        time_counts[bucket] += 1
        report_rows.append(
            {
                "reference": report.public_reference,
                "category": report.category.name,
                "location_type": report.location_type.name,
                "area": report.approx_area_name or report.ward_or_district or "Area context missing",
                "occurred_at": report.occurred_at,
            }
        )

    top_categories = _top_items([row["category"] for row in report_rows])
    top_areas = _top_items([row["area"] for row in report_rows])
    top_location_types = _top_items([row["location_type"] for row in report_rows])
    total_reports = len(report_rows)
    area_chart = _with_percentages(top_areas, total_reports)
    category_chart = _with_percentages(top_categories, total_reports)
    location_type_chart = _with_percentages(top_location_types, total_reports)
    time_chart = _time_chart(time_counts, total_reports)
    peak_time = max(time_counts, key=time_counts.get) if total_reports else "none"
    summary_text = _brief_sentence(
        total_reports,
        top_categories,
        top_areas,
        time_counts,
        month_label,
    )
    recommendations = [
        "Prioritise field response around the highest-frequency hotspot areas.",
        "Use peak time windows to guide patrol timing, lighting audits, and transport safety checks.",
        "Share category-specific patterns with TAWLA, police partners, and city gender desk teams.",
    ]
    if top_categories:
        recommendations.insert(
            0,
            f"Design a focused response for {top_categories[0]['label']} reports.",
        )
    if top_areas:
        recommendations.insert(
            0,
            f"Review infrastructure and enforcement needs around {top_areas[0]['label']}.",
        )

    export_query = request.GET.urlencode()
    export_url = reverse("admin-briefs-export")
    if export_query:
        export_url = f"{export_url}?{export_query}"

    return {
            **portal_context(request, "briefs"),
            "page_title": "Create brief",
            "page_kicker": "Monthly summary",
            "page_summary": (
                "Turn approved incident data into a clear monthly summary for "
                "city council, TAWLA, police partners, and researchers."
            ),
            "selected_month": month_value,
            "month_label": month_label,
            "month_start": month_start,
            "month_end": month_end,
            "audience": audience,
            "total_reports": total_reports,
            "top_categories": top_categories,
            "top_areas": top_areas,
            "top_location_types": top_location_types,
            "area_chart": area_chart,
            "category_chart": category_chart,
            "location_type_chart": location_type_chart,
            "time_chart": time_chart,
            "time_counts": time_counts,
            "peak_time": peak_time,
            "summary_text": summary_text,
            "recommendations": recommendations[:5],
            "report_rows": report_rows[:25],
            "export_url": export_url,
    }


@portal_access_required
@role_required(
    PortalRole.ADMIN,
    PortalRole.POLICY_OFFICER,
    PortalRole.POLICE_PARTNER,
    PortalRole.TAWLA_PARTNER,
    PortalRole.RESEARCHER,
)
def briefs_view(request):
    context = _build_brief_context(request)
    return render(request, "admin_portal/briefs.html", context)


@portal_access_required
@role_required(
    PortalRole.ADMIN,
    PortalRole.POLICY_OFFICER,
    PortalRole.POLICE_PARTNER,
    PortalRole.TAWLA_PARTNER,
    PortalRole.RESEARCHER,
)
def briefs_export_view(request):
    context = _build_brief_context(request)
    month_slug = context["selected_month"] or timezone.localdate().strftime("%Y-%m")
    response = HttpResponse(content_type="text/csv")
    response["Content-Disposition"] = (
        f'attachment; filename="project17-policy-brief-{month_slug}.csv"'
    )
    writer = csv.writer(response)
    writer.writerow(["Project 17 Monthly Policy Brief"])
    writer.writerow(["Month", context["month_label"]])
    writer.writerow(["Audience", context["audience"]])
    writer.writerow(["Approved reports", context["total_reports"]])
    writer.writerow(["Peak time", context["peak_time"]])
    writer.writerow([])
    writer.writerow(["Executive summary"])
    writer.writerow([context["summary_text"]])
    writer.writerow([])
    writer.writerow(["Recommended actions"])
    for recommendation in context["recommendations"]:
        writer.writerow([recommendation])
    writer.writerow([])
    writer.writerow(["Reference", "Category", "Area", "Location Type", "Occurred"])
    for report in context["report_rows"]:
        writer.writerow(
            [
                report["reference"],
                report["category"],
                report["area"],
                report["location_type"],
                report["occurred_at"].strftime("%Y-%m-%d %H:%M"),
            ]
        )
    return response


@portal_access_required
@role_required(
    PortalRole.ADMIN,
    PortalRole.MODERATOR,
    PortalRole.POLICY_OFFICER,
    PortalRole.TAWLA_PARTNER,
    PortalRole.RESEARCHER,
)
def privacy_view(request):
    return render(
        request,
        "admin_portal/privacy.html",
        {
            **portal_context(request, "privacy"),
            "page_title": "Check privacy",
            "page_kicker": "Safe sharing checklist",
            "page_summary": (
                "Use this page before data is shared, printed, or exported so "
                "anonymous reports stay protected."
            ),
        },
    )
