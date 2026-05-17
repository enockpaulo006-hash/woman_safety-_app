import 'dart:convert';
import 'dart:io';

import '../models/pending_incident_report.dart';

class OfflineReportStore {
  static const _fileName = "move_safety_pending_reports.json";

  Future<List<PendingIncidentReport>> loadPendingReports() async {
    try {
      final file = await _queueFile();
      if (!await file.exists()) {
        return const [];
      }

      final content = await file.readAsString();
      if (content.trim().isEmpty) {
        return const [];
      }

      final decoded = jsonDecode(content);
      if (decoded is! List) {
        return const [];
      }

      return decoded
          .map(
            (item) => PendingIncidentReport.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  Future<void> enqueueReport(PendingIncidentReport report) async {
    final reports = await loadPendingReports();
    final updatedReports = [...reports, report];
    await savePendingReports(updatedReports);
  }

  Future<void> savePendingReports(List<PendingIncidentReport> reports) async {
    final file = await _queueFile();
    final encodedReports = jsonEncode(
      reports.map((report) => report.toJson()).toList(growable: false),
    );
    await file.writeAsString(encodedReports, flush: true);
  }

  Future<File> _queueFile() async {
    final directory = Directory.systemTemp;
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    return File("${directory.path}${Platform.pathSeparator}$_fileName");
  }
}
