import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/localization/app_strings.dart';
import 'core/settings/app_settings_controller.dart';
import 'core/settings/app_settings_scope.dart';
import 'core/theme/app_theme.dart';
import 'features/onboarding/presentation/welcome_page.dart';

class WomenSafetyApp extends StatefulWidget {
  const WomenSafetyApp({super.key});

  @override
  State<WomenSafetyApp> createState() => _WomenSafetyAppState();
}

class _WomenSafetyAppState extends State<WomenSafetyApp> {
  final _settingsController = AppSettingsController();

  @override
  void dispose() {
    _settingsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppSettingsScope(
      controller: _settingsController,
      child: AnimatedBuilder(
        animation: _settingsController,
        builder: (context, _) {
          final strings = AppStrings(_settingsController.language);

          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: strings.text('appTitle'),
            locale: _settingsController.language.locale,
            supportedLocales: AppLanguage.values
                .map((language) => language.locale)
                .toList(growable: false),
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            themeMode: _settingsController.themeMode,
            theme: AppTheme.light(_settingsController.themePreset),
            darkTheme: AppTheme.dark(_settingsController.themePreset),
            home: const WelcomePage(),
          );
        },
      ),
    );
  }
}
