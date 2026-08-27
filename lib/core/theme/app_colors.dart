import 'package:flutter/material.dart';

import 'tokens.dart';

/// App color scheme constants.
/// For adaptive dark/light colors, use [AdaptiveColors] instead.
/// For subject colors, use [SubjectColors].
class AppColors {
  // Primary Color - Teal/Dark Cyan
  static const Color primary = Color(0xFF216869);
  
  // Secondary Color - Beige
  static const Color secondary = Color(0xFFDDDBCB);

  // Background and Surfaces
  static const Color background = Color(0xFFF9F9F9);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color surfaceWarm = Color(0xFFFDFBF7);

  // Dark Mode
  static const Color backgroundDark = Color(0xFF0F1115);
  static const Color surfaceDark = Color(0xFF1A1D24);
  static const Color cardBgDark = Color(0xFF1A1D24);
  
  // Text colors
  static const Color textDark = Color(0xFF1E293B);
  static const Color textLight = Color(0xFFF1F3F7);
  static const Color textSubtle = Color(0xFF64748B);
  static const Color textSubtleDark = Color(0xFF8B919E);

  // Status colors
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);

  // Subject accents — delegate to SubjectColors for consistency
  static Color get biologyAccent => SubjectColors.biology;
  static Color get chemistryAccent => SubjectColors.chemistry;
  static Color get physicsAccent => SubjectColors.physics;

  // Borders & Dividers
  static const Color divider = Color(0xFFE2E8F0);
  static const Color dividerDark = Color(0xFF334155);
}
