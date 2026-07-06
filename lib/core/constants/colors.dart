import 'package:flutter/material.dart';

/// Premium Islamic color system for Manevi Rehber
class AppColors {
  AppColors._();

  // Primary – rich forest emerald
  static const Color primary = Color(0xFF1B5E3C);
  static const Color primaryLight = Color(0xFF3D8B5F);
  static const Color primaryDark = Color(0xFF0E3B26);

  // Secondary – warm sand
  static const Color secondary = Color(0xFFF0DFB6);
  static const Color secondaryLight = Color(0xFFFAF0DC);
  static const Color secondaryDark = Color(0xFFC9A84C);

  // Accent – rich gold
  static const Color accent = Color(0xFFC8943E);
  static const Color accentLight = Color(0xFFE2C06D);
  static const Color accentDark = Color(0xFF8B632A);

  // Background
  static const Color background = Color(0xFFF9F7F1);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFEDEBE3);

  // Text
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFADADAD);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Semantic
  static const Color success = Color(0xFF2E7D32);
  static const Color error = Color(0xFFC9514B);
  static const Color warning = Color(0xFFE8A838);
  static const Color info = Color(0xFF3A7DA8);

  // Soft palette (prayer time chips, etc.)
  static const Color softBlue = Color(0xFFD9EAF2);
  static const Color softPurple = Color(0xFFE6DDF0);
  static const Color softOrange = Color(0xFFF2E1C3);
  static const Color softPink = Color(0xFFF0D8D4);

  // Gradients
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
