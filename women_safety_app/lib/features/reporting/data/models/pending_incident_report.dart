class PendingIncidentReport {
  const PendingIncidentReport({
    required this.localId,
    required this.categoryCode,
    required this.locationTypeCode,
    required this.occurredAt,
    required this.latitude,
    required this.longitude,
    required this.approxAreaName,
    required this.wardOrDistrict,
    required this.description,
    required this.languageCode,
    required this.consentAcknowledged,
    required this.queuedAt,
  });

  final String localId;
  final String categoryCode;
  final String locationTypeCode;
  final DateTime occurredAt;
  final double latitude;
  final double longitude;
  final String approxAreaName;
  final String wardOrDistrict;
  final String description;
  final String languageCode;
  final bool consentAcknowledged;
  final DateTime queuedAt;

  Map<String, dynamic> toJson() {
    return {
      "local_id": localId,
      "category_code": categoryCode,
      "location_type_code": locationTypeCode,
      "occurred_at": occurredAt.toIso8601String(),
      "latitude": latitude,
      "longitude": longitude,
      "approx_area_name": approxAreaName,
      "ward_or_district": wardOrDistrict,
      "description": description,
      "language_code": languageCode,
      "consent_acknowledged": consentAcknowledged,
      "queued_at": queuedAt.toIso8601String(),
    };
  }

  factory PendingIncidentReport.fromJson(Map<String, dynamic> json) {
    return PendingIncidentReport(
      localId: json["local_id"] as String,
      categoryCode: json["category_code"] as String,
      locationTypeCode: json["location_type_code"] as String,
      occurredAt: DateTime.parse(json["occurred_at"] as String),
      latitude: (json["latitude"] as num).toDouble(),
      longitude: (json["longitude"] as num).toDouble(),
      approxAreaName: json["approx_area_name"] as String? ?? "",
      wardOrDistrict: json["ward_or_district"] as String? ?? "",
      description: json["description"] as String? ?? "",
      languageCode: json["language_code"] as String? ?? "en",
      consentAcknowledged:
          json["consent_acknowledged"] as bool? ?? false,
      queuedAt: DateTime.parse(json["queued_at"] as String),
    );
  }
}
