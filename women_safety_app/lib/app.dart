import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/localization/app_strings.dart';
import 'core/settings/app_settings_controller.dart';
import 'core/settings/app_settings_scope.dart';
import 'core/theme/app_palette.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/models/auth_session.dart';
import 'features/auth/data/services/auth_session_store.dart';
import 'features/onboarding/presentation/welcome_page.dart';
import 'features/reporting/presentation/report_home_page.dart';

class WomenSafetyApp extends StatefulWidget {
  const WomenSafetyApp({super.key});

  @override
  State<WomenSafetyApp> createState() => _WomenSafetyAppState();
}

class _WomenSafetyAppState extends State<WomenSafetyApp> {
  final _settingsController = AppSettingsController();
  final _navigatorKey = GlobalKey<NavigatorState>();
  final _sessionStore = AuthSessionStore();

  AuthSession? _session;
  bool _isBootstrapping = true;

  @override
  void initState() {
    super.initState();
    _bootstrapApp();
  }

  @override
  void dispose() {
    _settingsController.dispose();
    super.dispose();
  }

  Future<void> _bootstrapApp() async {
    await _settingsController.load();
    final session = await _sessionStore.loadSession();
    if (!mounted) {
      return;
    }

    setState(() {
      _session = session;
      _isBootstrapping = false;
    });
  }

  Future<void> _handleAuthenticated(AuthSession session) async {
    await _sessionStore.saveSession(session);
    if (!mounted) {
      return;
    }

    setState(() {
      _session = session;
    });

    _navigatorKey.currentState?.popUntil((route) => route.isFirst);
  }

  Future<void> _handleLoggedOut() async {
    await _sessionStore.clearSession();
    if (!mounted) {
      return;
    }

    setState(() {
      _session = null;
    });

    _navigatorKey.currentState?.popUntil((route) => route.isFirst);
  }

  Widget _buildHome() {
    if (_isBootstrapping || !_settingsController.isLoaded) {
      return const _SessionBootstrapPage();
    }

    if (_session == null) {
      return WelcomePage(onAuthenticated: _handleAuthenticated);
    }

    return ReportHomePage(
      currentUser: _session!.user,
      onLogout: _handleLoggedOut,
    );
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
            navigatorKey: _navigatorKey,
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
            home: _buildHome(),
          );
        },
      ),
    );
  }
}

class _SessionBootstrapPage extends StatelessWidget {
  const _SessionBootstrapPage();

  @override
  Widget build(BuildContext context) {
    final strings = AppSettingsScope.stringsOf(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              context.appVisuals.bright,
              context.appVisuals.primary,
              context.appVisuals.deep,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                strings.text('sessionLoading'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
