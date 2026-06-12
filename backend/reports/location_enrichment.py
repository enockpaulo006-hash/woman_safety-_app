from dataclasses import dataclass
import json
from urllib import error as urllib_error
from urllib import parse as urllib_parse
from urllib import request as urllib_request

from django.conf import settings


DEFAULT_REVERSE_GEOCODE_URL = "https://nominatim.openstreetmap.org/reverse"
DEFAULT_REVERSE_GEOCODE_USER_AGENT = "ANONYMUS safety reports/1.0"


@dataclass(frozen=True)
class LocationContext:
    ward_or_district: str
    location_type_code: str


def resolve_location_context(latitude: float, longitude: float) -> LocationContext:
    payload = _fetch_reverse_geocode_payload(latitude, longitude)
    return _context_from_payload(payload, latitude, longitude)


def _fetch_reverse_geocode_payload(latitude: float, longitude: float) -> dict:
    if not getattr(settings, "REPORT_REVERSE_GEOCODING_ENABLED", True):
        return {}

    base_url = getattr(
        settings,
        "REPORT_REVERSE_GEOCODE_URL",
        DEFAULT_REVERSE_GEOCODE_URL,
    )
    timeout = getattr(settings, "REPORT_REVERSE_GEOCODE_TIMEOUT", 4)
    params = urllib_parse.urlencode(
        {
            "format": "jsonv2",
            "lat": f"{latitude:.7f}",
            "lon": f"{longitude:.7f}",
            "addressdetails": 1,
            "zoom": 18,
        }
    )
    request = urllib_request.Request(
        f"{base_url}?{params}",
        headers={
            "Accept": "application/json",
            "User-Agent": getattr(
                settings,
                "REPORT_REVERSE_GEOCODE_USER_AGENT",
                DEFAULT_REVERSE_GEOCODE_USER_AGENT,
            ),
        },
    )

    try:
        with urllib_request.urlopen(request, timeout=timeout) as response:
            if getattr(response, "status", 200) != 200:
                return {}
            payload = json.loads(response.read().decode("utf-8"))
    except (
        OSError,
        TimeoutError,
        ValueError,
        urllib_error.HTTPError,
        urllib_error.URLError,
    ):
        return {}

    return payload if isinstance(payload, dict) else {}


def _context_from_payload(
    payload: dict,
    latitude: float,
    longitude: float,
) -> LocationContext:
    address = payload.get("address")
    if not isinstance(address, dict):
        address = {}

    return LocationContext(
        ward_or_district=_ward_or_district_from_address(
            address,
            latitude,
            longitude,
        ),
        location_type_code=_location_type_code_from_payload(payload, address),
    )


def _ward_or_district_from_address(
    address: dict,
    latitude: float,
    longitude: float,
) -> str:
    for key in (
        "ward",
        "city_district",
        "district",
        "municipality",
        "county",
        "state_district",
        "suburb",
        "neighbourhood",
        "quarter",
        "city",
        "town",
        "village",
    ):
        value = str(address.get(key, "")).strip()
        if value:
            return value

    return f"GPS {latitude:.5f}, {longitude:.5f}"


def _location_type_code_from_payload(payload: dict, address: dict) -> str:
    text = " ".join(
        str(value)
        for value in (
            payload.get("class", ""),
            payload.get("type", ""),
            payload.get("name", ""),
            payload.get("display_name", ""),
            *address.values(),
        )
    ).lower()

    if _contains_any(text, ("bus stop", "bus station", "terminal", "station")):
        return "BUS_STOP"
    if _contains_any(text, ("market", "mall", "shop", "commercial")):
        return "MARKET"
    if _contains_any(text, ("school", "college", "university")):
        return "SCHOOL"
    if _contains_any(text, ("office", "workplace", "industrial")):
        return "WORKPLACE"
    if _contains_any(text, ("park", "garden", "recreation")):
        return "PARK"
    if _contains_any(text, ("bar", "club", "pub", "nightclub", "entertainment")):
        return "ENTERTAINMENT"
    if any(str(address.get(key, "")).strip() for key in ("road", "pedestrian", "footway", "path", "cycleway")):
        return "STREET"
    if _contains_any(text, ("street", "road", "highway", "footway", "path")):
        return "STREET"
    if _contains_any(text, ("residential", "neighbourhood", "suburb")):
        return "RESIDENTIAL"

    return "STREET"


def _contains_any(value: str, candidates: tuple[str, ...]) -> bool:
    return any(candidate in value for candidate in candidates)
