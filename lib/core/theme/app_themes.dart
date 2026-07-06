import 'package:flutter/material.dart';

/// Manevi Rehber premium tema modları
enum AppThemeMode {
  dawn, // Gün Doğumu – warm amber, cream
  serenity, // Gece Sükuneti – deep navy, gold stars
  meadow, // Bahar Nebesi – rich forest, sunlight
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
        return 'Sıcak kehribar, krem, gün ışığı';
      case AppThemeMode.serenity:
        return 'Derin lacivert, yıldız altını';
      case AppThemeMode.meadow:
        return 'Orman yeşili, altın ışık';
    }
  }

  static IconData icon(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.dawn:
        return Icons.wb_sunny_outlined;
      case AppThemeMode.serenity:
        return Icons.nightlight_round;
      case AppThemeMode.meadow:
        return Icons.forest_outlined;
    }
  }

  static ThemeColors colors(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.dawn:
        return const ThemeColors(
          primary: Color(0xFFC67B4B),
          primaryLight: Color(0xFFDCA67A),
          primaryDark: Color(0xFF9A5A34),
          background: Color(0xFFFCFAF5),
          surface: Color(0xFFFFFFFF),
          surfaceVariant: Color(0xFFF2ECE2),
          textPrimary: Color(0xFF1C1814),
          textSecondary: Color(0xFF7A7268),
          textHint: Color(0xFFB5AEA4),
          accent: Color(0xFFD4943A),
          gradientStart: Color(0xFFFBF6EE),
          gradientEnd: Color(0xFFF0E6D5),
          primaryGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFC67B4B), Color(0xFFDCA67A)],
          ),
        );
      case AppThemeMode.serenity:
        return const ThemeColors(
          primary: Color(0xFF2B3D6E),
          primaryLight: Color(0xFF4A5F9E),
          primaryDark: Color(0xFF18264A),
          background: Color(0xFFF6F7FB),
          surface: Color(0xFFFFFFFF),
          surfaceVariant: Color(0xFFE8EAF2),
          textPrimary: Color(0xFF141A2E),
          textSecondary: Color(0xFF6B708A),
          textHint: Color(0xFFA5AABF),
          accent: Color(0xFFD4A84B),
          gradientStart: Color(0xFFF2F4FA),
          gradientEnd: Color(0xFFE0E3F0),
          primaryGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2B3D6E), Color(0xFF4A5F9E)],
          ),
        );
      case AppThemeMode.meadow:
        return const ThemeColors(
          primary: Color(0xFF1B5E3C),
          primaryLight: Color(0xFF3D8B5F),
          primaryDark: Color(0xFF0E3B26),
          background: Color(0xFFF9F7F1),
          surface: Color(0xFFFFFFFF),
          surfaceVariant: Color(0xFFEDEBE3),
          textPrimary: Color(0xFF1A1A1A),
          textSecondary: Color(0xFF757575),
          textHint: Color(0xFFADADAD),
          accent: Color(0xFFC8943E),
          gradientStart: Color(0xFFF8F5ED),
          gradientEnd: Color(0xFFE8E5DA),
          primaryGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1B5E3C), Color(0xFF3D8B5F)],
          ),
        );
    }
  }
}
