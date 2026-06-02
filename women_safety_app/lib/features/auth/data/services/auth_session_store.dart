import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/auth_session.dart';

class AuthSessionStore {
  static const _sessionKey = "women_safety_auth_session";

  Future<AuthSession?> loadSession() async {
    final preferences = await SharedPreferences.getInstance();
    final rawSession = preferences.getString(_sessionKey);
    if (rawSession == null || rawSession.trim().isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(rawSession);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      return AuthSession.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveSession(AuthSession session) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_sessionKey, jsonEncode(session.toJson()));
  }

  Future<void> clearSession() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_sessionKey);
  }
}
