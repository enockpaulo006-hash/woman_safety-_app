import 'package:flutter/material.dart';

enum AppThemePreset { roseDawn, oceanCalm, emeraldGlow }

@immutable
class AppThemeVisuals extends ThemeExtension<AppThemeVisuals> {
  const AppThemeVisuals({
    required this.pageBackground,
    required this.cardSurface,
    required this.softSurface,
    required this.primary,
    required this.bright,
    required this.deep,
    required this.muted,
    required this.blush,
    required this.accent,
    required this.accentGold,
    required this.navBackground,
    required this.cardShadow,
    required this.blobA,
    required this.blobB,
    required this.blobC,
  });

  final Color pageBackground;
  final Color cardSurface;
  final Color softSurface;
  final Color primary;
  final Color bright;
  final Color deep;
  final Color muted;
  final Color blush;
  final Color accent;
  final Color accentGold;
  final Color navBackground;
  final Color cardShadow;
  final Color blobA;
  final Color blobB;
  final Color blobC;

  Color get border => primary.withValues(alpha: 0.16);

  @override
  AppThemeVisuals copyWith({
    Color? pageBackground,
    Color? cardSurface,
    Color? softSurface,
    Color? primary,
    Color? bright,
    Color? deep,
    Color? muted,
    Color? blush,
    Color? accent,
    Color? accentGold,
    Color? navBackground,
    Color? cardShadow,
    Color? blobA,
    Color? blobB,
    Color? blobC,
  }) {
    return AppThemeVisuals(
      pageBackground: pageBackground ?? this.pageBackground,
      cardSurface: cardSurface ?? this.cardSurface,
      softSurface: softSurface ?? this.softSurface,
      primary: primary ?? this.primary,
      bright: bright ?? this.bright,
      deep: deep ?? this.deep,
      muted: muted ?? this.muted,
      blush: blush ?? this.blush,
      accent: accent ?? this.accent,
      accentGold: accentGold ?? this.accentGold,
      navBackground: navBackground ?? this.navBackground,
      cardShadow: cardShadow ?? this.cardShadow,
      blobA: blobA ?? this.blobA,
      blobB: blobB ?? this.blobB,
      blobC: blobC ?? this.blobC,
    );
  }

