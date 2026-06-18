import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/pending_incident_report.dart';

class OfflineReportStore {
  static const _storageKey = "move_safety_pending_reports";
  static const _legacyFileName = "move_safety_pending_reports.json";
  static const _hotspotsKey = "move_safety_hotspots_cache";

  Future<List<PendingIncidentReport>> loadPendingReports() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      var content = preferences.getString(_storageKey);
      content ??= await _migrateLegacyReports(preferences);

      if (content == null || content.trim().isEmpty) {
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

  Future<void> savePendingReports(
    List<PendingIncidentReport> reports,
  ) async {
    final preferences = await SharedPreferences.getInstance();

    final encodedReports = jsonEncode(
      reports.map((report) => report.toJson()).toList(growable: false),
    );

    await preferences.setString(_storageKey, encodedReports);
  }

  Future<String?> _migrateLegacyReports(
    SharedPreferences preferences,
  ) async {
    try {
      final file = File(
        "${Directory.systemTemp.path}${Platform.pathSeparator}$_legacyFileName",
      );

      if (!await file.exists()) {
        return null;
      }

      final content = await file.readAsString();

      if (content.trim().isEmpty) {
        return null;
      }

      await preferences.setString(_storageKey, content);

      return content;
    } catch (_) {
      return null;
    }
  }

  Future<void> saveHotspots(
    Map<String, dynamic> hotspots,
  ) async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.setString(
      _hotspotsKey,
      jsonEncode(hotspots),
    );
  }

  Future<Map<String, dynamic>?> loadHotspots() async {
    try {
      final preferences = await SharedPreferences.getInstance();

      final cached = preferences.getString(_hotspotsKey);

      if (cached == null || cached.isEmpty) {
        return null;
      }

      return jsonDecode(cached) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}