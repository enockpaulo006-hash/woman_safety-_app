class EmergencySOSResult {
  const EmergencySOSResult({
    required this.id,
    required this.referenceNumber,
    required this.status,
    required this.message,
  });

  final String id;
  final String referenceNumber;
  final String status;
  final String message;

  factory EmergencySOSResult.fromJson(Map<String, dynamic> json) {
    return EmergencySOSResult(
      id: json["id"] as String,
      referenceNumber: json["reference_number"] as String,
      status: json["status"] as String,
      message: json["message"] as String,
    );
  }
}