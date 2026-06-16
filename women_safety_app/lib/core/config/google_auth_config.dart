class GoogleAuthConfig {
  // Paste your Google web client ID here if you do not want to use
  // --dart-define=GOOGLE_SERVER_CLIENT_ID=...
  static const _defaultServerClientId = '';
  static const _serverClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
  );

  static String? get serverClientId {
    final candidate = _serverClientId.trim().isNotEmpty
        ? _serverClientId
        : _defaultServerClientId;
    final trimmed = candidate.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static bool get isConfigured => serverClientId != null;
}
oi