import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    final textTheme = GoogleFonts.interTextTheme().copyWith(
      displayLarge: GoogleFonts.inter(color: AppColors.textDark, fontWeight: FontWeight.bold),
      displayMedium: GoogleFonts.inter(color: AppColors.textDark, fontWeight: FontWeight.bold),
      displaySmall: GoogleFonts.inter(color: AppColors.textDark, fontWeight: FontWeight.bold),
      headlineLarge: GoogleFonts.inter(color: AppColors.textDark, fontWeight: FontWeight.bold),
      headlineMedium: GoogleFonts.inter(color: AppColors.textDark, fontWeight: FontWeight.bold),
      headlineSmall: GoogleFonts.inter(color: AppColors.textDark, fontWeight: FontWeight.w600),
      titleLarge: GoogleFonts.inter(color: AppColors.textDark, fontWeight: FontWeight.w600),
      titleMedium: GoogleFonts.inter(color: AppColors.textDark, fontWeight: FontWeight.w500),
      titleSmall: GoogleFonts.inter(color: AppColors.textDark, fontWeight: FontWeight.w500),
      bodyLarge: GoogleFonts.inter(color: AppColors.textDark),
      bodyMedium: GoogleFonts.inter(color: AppColors.textDark),
      bodySmall: GoogleFonts.inter(color: AppColors.textSubtle),
      labelLarge: GoogleFonts.inter(color: AppColors.textSubtle, fontWeight: FontWeight.w500),
      labelMedium: GoogleFonts.inter(color: AppColors.textSubtle, fontWeight: FontWeight.w500),
      labelSmall: GoogleFonts.inter(color: AppColors.textSubtle, fontWeight: FontWeight.w500),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        error: AppColors.error,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textLight,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          color: AppColors.textLight,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardBg,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.divider, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textLight,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 24,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSubtle,
        selectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12),
        unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 12),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }

  static ThemeData get darkTheme {
    final textTheme = GoogleFonts.interTextTheme().copyWith(
      displayLarge: GoogleFonts.inter(color: AppColors.textLight, fontWeight: FontWeight.bold),
      displayMedium: GoogleFonts.inter(color: AppColors.textLight, fontWeight: FontWeight.bold),
      displaySmall: GoogleFonts.inter(color: AppColors.textLight, fontWeight: FontWeight.bold),
      headlineLarge: GoogleFonts.inter(color: AppColors.textLight, fontWeight: FontWeight.bold),
      headlineMedium: GoogleFonts.inter(color: AppColors.textLight, fontWeight: FontWeight.bold),
      headlineSmall: GoogleFonts.inter(color: AppColors.textLight, fontWeight: FontWeight.w600),
      titleLarge: GoogleFonts.inter(color: AppColors.textLight, fontWeight: FontWeight.w600),
      titleMedium: GoogleFonts.inter(color: AppColors.textLight, fontWeight: FontWeight.w500),
      titleSmall: GoogleFonts.inter(color: AppColors.textLight, fontWeight: FontWeight.w500),
      bodyLarge: GoogleFonts.inter(color: AppColors.textLight),
      bodyMedium: GoogleFonts.inter(color: AppColors.textLight),
      bodySmall: GoogleFonts.inter(color: AppColors.textDarkSubtle),
      labelLarge: GoogleFonts.inter(color: AppColors.textDarkSubtle, fontWeight: FontWeight.w500),
      labelMedium: GoogleFonts.inter(color: AppColors.textDarkSubtle, fontWeight: FontWeight.w500),
      labelSmall: GoogleFonts.inter(color: AppColors.textDarkSubtle, fontWeight: FontWeight.w500),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surfaceDark,
        error: AppColors.error,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surfaceDark,
        foregroundColor: AppColors.textLight,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          color: AppColors.textLight,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardBgDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.dividerDark, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textLight,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.dividerDark,
        thickness: 1,
        space: 24,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceDark,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textDarkSubtle,
        selectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12),
        unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 12),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }
}
