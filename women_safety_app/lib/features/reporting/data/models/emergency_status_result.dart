class EmergencyStatusResult {
  const EmergencyStatusResult({
    required this.id,
    required this.referenceNumber,
    required this.status,
    this.assignedOfficer,
    this.assignedAt,
    this.dispatchedAt,
    this.arrivedAt,
    this.resolvedAt,
    this.updatedAt,
  });

  final String id;
  final String referenceNumber;
  final String status;

  final String? assignedOfficer;
  final String? assignedAt;
  final String? dispatchedAt;
  final String? arrivedAt;
  final String? resolvedAt;
  final String? updatedAt;

  factory EmergencyStatusResult.fromJson(
    Map<String, dynamic> json,
  ) {
    return EmergencyStatusResult(
      id: json["id"] as String,
      referenceNumber: json["reference_number"] as String,
      status: json["status"] as String,
      assignedOfficer: json["assigned_officer"]?.toString(),
      assignedAt: json["assigned_at"]?.toString(),
      dispatchedAt: json["dispatched_at"]?.toString(),
      arrivedAt: json["arrived_at"]?.toString(),
      resolvedAt: json["resolved_at"]?.toString(),
      updatedAt: json["updated_at"]?.toString(),
    );
  }
}