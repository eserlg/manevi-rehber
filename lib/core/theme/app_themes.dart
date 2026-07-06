import 'package:flutter/material.dart';

/// Manevi Rehber soft pastel tema modları
enum AppThemeMode {
  dawn, // Gün Doğumu (soft şeftali + krem)
  serenity, // Gece Sükuneti (soft lacivert + gümüş)
  meadow, // Bahar Nebesi (sage yeşili + nane)
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
        return 'Soft şeftali, krem, gün ışığı';
      case AppThemeMode.serenity:
        return 'Soft lacivert, gümüş, sükunet';
      case AppThemeMode.meadow:
        return 'Sage yeşili, nane, ferahlık';
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
          primary: Color(0xFFE09F7A),
          primaryLight: Color(0xFFF2C6AD),
          primaryDark: Color(0xFFC47E5A),
          background: Color(0xFFFFF8F5),
          surface: Color(0xFFFFFFFF),
          surfaceVariant: Color(0xFFF5E8E0),
          textPrimary: Color(0xFF4A3B32),
          textSecondary: Color(0xFF8F7A6E),
          textHint: Color(0xFFC4B0A3),
          accent: Color(0xFFE8B4B8),
          gradientStart: Color(0xFFFFF6F1),
          gradientEnd: Color(0xFFFAE6DA),
          primaryGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE09F7A), Color(0xFFF2C6AD)],
          ),
        );
      case AppThemeMode.serenity:
        return const ThemeColors(
          primary: Color(0xFF5E6FA3),
          primaryLight: Color(0xFF8FA0C9),
          primaryDark: Color(0xFF465585),
          background: Color(0xFFF5F6FA),
          surface: Color(0xFFFFFFFF),
          surfaceVariant: Color(0xFFE6E9F2),
          textPrimary: Color(0xFF2A2F3F),
          textSecondary: Color(0xFF6B7285),
          textHint: Color(0xFFA5ADBF),
          accent: Color(0xFFE8C566),
          gradientStart: Color(0xFFF2F4FA),
          gradientEnd: Color(0xFFE1E5F2),
          primaryGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF5E6FA3), Color(0xFF8FA0C9)],
          ),
        );
      case AppThemeMode.meadow:
        return const ThemeColors(
          primary: Color(0xFF7BAE8A),
          primaryLight: Color(0xFFA8D5BA),
          primaryDark: Color(0xFF5E8F6F),
          background: Color(0xFFF9FBF9),
          surface: Color(0xFFFFFFFF),
          surfaceVariant: Color(0xFFE8F0EA),
          textPrimary: Color(0xFF2C3E36),
          textSecondary: Color(0xFF6B7D74),
          textHint: Color(0xFFA3B2AA),
          accent: Color(0xFFE8B4B8),
          gradientStart: Color(0xFFF7FBF8),
          gradientEnd: Color(0xFFE3EFE6),
          primaryGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF7BAE8A), Color(0xFFA8D5BA)],
          ),
        );
    }
  }
}
