import 'package:flutter/material.dart';

import 'tokens.dart';

/// NEET Mitos brand palette with accessible semantic and surface colors.
class AppColors {
  static const Color brandNavy = Color(0xFF0A2344);
  static const Color brandTeal = Color(0xFF00B8A9);
  static const Color primary = brandNavy;
  static const Color primarySoft = Color(0xFFE3F5F2);
  static const Color primaryDark = Color(0xFF52D6C8);

  static const Color secondary = Color(0xFFE8E5DA);

  static const Color background = Color(0xFFF6F8FB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color surfaceWarm = Color(0xFFF2F4EF);
  static const Color surfaceMuted = Color(0xFFE8EFEB);

  static const Color backgroundDark = Color(0xFF071629);
  static const Color surfaceDark = Color(0xFF0D2038);
  static const Color cardBgDark = Color(0xFF112742);
  static const Color surfaceMutedDark = Color(0xFF1B3450);

  static const Color textDark = Color(0xFF0A2344);
  static const Color textLight = Color(0xFFF1F6FC);
  static const Color textSubtle = Color(0xFF52647A);
  static const Color textSubtleDark = Color(0xFFB2C1D1);

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

  static const Color divider = Color(0xFFDCE4ED);
  static const Color dividerDark = Color(0xFF30445A);
}
