class ReportSubmissionResult {
  const ReportSubmissionResult({
    required this.id,
    required this.publicReference,
    required this.status,
    required this.message,
  });

  final String id;
  final String publicReference;
  final String status;
  final String message;

  factory ReportSubmissionResult.fromJson(Map<String, dynamic> json) {
    return ReportSubmissionResult(
      id: json["id"] as String,
      publicReference: json["public_reference"] as String,
      status: json["status"] as String,
      message: json["message"] as String,
    );
  }

  factory ReportSubmissionResult.offlineQueued({
    required String localId,
    required int pendingCount,
  }) {
    final referenceSuffix = localId.length > 8
        ? localId.substring(localId.length - 8)
        : localId;

    final queueMessage = pendingCount == 1
        ? "Report saved on this phone and will sync when a connection is available."
        : "Report saved on this phone. Pending offline reports: $pendingCount.";

    return ReportSubmissionResult(
      id: localId,
      publicReference: "OFFLINE-$referenceSuffix",
      status: "queued offline",
      message: queueMessage,
    );
  }
}
