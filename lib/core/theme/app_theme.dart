import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/colors.dart';
import '../constants/dimensions.dart';
import 'app_themes.dart';

class AppTheme {
  AppTheme._();

  static ThemeData lightTheme = buildTheme();

  static ThemeData buildTheme([AppThemeMode? mode]) {
    final c = AppThemes.colors(mode ?? AppThemeMode.meadow);
    final onPrimary = Colors.white;
    final textPrimary = c.textPrimary;
    final textSecondary = c.textSecondary;
    final surface = c.surface;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: c.primary,
      scaffoldBackgroundColor: c.background,
      colorScheme: ColorScheme.light(
        primary: c.primary,
        secondary: c.primaryLight,
        tertiary: c.accent,
        surface: surface,
        onPrimary: onPrimary,
        onSurface: textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        surfaceTintColor: Colors.transparent,
        shadowColor: c.primary.withOpacity(0.04),
        centerTitle: false,
        titleTextStyle: GoogleFonts.notoSans(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: c.primary,
          foregroundColor: onPrimary,
          minimumSize: const Size(double.infinity, 52),
          elevation: 0,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.notoSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.primary,
          textStyle: GoogleFonts.notoSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.primary,
          side: BorderSide(color: c.primary.withOpacity(0.35)),
          surfaceTintColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.notoSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: c.surfaceVariant,
        selectedColor: c.primary.withOpacity(0.12),
        checkmarkColor: c.primary,
        labelStyle: GoogleFonts.notoSans(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        secondaryLabelStyle: GoogleFonts.notoSans(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: c.primary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: c.primary.withOpacity(0.08)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c.primary.withOpacity(0.06)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        hintStyle: GoogleFonts.notoSans(
          color: c.textHint,
          fontSize: 15,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: c.primary,
        unselectedItemColor: textSecondary,
        selectedLabelStyle: GoogleFonts.notoSans(
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: GoogleFonts.notoSans(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 4,
      ),
      dividerTheme: DividerThemeData(
        color: c.surfaceVariant,
        thickness: 1,
        space: 0,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        modalBackgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      textTheme: _buildTextTheme(textPrimary, textSecondary),
    );
  }

  static TextTheme _buildTextTheme(Color textP, Color textS) {
    return TextTheme(
      displayLarge: GoogleFonts.amiri(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textP,
          letterSpacing: -0.5),
      displayMedium: GoogleFonts.amiri(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: textP,
          letterSpacing: -0.5),
      displaySmall: GoogleFonts.amiri(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: textP,
          letterSpacing: -0.3),
      headlineLarge: GoogleFonts.notoSans(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: textP,
          letterSpacing: -0.3),
      headlineMedium: GoogleFonts.notoSans(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textP),
      headlineSmall: GoogleFonts.notoSans(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textP),
      titleLarge: GoogleFonts.notoSans(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textP),
      titleMedium: GoogleFonts.notoSans(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textP),
      titleSmall: GoogleFonts.notoSans(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textP),
      bodyLarge: GoogleFonts.notoSans(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: textP),
      bodyMedium: GoogleFonts.notoSans(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: textP),
      bodySmall: GoogleFonts.notoSans(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: textS),
      labelLarge: GoogleFonts.notoSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textP),
      labelMedium: GoogleFonts.notoSans(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textS),
      labelSmall: GoogleFonts.notoSans(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: textS),
    );
  }
}
