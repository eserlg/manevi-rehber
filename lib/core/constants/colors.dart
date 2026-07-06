import 'package:flutter/material.dart';

/// Soft pastel Islamic color palette for Manevi Rehber
class AppColors {
  AppColors._();

  // Primary Colors – sage green family
  static const Color primary = Color(0xFF7BAE8A);
  static const Color primaryLight = Color(0xFFA8D5BA);
  static const Color primaryDark = Color(0xFF5E8F6F);

  // Secondary Colors – warm cream/gold
  static const Color secondary = Color(0xFFF3DFA2);
  static const Color secondaryLight = Color(0xFFFFF4C8);
  static const Color secondaryDark = Color(0xFFC9A345);

  // Accent Colors – soft rose
  static const Color accent = Color(0xFFE8B4B8);
  static const Color accentLight = Color(0xFFF2D4D4);
  static const Color accentDark = Color(0xFFB88A8A);

  // Background Colors
  static const Color background = Color(0xFFF9F8F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFEEF3F0);

  // Text Colors
  static const Color textPrimary = Color(0xFF2C3E36);
  static const Color textSecondary = Color(0xFF6B7D74);
  static const Color textHint = Color(0xFFA3B2AA);
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

  // Gradient – very soft, almost flat
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
