import 'package:flutter/material.dart';

/// App color scheme constants
class AppColors {
  // Primary Color - Teal/Dark Cyan
  static const Color primary = Color(0xFF216869);
  
  // Secondary Color - Beige
  static const Color secondary = Color(0xFFDDDBCB);

  // Background and Surfaces
  static const Color background = Color(0xFFF9F9F9); // Slightly off-white for depth
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color surfaceWarm = Color(0xFFFDFBF7); // Warm beige for "Distraction-Free" reading

  // Dark Mode Background and Surfaces
  static const Color backgroundDark = Color(0xFF0F172A); // Deep Navy/Slate 900
  static const Color surfaceDark = Color(0xFF1E293B);    // Slate 800
  static const Color cardBgDark = Color(0xFF1E293B);
  
  // Text colors
  static const Color textDark = Color(0xFF1E293B); // Slate 800
  static const Color textLight = Color(0xFFFFFFFF);
  static const Color textSubtle = Color(0xFF64748B); // Slate 500
  static const Color textDarkSubtle = Color(0xFF94A3B8); // Slate 400

  // Status/Utility colors
  static const Color success = Color(0xFF10B981); // Emerald 500
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color warning = Color(0xFFF59E0B); // Amber 500
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFEF4444); // Red 500
  static const Color errorLight = Color(0xFFFEE2E2);

  // Subject Accents
  static const Color biologyAccent = Color(0xFF10B981); // Green
  static const Color chemistryAccent = Color(0xFF3B82F6); // Blue
  static const Color physicsAccent = Color(0xFFF59E0B); // Orange

  // Borders & Dividers
  static const Color divider = Color(0xFFE2E8F0); // Slate 200
  static const Color dividerDark = Color(0xFF334155); // Slate 700

  // ───────── Premium Palette (for NeetHomeScreen redesign demo) ─────────
  static const Color premiumBg = Color(0xFFF4F3F8);
  static const Color premiumCard = Color(0xFFFFFFFF);
  static const Color premiumNavDock = Color(0xFF0E0E10);
  static const Color premiumSearchBg = Color(0xFFFFFFFF);
  static const Color premiumChipBg = Color(0xFFF1F5F9);

  // Subject accents – premium redesign
  static const Color biologyOrange = Color(0xFFFF7034);
  static const Color physicsBlue = Color(0xFF5B61F6);
  static const Color chemistryPurple = Color(0xFF9D4EDD);

  // Nav & interaction
  static const Color premiumNavActive = Color(0xFFFFFFFF);
  static const Color premiumNavInactive = Color(0xFF71717A);

  // Adaptive Color Helpers for Dynamic Dark/Light Mode
  static Color adaptiveBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? backgroundDark
        : background;
  }

  static Color adaptiveSurface(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? surfaceDark
        : surface;
  }

  static Color adaptiveText(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? textLight
        : textDark;
  }

  static Color adaptiveSubtleText(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? textDarkSubtle
        : textSubtle;
  }

  static Color adaptiveDivider(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? dividerDark
        : divider;
  }
}
