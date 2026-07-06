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
        return 'Terracotta, krem, gün ışığı';
      case AppThemeMode.serenity:
        return 'Lacivert, gümüş, altın hilal';
      case AppThemeMode.meadow:
        return 'Zümrüt, altın, ferahlık';
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
          primary: Color(0xFFD9784A),
          primaryLight: Color(0xFFE8A67E),
          primaryDark: Color(0xFFA85A32),
          background: Color(0xFFFFFBF7),
          surface: Color(0xFFFFFFFF),
          surfaceVariant: Color(0xFFF5E6D8),
          textPrimary: Color(0xFF3D2B1F),
          textSecondary: Color(0xFF8A6E5D),
          textHint: Color(0xFFB8A396),
          accent: Color(0xFFC96A3A),
          gradientStart: Color(0xFFFFF4E6),
          gradientEnd: Color(0xFFFCE3D0),
          primaryGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFD9784A), Color(0xFFE8A67E)],
          ),
        );
      case AppThemeMode.serenity:
        return const ThemeColors(
          primary: Color(0xFF3B4C9C),
          primaryLight: Color(0xFF6B7FC4),
          primaryDark: Color(0xFF253474),
          background: Color(0xFFF0F2F9),
          surface: Color(0xFFFFFFFF),
          surfaceVariant: Color(0xFFE1E6F2),
          textPrimary: Color(0xFF1A1F35),
          textSecondary: Color(0xFF5A6480),
          textHint: Color(0xFF99A3BD),
          accent: Color(0xFFC9A227),
          gradientStart: Color(0xFFE8EDF8),
          gradientEnd: Color(0xFFD6DDF0),
          primaryGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF3B4C9C), Color(0xFF6B7FC4)],
          ),
        );
      case AppThemeMode.meadow:
        return const ThemeColors(
          primary: Color(0xFF1E6B53),
          primaryLight: Color(0xFF4FA382),
          primaryDark: Color(0xFF14513E),
          background: Color(0xFFF5FAF7),
          surface: Color(0xFFFFFFFF),
          surfaceVariant: Color(0xFFE0F0E6),
          textPrimary: Color(0xFF1A2E24),
          textSecondary: Color(0xFF5A7669),
          textHint: Color(0xFF94A89D),
          accent: Color(0xFFC9A227),
          gradientStart: Color(0xFFE8F5EC),
          gradientEnd: Color(0xFFD4EBDC),
          primaryGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E6B53), Color(0xFF4FA382)],
          ),
        );
    }
  }
}