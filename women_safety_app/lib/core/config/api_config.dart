import 'package:flutter/foundation.dart';

class ApiConfig {
  // For USB testing on a physical Android phone, use `adb reverse tcp:8000 tcp:8000`
  // so the device can reach the backend through localhost.
  static const _phoneDevBaseUrl = "http://127.0.0.1:8000/api/v1";

  static String get baseUrl {
    const override = String.fromEnvironment("API_BASE_URL");
    if (override.isNotEmpty) {
      return override;
    }

    if (kIsWeb) {
      return "http://127.0.0.1:8000/api/v1";
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _phoneDevBaseUrl;
      default:
        return "http://127.0.0.1:8000/api/v1";
    }
  }
}
