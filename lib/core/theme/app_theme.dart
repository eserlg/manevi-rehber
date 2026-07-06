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
        centerTitle: true,
        titleTextStyle: GoogleFonts.notoSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: c.primary,
          foregroundColor: onPrimary,
          minimumSize: const Size(double.infinity, AppDimensions.buttonHeight),
          elevation: 0,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.notoSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.primary,
          textStyle: GoogleFonts.notoSans(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.primary,
          side: BorderSide(color: c.primary.withOpacity(0.4)),
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.notoSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: c.surfaceVariant,
        selectedColor: c.primary.withOpacity(0.16),
        checkmarkColor: c.primary,
        labelStyle: GoogleFonts.notoSans(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        secondaryLabelStyle: GoogleFonts.notoSans(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: c.primaryDark,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
          side: BorderSide(color: c.primary.withOpacity(0.10)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: c.primary.withOpacity(0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: c.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingMD,
          vertical: AppDimensions.spacingMD,
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
      textTheme: _buildTextTheme(textPrimary, textSecondary),
      dividerTheme: DividerThemeData(
        color: c.surfaceVariant,
        thickness: 1,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        modalBackgroundColor: surface,
        surfaceTintColor: Colors.transparent,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        ),
      ),
    );
  }

  static TextTheme _buildTextTheme(Color textP, Color textS) {
    return TextTheme(
      displayLarge: GoogleFonts.amiri(
        fontSize: 32, fontWeight: FontWeight.bold, color: textP),
      displayMedium: GoogleFonts.amiri(
        fontSize: 28, fontWeight: FontWeight.bold, color: textP),
      displaySmall: GoogleFonts.amiri(
        fontSize: 24, fontWeight: FontWeight.bold, color: textP),
      headlineLarge: GoogleFonts.notoSans(
        fontSize: 24, fontWeight: FontWeight.w600, color: textP),
      headlineMedium: GoogleFonts.notoSans(
        fontSize: 20, fontWeight: FontWeight.w600, color: textP),
      headlineSmall: GoogleFonts.notoSans(
        fontSize: 18, fontWeight: FontWeight.w500, color: textP),
      titleLarge: GoogleFonts.notoSans(
        fontSize: 18, fontWeight: FontWeight.w500, color: textP),
      titleMedium: GoogleFonts.notoSans(
        fontSize: 16, fontWeight: FontWeight.w500, color: textP),
      titleSmall: GoogleFonts.notoSans(
        fontSize: 14, fontWeight: FontWeight.w500, color: textP),
      bodyLarge: GoogleFonts.notoSans(
        fontSize: 16, fontWeight: FontWeight.normal, color: textP),
      bodyMedium: GoogleFonts.notoSans(
        fontSize: 14, fontWeight: FontWeight.normal, color: textP),
      bodySmall: GoogleFonts.notoSans(
        fontSize: 12, fontWeight: FontWeight.normal, color: textS),
      labelLarge: GoogleFonts.notoSans(
        fontSize: 14, fontWeight: FontWeight.w500, color: textP),
      labelMedium: GoogleFonts.notoSans(
        fontSize: 12, fontWeight: FontWeight.w500, color: textS),
      labelSmall: GoogleFonts.notoSans(
        fontSize: 10, fontWeight: FontWeight.w500, color: textS),
    );
  }
}
