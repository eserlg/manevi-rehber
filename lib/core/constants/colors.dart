import 'package:flutter/material.dart';

/// Islamic-inspired color palette for Manevi Rehber
class AppColors {
  AppColors._();

  // Primary Colors
  static const Color primary = Color(0xFF1E6B53);
  static const Color primaryLight = Color(0xFF4FA382);
  static const Color primaryDark = Color(0xFF14513E);

  // Secondary Colors
  static const Color secondary = Color(0xFFF3DFA2);
  static const Color secondaryLight = Color(0xFFFFF4C8);
  static const Color secondaryDark = Color(0xFFC9A345);

  // Accent Colors
  static const Color accent = Color(0xFFC9A227);
  static const Color accentLight = Color(0xFFE2C46D);
  static const Color accentDark = Color(0xFF7C5A18);

  // Background Colors
  static const Color background = Color(0xFFF5FAF7);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFE0F0E6);

  // Text Colors
  static const Color textPrimary = Color(0xFF1A2E24);
  static const Color textSecondary = Color(0xFF5A7669);
  static const Color textHint = Color(0xFF94A89D);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Semantic Colors
  static const Color success = Color(0xFF2F9D6A);
  static const Color error = Color(0xFFD46A5E);
  static const Color warning = Color(0xFFE8C566);
  static const Color info = Color(0xFF4F8FA8);

  // Prayer Time Colors
  static const Color softBlue = Color(0xFFCFE8EE);
  static const Color softPurple = Color(0xFFE9E0F3);
  static const Color softOrange = Color(0xFFF3E2C3);
  static const Color softPink = Color(0xFFF2D7D2);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryLight],
  );

  static const LinearGradient softGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [surface, background],
  );
}
