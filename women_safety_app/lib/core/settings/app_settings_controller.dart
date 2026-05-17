import 'package:flutter/material.dart';

import '../theme/app_palette.dart';

enum AppLanguage {
  english(Locale('en')),
  swahili(Locale('sw'));

  const AppLanguage(this.locale);

  final Locale locale;
}

class AppSettingsController extends ChangeNotifier {
  AppLanguage _language = AppLanguage.english;
  ThemeMode _themeMode = ThemeMode.light;
  AppThemePreset _themePreset = AppThemePreset.roseDawn;

  AppLanguage get language => _language;
  ThemeMode get themeMode => _themeMode;
  AppThemePreset get themePreset => _themePreset;

  void setLanguage(AppLanguage language) {
    if (_language == language) {
      return;
    }
    _language = language;
    notifyListeners();
  }

  void setThemeMode(ThemeMode themeMode) {
    if (_themeMode == themeMode) {
      return;
    }
    _themeMode = themeMode;
    notifyListeners();
  }

  void setThemePreset(AppThemePreset themePreset) {
    if (_themePreset == themePreset) {
      return;
    }
    _themePreset = themePreset;
    notifyListeners();
  }
}
