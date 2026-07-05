import 'package:flutter/material.dart';

/// Manevi Rehber tema modları
enum AppThemeMode {
  dawn, // Gün Doğumu (sıcak şeftali + krem + turuncu)
  serenity, // Gece Sükuneti (lacivert + gümüş + altın)
  meadow, // Bahar Nebesi (nane yeşili + yağmur mavisi)
}

class ThemeColors {
  final Color primary;
  final Color primaryLight;
  final Color primaryDark;
  final Color background;
  final Color surface;
  final Color surfaceVariant;
  final Color textPrimary;
  final Color textSecondary;
  final Color textHint;
  final Color accent;
  final Color gradientStart;
  final Color gradientEnd;
  final LinearGradient primaryGradient;

  const ThemeColors({
    required this.primary,
    required this.primaryLight,
    required this.primaryDark,
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.textPrimary,
    required this.textSecondary,
    required this.textHint,
    required this.accent,
    required this.gradientStart,
    required this.gradientEnd,
    required this.primaryGradient,
  });
}

class AppThemes {
  AppThemes._();

  static String label(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.dawn:
        return 'Gün Doğumu';
      case AppThemeMode.serenity:
        return 'Gece Sükuneti';
      case AppThemeMode.meadow:
        return 'Bahar Nebesi';
    }
  }

  static String subtitle(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.dawn:
        return 'Şeftali, krem, gün ışığı';
      case AppThemeMode.serenity:
        return 'Lacivert, gümüş, altın hilal';
      case AppThemeMode.meadow:
        return 'Nane, yağmur, ferahlık';
    }
  }

  static IconData icon(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.dawn:
        return Icons.wb_sunny_outlined;
      case AppThemeMode.serenity:
        return Icons.nightlight_round;
      case AppThemeMode.meadow:
        return Icons.grass;
    }
  }

  static ThemeColors colors(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.dawn:
        return const ThemeColors(
          primary: Color(0xFFE8915C),
          primaryLight: Color(0xFFF5B98C),
          primaryDark: Color(0xFFB26A3C),
          background: Color(0xFFFFFBF5),
          surface: Color(0xFFFFFFFF),
          surfaceVariant: Color(0xFFF8E8DB),
          textPrimary: Color(0xFF402E22),
          textSecondary: Color(0xFF7A6357),
          textHint: Color(0xFFA8978A),
          accent: Color(0xFFC56A3F),
          gradientStart: Color(0xFFFFF6E6),
          gradientEnd: Color(0xFFFCE3D0),
          primaryGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE8915C), Color(0xFFF5B98C)],
          ),
        );
      case AppThemeMode.serenity:
        return const ThemeColors(
          primary: Color(0xFF4055A8),
          primaryLight: Color(0xFF637BC4),
          primaryDark: Color(0xFF23357A),
          background: Color(0xFFF2F4FA),
          surface: Color(0xFFFFFFFF),
          surfaceVariant: Color(0xFFE4E8F2),
          textPrimary: Color(0xFF1E2638),
          textSecondary: Color(0xFF57617A),
          textHint: Color(0xFF8A93AD),
          accent: Color(0xFFD4AF37),
          gradientStart: Color(0xFFEAEEF8),
          gradientEnd: Color(0xFFD8DFED),
          primaryGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF4055A8), Color(0xFF637BC4)],
          ),
        );
      case AppThemeMode.meadow:
        return const ThemeColors(
          primary: Color(0xFF4FA67A),
          primaryLight: Color(0xFF7CC09E),
          primaryDark: Color(0xFF2F7355),
          background: Color(0xFFF5FBF6),
          surface: Color(0xFFFFFFFF),
          surfaceVariant: Color(0xFFE0F0E4),
          textPrimary: Color(0xFF1F3D2C),
          textSecondary: Color(0xFF577567),
          textHint: Color(0xFF8FA89C),
          accent: Color(0xFF5BA8C4),
          gradientStart: Color(0xFFEFFAF2),
          gradientEnd: Color(0xFFDDEFE2),
          primaryGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF4FA67A), Color(0xFF7CC09E)],
          ),
        );
    }
  }
}