import 'package:flutter/material.dart';

/// Design tokens for NEET Mitos. Never hardcode these in screens.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  static const SizedBox xsBox = SizedBox(width: xs, height: xs);
  static const SizedBox smBox = SizedBox(width: sm, height: sm);
  static const SizedBox mdBox = SizedBox(width: md, height: md);
  static const SizedBox lgBox = SizedBox(width: lg, height: lg);
  static const SizedBox xlBox = SizedBox(width: xl, height: xl);
  static const SizedBox xxlBox = SizedBox(width: xxl, height: xxl);

  static const SizedBox xsHeight = SizedBox(height: xs);
  static const SizedBox smHeight = SizedBox(height: sm);
  static const SizedBox mdHeight = SizedBox(height: md);
  static const SizedBox lgHeight = SizedBox(height: lg);
  static const SizedBox xlHeight = SizedBox(height: xl);
  static const SizedBox xxlHeight = SizedBox(height: xxl);
  static const SizedBox xxxlHeight = SizedBox(height: xxxl);

  static const EdgeInsets page = EdgeInsets.symmetric(
    horizontal: 20,
    vertical: 12,
  );
  static const EdgeInsets card = EdgeInsets.all(lg);
}

abstract final class AppRadius {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double full = 999;

  static const BorderRadius xsAll = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius xlAll = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius fullAll = BorderRadius.all(Radius.circular(full));

  static BorderRadius only({
    double topLeft = 0,
    double topRight = 0,
    double bottomLeft = 0,
    double bottomRight = 0,
  }) => BorderRadius.only(
    topLeft: Radius.circular(topLeft),
    topRight: Radius.circular(topRight),
    bottomLeft: Radius.circular(bottomLeft),
    bottomRight: Radius.circular(bottomRight),
  );
}

abstract final class AppDuration {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);
  static const Duration celebration = Duration(milliseconds: 800);
}

abstract final class AppShadows {
  static List<BoxShadow> card(bool isDark) => isDark
      ? const []
      : [
          BoxShadow(
            color: Color(0x0F0F172A),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ];

  static List<BoxShadow> raised(bool isDark) => isDark
      ? [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ]
      : [
          BoxShadow(
            color: Color(0x140F172A),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ];

  static List<BoxShadow> nav(bool isDark) => [
    BoxShadow(
      color: isDark ? const Color(0x66000000) : const Color(0x140F172A),
      blurRadius: 20,
      offset: const Offset(0, -2),
    ),
  ];
}

/// Biology = teal-green, Chemistry = violet, Physics = amber.
abstract final class SubjectColors {
  static const Color biology = Color(0xFF059669);
  static const Color biologyLight = Color(0xFFD1FAE5);
  static const Color biologyDark = Color(0xFF047857);

  static const Color chemistry = Color(0xFF7C3AED);
  static const Color chemistryLight = Color(0xFFEDE9FE);
  static const Color chemistryDark = Color(0xFF6D28D9);

  static const Color physics = Color(0xFFD97706);
  static const Color physicsLight = Color(0xFFFEF3C7);
  static const Color physicsDark = Color(0xFFB45309);

  static Color of(String subject) {
    switch (subject.toLowerCase()) {
      case 'biology':
      case 'bio':
      case 'botany':
      case 'zoology':
        return biology;
      case 'chemistry':
      case 'chem':
        return chemistry;
      case 'physics':
      case 'phys':
        return physics;
      default:
        return biology;
    }
  }

  static Color lightOf(String subject) {
    switch (subject.toLowerCase()) {
      case 'biology':
      case 'bio':
      case 'botany':
      case 'zoology':
        return biologyLight;
      case 'chemistry':
      case 'chem':
        return chemistryLight;
      case 'physics':
      case 'phys':
        return physicsLight;
      default:
        return biologyLight;
    }
  }

  static Color darkOf(String subject) {
    switch (subject.toLowerCase()) {
      case 'biology':
      case 'bio':
      case 'botany':
      case 'zoology':
        return biologyDark;
      case 'chemistry':
      case 'chem':
        return chemistryDark;
      case 'physics':
      case 'phys':
        return physicsDark;
      default:
        return biologyDark;
    }
  }
}
