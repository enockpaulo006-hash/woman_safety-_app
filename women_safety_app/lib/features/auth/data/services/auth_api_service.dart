import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../../core/config/api_config.dart';
import '../models/auth_session.dart';

class AuthApiService {
  static const _requestTimeout = Duration(seconds: 8);

  AuthApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Uri _uri(String path) => Uri.parse("${ApiConfig.baseUrl}$path");

  Future<AuthSession> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final response = await _client
        .post(
          _uri("/auth/register/"),
          headers: const {"Content-Type": "application/json"},
          body: jsonEncode({
            "full_name": fullName.trim(),
            "email": email.trim(),
            "password": password,
          }),
        )
        .timeout(_requestTimeout);

    final body = _decodeResponse(response);
    if (response.statusCode != 201) {
      throw AuthApiException(_extractErrorMessage(body));
    }

    return AuthSession.fromAuthResponse(body as Map<String, dynamic>);
  }

  Future<AuthSession> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _client
        .post(
          _uri("/auth/sign-in/"),
          headers: const {"Content-Type": "application/json"},
          body: jsonEncode({
            "email": email.trim(),
            "password": password,
          }),
        )
        .timeout(_requestTimeout);

    final body = _decodeResponse(response);
    if (response.statusCode != 200) {
      throw AuthApiException(_extractErrorMessage(body));
    }

    return AuthSession.fromAuthResponse(body as Map<String, dynamic>);
  }

  Future<AuthSession> signInWithGoogle({
    required String idToken,
  }) async {
    final response = await _client
        .post(
          _uri("/auth/google/"),
          headers: const {"Content-Type": "application/json"},
          body: jsonEncode({
            "id_token": idToken,
          }),
        )
        .timeout(_requestTimeout);

    final body = _decodeResponse(response);
    if (response.statusCode != 200) {
      throw AuthApiException(_extractErrorMessage(body));
    }

    return AuthSession.fromAuthResponse(body as Map<String, dynamic>);
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

      if (body["non_field_errors"] is List && body["non_field_errors"].isNotEmpty) {
        return body["non_field_errors"].first.toString();
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

class AuthApiException implements Exception {
  const AuthApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

