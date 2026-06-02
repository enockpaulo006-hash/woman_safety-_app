import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../../core/config/api_config.dart';
import '../models/incident_category.dart';
import '../models/location_type.dart';
import '../models/report_submission_result.dart';

class ReportingApiService {
  static const _requestTimeout = Duration(seconds: 8);

  ReportingApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Uri _uri(String path) => Uri.parse("${ApiConfig.baseUrl}$path");

  Future<bool> isBackendAvailable() async {
    final response = await _client
        .get(_uri("/health/"))
        .timeout(_requestTimeout);

    if (response.statusCode != 200) {
      return false;
    }

    final body = _decodeResponse(response);
    return body is Map<String, dynamic> && body["status"] == "ok";
  }

  Future<List<IncidentCategory>> fetchIncidentCategories() async {
    final response = await _client
        .get(_uri("/taxonomies/incident-categories/"))
        .timeout(_requestTimeout);
    return _decodeList(
      response,
      (item) => IncidentCategory.fromJson(item),
    );
  }

  Future<List<LocationType>> fetchLocationTypes() async {
    final response = await _client
        .get(_uri("/taxonomies/location-types/"))
        .timeout(_requestTimeout);
    return _decodeList(
      response,
      (item) => LocationType.fromJson(item),
    );
  }

  Future<ReportSubmissionResult> submitReport({
    required String categoryId,
    required String locationTypeId,
    required DateTime occurredAt,
    required double latitude,
    required double longitude,
    required String approxAreaName,
    required String wardOrDistrict,
    required String description,
    required bool consentAcknowledged,
    String languageCode = "en",
  }) async {
    final response = await _client
        .post(
          _uri("/reports/"),
          headers: const {"Content-Type": "application/json"},
          body: jsonEncode(
            {
              "category_id": categoryId,
              "location_type_id": locationTypeId,
              "occurred_at": occurredAt.toUtc().toIso8601String(),
              "description": description.trim(),
              "latitude": latitude,
              "longitude": longitude,
              "approx_area_name": approxAreaName.trim(),
              "ward_or_district": wardOrDistrict.trim(),
              "language_code": languageCode,
              "consent_acknowledged": consentAcknowledged,
            },
          ),
        )
        .timeout(_requestTimeout);

    final body = _decodeResponse(response);
    if (response.statusCode != 201) {
      throw ReportingApiException(_extractErrorMessage(body));
    }

    return ReportSubmissionResult.fromJson(body);
  }

  List<T> _decodeList<T>(
    http.Response response,
    T Function(Map<String, dynamic> item) builder,
  ) {
    final body = _decodeResponse(response);
    if (response.statusCode != 200) {
      throw ReportingApiException(_extractErrorMessage(body));
    }
    if (body is! List) {
      throw const ReportingApiException("Unexpected response format.");
    }

    return body
        .map((item) => builder(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  dynamic _decodeResponse(http.Response response) {
    if (response.body.isEmpty) {
      return const {};
    }
    return jsonDecode(response.body);
  }

  String _extractErrorMessage(dynamic body) {
    if (body is Map<String, dynamic>) {
      if (body["detail"] is String) {
        return body["detail"] as String;
      }

      final firstEntry = body.entries.firstOrNull;
      if (firstEntry != null) {
        final value = firstEntry.value;
        if (value is List && value.isNotEmpty) {
          return value.first.toString();
        }
        if (value != null) {
          return value.toString();
        }
      }
    }
    return "Request failed. Please try again.";
  }

  static bool isConnectivityError(Object error) {
    return error is TimeoutException ||
        error is SocketException ||
        error is http.ClientException;
  }
}

class ReportingApiException implements Exception {
  const ReportingApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
