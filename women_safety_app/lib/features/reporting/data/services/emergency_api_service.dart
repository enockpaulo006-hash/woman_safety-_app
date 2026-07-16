import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../auth/data/services/auth_session_store.dart';
import '../../../../core/config/api_config.dart';
import '../models/emergency_sos_result.dart';
import 'package:flutter/foundation.dart';

class EmergencyApiService {
  static const _requestTimeout = Duration(seconds: 45);

  EmergencyApiService({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  Uri _uri(String path) => Uri.parse("${ApiConfig.baseUrl}$path");

  Future<EmergencySOSResult> sendEmergencySOS({
    required double latitude,
    required double longitude,
    double? accuracy,
    String? phoneNumber,
}) async {

  debugPrint("===== SENDING SOS =====");
  debugPrint("Latitude: $latitude");
  debugPrint("Longitude: $longitude");

  final payload = {
    "latitude": latitude,
    "longitude": longitude,
    "accuracy": accuracy,
    "phone_number": phoneNumber,
  };

  debugPrint(_uri("/emergency/sos/").toString());

  final session = await AuthSessionStore().loadSession();

if (session == null) {
  throw const EmergencyApiException(
    "Please sign in before sending an emergency SOS.",
  );
}

final headers = {
  "Content-Type": "application/json",
  "Authorization": "Token ${session.token}",
};

debugPrint("===== TOKEN =====");
debugPrint(session.token);

debugPrint("===== HEADERS =====");
debugPrint(headers.toString());

final response = await _client.post(
  _uri("/emergency/sos/"),
  headers: headers,
  body: jsonEncode(payload),
).timeout(_requestTimeout);

debugPrint("===== RESPONSE =====");
debugPrint("STATUS: ${response.statusCode}");
debugPrint("BODY: ${response.body}");

  final body = _decodeResponse(response);

  if (response.statusCode != 201) {
    throw EmergencyApiException(_extractErrorMessage(body));
  }

  return EmergencySOSResult.fromJson(body);
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
    }

    return "Unable to send emergency SOS.";
  }

  static bool isConnectivityError(Object error) {
    return error is TimeoutException ||
        error is SocketException ||
        error is http.ClientException;
  }
}

class EmergencyApiException implements Exception {
  const EmergencyApiException(this.message);

  final String message;

  @override
  String toString() => message;
}