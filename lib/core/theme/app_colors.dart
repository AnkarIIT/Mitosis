import 'package:flutter/material.dart';

import 'tokens.dart';

/// Premium teal and warm-neutral palette. Prefer [AdaptiveColors] in widgets.
class AppColors {
  static const Color primary = Color(0xFF0D4F4A);
  static const Color primarySoft = Color(0xFFD8F1EA);
  static const Color primaryDark = Color(0xFF4ED3B8);

  static const Color secondary = Color(0xFFE8E5DA);

  static const Color background = Color(0xFFF7F7F2);
  static const Color surface = Color(0xFFFFFEFB);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color surfaceWarm = Color(0xFFF2F4EF);
  static const Color surfaceMuted = Color(0xFFE8EFEB);

  static const Color backgroundDark = Color(0xFF081719);
  static const Color surfaceDark = Color(0xFF102528);
  static const Color cardBgDark = Color(0xFF132B2E);
  static const Color surfaceMutedDark = Color(0xFF20383A);

  static const Color textDark = Color(0xFF132B2F);
  static const Color textLight = Color(0xFFEDF6F2);
  static const Color textSubtle = Color(0xFF52656A);
  static const Color textSubtleDark = Color(0xFF9CB1AD);

  static const Color success = Color(0xFF0D8B68);
  static const Color successLight = Color(0xFFD9F3E8);
  static const Color warning = Color(0xFFB7791F);
  static const Color warningLight = Color(0xFFF7E9C8);
  static const Color error = Color(0xFFB94545);
  static const Color errorLight = Color(0xFFFBE4E1);
  static const Color info = Color(0xFF1B817A);

  static Color get biologyAccent => SubjectColors.biology;
  static Color get chemistryAccent => SubjectColors.chemistry;
  static Color get physicsAccent => SubjectColors.physics;

  static const Color divider = Color(0xFFDDE5E2);
  static const Color dividerDark = Color(0xFF2C3A3E);
}
