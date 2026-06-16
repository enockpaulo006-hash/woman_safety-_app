import 'package:flutter/foundation.dart';

class ApiConfig {
  // Default to the USB-debugging route for real phones during local dev.
  // Run: adb reverse tcp:8000 tcp:8000
  // This can be overridden at runtime from app settings.
  static const _androidDeviceBaseUrl = "http://127.0.0.1:8000/api/v1";
  static const _localBaseUrl = "http://127.0.0.1:8000/api/v1";

  static const _obsoleteBundledBaseUrls = {
    "http://192.168.1.3:8000/api/v1",
    "http://172.17.16.69:8000/api/v1",
  };

  static String? _savedBaseUrl;

  static String get defaultBaseUrl {
    if (kIsWeb) {
      return _localBaseUrl;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _androidDeviceBaseUrl;
      default:
        return _localBaseUrl;
    }
  }

  static String get baseUrl {
    const override = String.fromEnvironment("API_BASE_URL");
    if (override.isNotEmpty) {
      return normalizeBaseUrl(override, fallback: defaultBaseUrl);
    }

    return _savedBaseUrl ?? defaultBaseUrl;
  }

  static void setSavedBaseUrl(String? value) {
    _savedBaseUrl = normalizeBaseUrl(value, fallback: defaultBaseUrl);
  }

  static bool isObsoleteBundledBaseUrl(String value) {
    return _obsoleteBundledBaseUrls.contains(
      normalizeBaseUrl(value, fallback: defaultBaseUrl),
    );
  }

  static String normalizeBaseUrl(String? value, {required String fallback}) {
    final rawValue = value?.trim() ?? "";
    if (rawValue.isEmpty) {
      return _trimTrailingSlash(fallback);
    }

    final candidate = rawValue.contains("://") ? rawValue : "http://$rawValue";
    final uri = Uri.tryParse(candidate);
    if (uri == null || uri.host.isEmpty) {
      throw const FormatException("Invalid backend URL.");
    }

    var path = uri.path.trim();
    final apiBaseIndex = path.indexOf("/api/v1");
    if (apiBaseIndex >= 0) {
      path = path.substring(apiBaseIndex, apiBaseIndex + 7);
    } else if (path.isEmpty || path == "/") {
      path = "/api/v1";
    } else {
      path = _trimTrailingSlash(path);
    }

    return _trimTrailingSlash(
      uri.replace(path: path, query: null, fragment: null).toString(),
    );
  }

  static String _trimTrailingSlash(String value) {
    return value.replaceFirst(RegExp(r"/+$"), "");
  }
}