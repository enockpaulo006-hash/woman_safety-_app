import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../theme/app_palette.dart';

enum AppLanguage {
  english(Locale('en')),
  swahili(Locale('sw'));

  const AppLanguage(this.locale);

  final Locale locale;
}

class AppSettingsController extends ChangeNotifier {
  static const _languageKey = "app_settings.language";
  static const _themeModeKey = "app_settings.theme_mode";
  static const _themePresetKey = "app_settings.theme_preset";
  static const _autoSyncKey = "app_settings.auto_sync";
  static const _locationHintsKey = "app_settings.location_hints";
  static const _privacyTipsKey = "app_settings.privacy_tips";
  static const _backendUrlKey = "app_settings.backend_url";

  AppLanguage _language = AppLanguage.english;
  ThemeMode _themeMode = ThemeMode.light;
  AppThemePreset _themePreset = AppThemePreset.roseDawn;
  bool _autoSyncEnabled = true;
  bool _locationHintsEnabled = true;
  bool _privacyTipsEnabled = true;
  String _backendUrl = ApiConfig.defaultBaseUrl;
  bool _isLoaded = false;
  SharedPreferences? _preferences;

  AppLanguage get language => _language;
  ThemeMode get themeMode => _themeMode;
  AppThemePreset get themePreset => _themePreset;
  bool get autoSyncEnabled => _autoSyncEnabled;
  bool get locationHintsEnabled => _locationHintsEnabled;
  bool get privacyTipsEnabled => _privacyTipsEnabled;
  String get backendUrl => _backendUrl;
  bool get isLoaded => _isLoaded;

  Future<void> load() async {
    _preferences ??= await SharedPreferences.getInstance();
    final preferences = _preferences!;

    _language = _appLanguageFromName(
      preferences.getString(_languageKey),
      fallback: _language,
    );
    _themeMode = _themeModeFromName(
      preferences.getString(_themeModeKey),
      fallback: _themeMode,
    );
    _themePreset = _themePresetFromName(
      preferences.getString(_themePresetKey),
      fallback: _themePreset,
    );
    _autoSyncEnabled = preferences.getBool(_autoSyncKey) ?? _autoSyncEnabled;
    _locationHintsEnabled =
        preferences.getBool(_locationHintsKey) ?? _locationHintsEnabled;
    _privacyTipsEnabled =
        preferences.getBool(_privacyTipsKey) ?? _privacyTipsEnabled;
    try {
      _backendUrl = ApiConfig.normalizeBaseUrl(
        preferences.getString(_backendUrlKey),
        fallback: ApiConfig.defaultBaseUrl,
      );
    } on FormatException {
      _backendUrl = ApiConfig.defaultBaseUrl;
    }
    ApiConfig.setSavedBaseUrl(_backendUrl);
    _isLoaded = true;
    notifyListeners();
  }

  void setLanguage(AppLanguage language) {
    if (_language == language) {
      return;
    }
    _language = language;
    notifyListeners();
    _saveString(_languageKey, language.name);
  }

  void setThemeMode(ThemeMode themeMode) {
    if (_themeMode == themeMode) {
      return;
    }
    _themeMode = themeMode;
    notifyListeners();
    _saveString(_themeModeKey, themeMode.name);
  }

  void setThemePreset(AppThemePreset themePreset) {
    if (_themePreset == themePreset) {
      return;
    }
    _themePreset = themePreset;
    notifyListeners();
    _saveString(_themePresetKey, themePreset.name);
  }

  void setAutoSyncEnabled(bool value) {
    if (_autoSyncEnabled == value) {
      return;
    }
    _autoSyncEnabled = value;
    notifyListeners();
    _saveBool(_autoSyncKey, value);
  }

  void setLocationHintsEnabled(bool value) {
    if (_locationHintsEnabled == value) {
      return;
    }
    _locationHintsEnabled = value;
    notifyListeners();
    _saveBool(_locationHintsKey, value);
  }

  void setPrivacyTipsEnabled(bool value) {
    if (_privacyTipsEnabled == value) {
      return;
    }
    _privacyTipsEnabled = value;
    notifyListeners();
    _saveBool(_privacyTipsKey, value);
  }

  Future<void> setBackendUrl(String value) async {
    final normalized = ApiConfig.normalizeBaseUrl(
      value,
      fallback: ApiConfig.defaultBaseUrl,
    );
    if (_backendUrl == normalized) {
      return;
    }

    _backendUrl = normalized;
    ApiConfig.setSavedBaseUrl(normalized);
    notifyListeners();
    await _saveString(_backendUrlKey, normalized);
  }

  Future<void> _saveString(String key, String value) async {
    _preferences ??= await SharedPreferences.getInstance();
    await _preferences!.setString(key, value);
  }

  Future<void> _saveBool(String key, bool value) async {
    _preferences ??= await SharedPreferences.getInstance();
    await _preferences!.setBool(key, value);
  }

  AppLanguage _appLanguageFromName(
    String? value, {
    required AppLanguage fallback,
  }) {
    if (value == null || value.isEmpty) {
      return fallback;
    }
    return AppLanguage.values.where((item) => item.name == value).firstOrNull ??
        fallback;
  }

  ThemeMode _themeModeFromName(
    String? value, {
    required ThemeMode fallback,
  }) {
    if (value == null || value.isEmpty) {
      return fallback;
    }
    return ThemeMode.values.where((item) => item.name == value).firstOrNull ??
        fallback;
  }

  AppThemePreset _themePresetFromName(
    String? value, {
    required AppThemePreset fallback,
  }) {
    if (value == null || value.isEmpty) {
      return fallback;
    }
    return AppThemePreset.values
            .where((item) => item.name == value)
            .firstOrNull ??
        fallback;
  }
}