  @override
  AppThemeVisuals lerp(ThemeExtension<AppThemeVisuals>? other, double t) {
    if (other is! AppThemeVisuals) {
      return this;
    }

    return AppThemeVisuals(
      pageBackground: Color.lerp(pageBackground, other.pageBackground, t)!,
      cardSurface: Color.lerp(cardSurface, other.cardSurface, t)!,
      softSurface: Color.lerp(softSurface, other.softSurface, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      bright: Color.lerp(bright, other.bright, t)!,
      deep: Color.lerp(deep, other.deep, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      blush: Color.lerp(blush, other.blush, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentGold: Color.lerp(accentGold, other.accentGold, t)!,
      navBackground: Color.lerp(navBackground, other.navBackground, t)!,
      cardShadow: Color.lerp(cardShadow, other.cardShadow, t)!,
      blobA: Color.lerp(blobA, other.blobA, t)!,
      blobB: Color.lerp(blobB, other.blobB, t)!,
      blobC: Color.lerp(blobC, other.blobC, t)!,
    );
  }
}

class AppPalette {
  static const blush = Color(0xFFF6C0D8);
  static const softShell = Color(0xFFFBE9F1);
  static const pageBackground = Color(0xFFF6D2E2);
  static const softRose = Color(0xFFE8BDD0);
  static const mutedRose = Color(0xFFB07D9A);
  static const primaryRose = Color(0xFFD64686);
  static const brightRose = Color(0xFFEF78A9);
  static const deepBerry = Color(0xFF6E0938);
  static const darkPlum = Color(0xFF4F2741);
  static const accentCoral = Color(0xFFF47DA6);
  static const accentGold = Color(0xFFF7B956);
  static const cardShadow = Color(0x260D0010);

  static AppThemeVisuals visualsFor(
    AppThemePreset preset,
    Brightness brightness,
  ) {
    return switch ((preset, brightness)) {
      (AppThemePreset.roseDawn, Brightness.light) => const AppThemeVisuals(
        pageBackground: Color(0xFFF6D2E2),
        cardSurface: Colors.white,
        softSurface: Color(0xFFFBE9F1),
        primary: Color(0xFFD64686),
        bright: Color(0xFFEF78A9),
        deep: Color(0xFF6E0938),
        muted: Color(0xFFB07D9A),
        blush: Color(0xFFF6C0D8),
        accent: Color(0xFFF47DA6),
        accentGold: Color(0xFFF7B956),
        navBackground: Color(0xFF1D1F29),
        cardShadow: Color(0x260D0010),
        blobA: Color(0x3314DEC8),
        blobB: Color(0x22FF7F97),
        blobC: Color(0x223E42D3),
      ),
      (AppThemePreset.roseDawn, Brightness.dark) => const AppThemeVisuals(
        pageBackground: Color(0xFF24111B),
        cardSurface: Color(0xFF321826),
        softSurface: Color(0xFF422233),
        primary: Color(0xFFF077A9),
        bright: Color(0xFFF8A5C5),
        deep: Color(0xFFFFE3EE),
        muted: Color(0xFFD6AFC1),
        blush: Color(0xFFB95B87),
        accent: Color(0xFFF7A9C7),
        accentGold: Color(0xFFF7C76B),
        navBackground: Color(0xFF0E1016),
        cardShadow: Color(0x55000000),
        blobA: Color(0x3345E6D7),
        blobB: Color(0x33E773A4),
        blobC: Color(0x334D65F1),
      ),
      (AppThemePreset.oceanCalm, Brightness.light) => const AppThemeVisuals(
        pageBackground: Color(0xFFDCEEFE),
        cardSurface: Colors.white,
        softSurface: Color(0xFFEAF6FF),
        primary: Color(0xFF1A78C2),
        bright: Color(0xFF4AB7E8),
        deep: Color(0xFF11324D),
        muted: Color(0xFF65879E),
        blush: Color(0xFFB8E7F3),
        accent: Color(0xFF62D6BF),
        accentGold: Color(0xFFF1B75C),
        navBackground: Color(0xFF121C27),
        cardShadow: Color(0x1F0E2032),
        blobA: Color(0x334AB7E8),
        blobB: Color(0x2262D6BF),
        blobC: Color(0x221A78C2),
      ),
      (AppThemePreset.oceanCalm, Brightness.dark) => const AppThemeVisuals(
        pageBackground: Color(0xFF0E1A24),
        cardSurface: Color(0xFF152635),
        softSurface: Color(0xFF1B3246),
        primary: Color(0xFF4AB7E8),
        bright: Color(0xFF88E0FF),
        deep: Color(0xFFE1F7FF),
        muted: Color(0xFFA4C8D8),
        blush: Color(0xFF2A7E9D),
        accent: Color(0xFF62D6BF),
        accentGold: Color(0xFFF1B75C),
        navBackground: Color(0xFF0A1017),
        cardShadow: Color(0x55000000),
        blobA: Color(0x334AB7E8),
        blobB: Color(0x2262D6BF),
        blobC: Color(0x221A78C2),
      ),
      (AppThemePreset.emeraldGlow, Brightness.light) => const AppThemeVisuals(
        pageBackground: Color(0xFFE6F3E8),
        cardSurface: Colors.white,
        softSurface: Color(0xFFF1FAF2),
        primary: Color(0xFF1F8A5B),
        bright: Color(0xFF4AC28F),
        deep: Color(0xFF173A2D),
        muted: Color(0xFF6A8F7D),
        blush: Color(0xFFC8E9D5),
        accent: Color(0xFF6DD0A6),
        accentGold: Color(0xFFF0BE62),
        navBackground: Color(0xFF18211D),
        cardShadow: Color(0x1F10221A),
        blobA: Color(0x334AC28F),
        blobB: Color(0x226DD0A6),
        blobC: Color(0x221F8A5B),
      ),
      (AppThemePreset.emeraldGlow, Brightness.dark) => const AppThemeVisuals(
        pageBackground: Color(0xFF111B15),
        cardSurface: Color(0xFF1A2B22),
        softSurface: Color(0xFF22392D),
        primary: Color(0xFF4AC28F),
        bright: Color(0xFF7EE0B6),
        deep: Color(0xFFE9FFF2),
        muted: Color(0xFFBCD8C7),
        blush: Color(0xFF297F5B),
        accent: Color(0xFF6DD0A6),
        accentGold: Color(0xFFF0BE62),
        navBackground: Color(0xFF0D1310),
        cardShadow: Color(0x55000000),
        blobA: Color(0x334AC28F),
        blobB: Color(0x226DD0A6),
        blobC: Color(0x221F8A5B),
      ),
    };
  }

  const AppPalette._();
}

extension AppThemeVisualsContext on BuildContext {
  AppThemeVisuals get appVisuals =>
      Theme.of(this).extension<AppThemeVisuals>()!;
}
