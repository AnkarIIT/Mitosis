import 'package:flutter/material.dart';

import 'tokens.dart';

/// Calm Precision palette: the logo remains the brand mark; study actions use
/// a quieter, more accessible deep teal on warm neutral surfaces.
class AppColors {
  static const Color brandNavy = Color(0xFF0A2344);
  static const Color brandTeal = Color(0xFF00B8A9);
  static const Color actionTeal = Color(0xFF146C60);
  static const Color primary = actionTeal;
  static const Color primarySoft = Color(0xFFE5F2EC);
  static const Color primaryDark = Color(0xFF72C8B5);

  static const Color secondary = Color(0xFFE8E5DA);

  static const Color background = Color(0xFFF7F8F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color surfaceWarm = Color(0xFFF1F4F0);
  static const Color surfaceMuted = Color(0xFFE5F2EC);

  static const Color backgroundDark = Color(0xFF071B18);
  static const Color surfaceDark = Color(0xFF102521);
  static const Color cardBgDark = Color(0xFF102521);
  static const Color surfaceMutedDark = Color(0xFF1A3630);

  static const Color textDark = Color(0xFF172724);
  static const Color textLight = Color(0xFFF1F6F4);
  static const Color textSubtle = Color(0xFF566762);
  static const Color textSubtleDark = Color(0xFFB8C7C1);

  static const Color success = Color(0xFF216A43);
  static const Color successLight = Color(0xFFEAF5ED);
  static const Color warning = Color(0xFF946200);
  static const Color warningLight = Color(0xFFFFF4D6);
  static const Color error = Color(0xFFB3261E);
  static const Color errorLight = Color(0xFFFCECEB);
  static const Color info = Color(0xFF146C60);

  static Color get biologyAccent => SubjectColors.biology;
  static Color get chemistryAccent => SubjectColors.chemistry;
  static Color get physicsAccent => SubjectColors.physics;

  static const Color divider = Color(0xFFDCE5DF);
  static const Color dividerDark = Color(0xFF354B46);
}
