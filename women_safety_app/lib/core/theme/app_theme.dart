import 'package:flutter/material.dart';

import 'app_palette.dart';

class AppTheme {
  static ThemeData light(AppThemePreset preset) {
    return _build(
      visuals: AppPalette.visualsFor(preset, Brightness.light),
      brightness: Brightness.light,
    );
  }

  static ThemeData dark(AppThemePreset preset) {
    return _build(
      visuals: AppPalette.visualsFor(preset, Brightness.dark),
      brightness: Brightness.dark,
    );
  }

  static ThemeData _build({
    required AppThemeVisuals visuals,
    required Brightness brightness,
  }) {
    final isDark = brightness == Brightness.dark;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: visuals.primary,
      brightness: brightness,
    ).copyWith(
      primary: visuals.primary,
      secondary: visuals.blush,
      tertiary: visuals.accent,
      surface: visuals.cardSurface,
      onSurface: visuals.deep,
      error: visuals.accentGold,
    );

    final base = ThemeData(
      brightness: brightness,
      useMaterial3: true,
    );

    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: visuals.pageBackground,
      textTheme: base.textTheme.apply(
        bodyColor: visuals.deep,
        displayColor: visuals.deep,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: visuals.deep,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: visuals.cardSurface,
        elevation: 0,
        shadowColor: visuals.cardShadow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: visuals.blush,
          foregroundColor: isDark ? visuals.deep : Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: visuals.primary,
          backgroundColor: visuals.cardSurface,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          side: BorderSide(color: visuals.primary.withValues(alpha: 0.22)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      checkboxTheme: const CheckboxThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(6)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: visuals.deep,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        behavior: SnackBarBehavior.floating,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? visuals.softSurface : visuals.muted,
        labelStyle: TextStyle(
          color: isDark ? visuals.blush : const Color(0xFFFBE4EE),
          fontWeight: FontWeight.w600,
          letterSpacing: 0.7,
        ),
        hintStyle: TextStyle(
          color: isDark ? visuals.muted : const Color(0xFFF5CBDD),
        ),
        prefixIconColor: isDark ? visuals.deep : Colors.white,
        suffixIconColor: isDark ? visuals.deep.withValues(alpha: 0.8) : Colors.white70,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(
            color: isDark
                ? visuals.primary.withValues(alpha: 0.25)
                : const Color(0x33FFFFFF),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(
            color: isDark ? visuals.primary : Colors.white,
            width: 1.6,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(color: visuals.accentGold),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(color: visuals.accentGold, width: 1.6),
        ),
        errorStyle: TextStyle(
          color: isDark ? visuals.accentGold : Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return visuals.primary;
          }
          return visuals.muted.withValues(alpha: 0.9);
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return visuals.primary.withValues(alpha: 0.35);
          }
          return visuals.softSurface;
        }),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return visuals.primary;
            }
            return visuals.cardSurface;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return Colors.white;
            }
            return visuals.deep;
          }),
          side: WidgetStatePropertyAll(
            BorderSide(color: visuals.primary.withValues(alpha: 0.24)),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
        ),
      ),
      extensions: [visuals],
    );
  }
}
