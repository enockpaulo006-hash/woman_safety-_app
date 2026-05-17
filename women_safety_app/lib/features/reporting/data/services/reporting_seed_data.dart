import '../models/incident_category.dart';
import '../models/location_type.dart';

class ReportingSeedData {
  static const incidentCategories = [
    IncidentCategory(
      id: "VERBAL",
      code: "VERBAL",
      name: "Verbal harassment",
      description: "Insults, catcalling, or abusive verbal behavior.",
      sortOrder: 1,
    ),
    IncidentCategory(
      id: "STALKING",
      code: "STALKING",
      name: "Stalking or persistent following",
      description: "Following or monitoring a person without consent.",
      sortOrder: 2,
    ),
    IncidentCategory(
      id: "GESTURES",
      code: "GESTURES",
      name: "Unwanted sexual comments or gestures",
      description: "Sexualized gestures, sounds, or propositions.",
      sortOrder: 3,
    ),
    IncidentCategory(
      id: "TOUCHING",
      code: "TOUCHING",
      name: "Unwanted touching",
      description: "Non-consensual physical contact.",
      sortOrder: 4,
    ),
    IncidentCategory(
      id: "THREAT",
      code: "THREAT",
      name: "Physical intimidation or threat",
      description: "Threatening behavior or menacing conduct.",
      sortOrder: 5,
    ),
    IncidentCategory(
      id: "ASSAULT",
      code: "ASSAULT",
      name: "Physical assault",
      description: "Direct physical attack or violence.",
      sortOrder: 6,
    ),
    IncidentCategory(
      id: "AUTHORITY_ABUSE",
      code: "AUTHORITY_ABUSE",
      name: "Coercion, extortion, or abuse by authority figure",
      description:
          "Abuse involving transport staff, police, guards, or other authority figures.",
      sortOrder: 7,
    ),
    IncidentCategory(
      id: "OTHER",
      code: "OTHER",
      name: "Other gender-based safety incident",
      description: "Any incident not covered by the categories above.",
      sortOrder: 8,
    ),
  ];

  static const locationTypes = [
    LocationType(
      id: "STREET",
      code: "STREET",
      name: "Street or roadside",
      description: "Open roads, walkways, and roadside corridors.",
      sortOrder: 1,
    ),
    LocationType(
      id: "BUS_STOP",
      code: "BUS_STOP",
      name: "Bus stop or transport terminal",
      description: "Formal or informal transport waiting points.",
      sortOrder: 2,
    ),
    LocationType(
      id: "PUBLIC_TRANSPORT",
      code: "PUBLIC_TRANSPORT",
      name: "Public transport vehicle",
      description: "Buses, minibuses, taxis, or shared transport.",
      sortOrder: 3,
    ),
    LocationType(
      id: "MARKET",
      code: "MARKET",
      name: "Market or shopping area",
      description: "Markets, malls, shops, and busy trading areas.",
      sortOrder: 4,
    ),
    LocationType(
      id: "SCHOOL",
      code: "SCHOOL",
      name: "School or university area",
      description: "Education facilities and surrounding grounds.",
      sortOrder: 5,
    ),
    LocationType(
      id: "WORKPLACE",
      code: "WORKPLACE",
      name: "Workplace or office area",
      description: "Work-related locations and office zones.",
      sortOrder: 6,
    ),
    LocationType(
      id: "PARK",
      code: "PARK",
      name: "Park or recreation area",
      description: "Public gardens, fields, and recreation zones.",
      sortOrder: 7,
    ),
    LocationType(
      id: "ENTERTAINMENT",
      code: "ENTERTAINMENT",
      name: "Bar, club, or entertainment area",
      description: "Nightlife or leisure spaces.",
      sortOrder: 8,
    ),
    LocationType(
      id: "RESIDENTIAL",
      code: "RESIDENTIAL",
      name: "Residential area",
      description: "Neighborhoods and housing-adjacent public space.",
      sortOrder: 9,
    ),
    LocationType(
      id: "OTHER",
      code: "OTHER",
      name: "Other public space",
      description: "Any other public or semi-public location.",
      sortOrder: 10,
    ),
  ];

  const ReportingSeedData._();
}
