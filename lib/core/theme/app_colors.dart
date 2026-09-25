import 'package:flutter/material.dart';

import 'tokens.dart';

/// Academic Calm palette. Use [AdaptiveColors] in widgets — not raw hex.
class AppColors {
  static const Color primary = Color(0xFF0F766E);
  static const Color primarySoft = Color(0xFFCCFBF1);
  static const Color primaryDark = Color(0xFF14B8A6);

  static const Color secondary = Color(0xFFE8E4D9);

  static const Color background = Color(0xFFF3F5F4);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color surfaceWarm = Color(0xFFEEF2F1);
  static const Color surfaceMuted = Color(0xFFE7EEEC);

  static const Color backgroundDark = Color(0xFF0B1214);
  static const Color surfaceDark = Color(0xFF152024);
  static const Color cardBgDark = Color(0xFF1A262A);
  static const Color surfaceMutedDark = Color(0xFF243033);

  static const Color textDark = Color(0xFF0F172A);
  static const Color textLight = Color(0xFFF1F5F4);
  static const Color textSubtle = Color(0xFF475569);
  static const Color textSubtleDark = Color(0xFF94A3A8);

  static const Color success = Color(0xFF059669);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color warning = Color(0xFFD97706);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFDC2626);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF0F766E);

  static Color get biologyAccent => SubjectColors.biology;
  static Color get chemistryAccent => SubjectColors.chemistry;
  static Color get physicsAccent => SubjectColors.physics;

  static const Color divider = Color(0xFFDDE5E2);
  static const Color dividerDark = Color(0xFF2C3A3E);
}
