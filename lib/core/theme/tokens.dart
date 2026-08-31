import 'package:flutter/material.dart';

/// Design tokens for NEET Mitos.
/// All spacing, radii, durations, and subject colors live here.
/// Import this file — never hardcode these values in screens.
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

/// Unified subject color palette.
/// Biology = teal-green, Chemistry = purple, Physics = amber.
abstract final class SubjectColors {
  static const Color biology = Color(0xFF10B981);
  static const Color biologyLight = Color(0xFFD1FAE5);
  static const Color biologyDark = Color(0xFF059669);

  static const Color chemistry = Color(0xFF9D4EDD);
  static const Color chemistryLight = Color(0xFFEDE9F6);
  static const Color chemistryDark = Color(0xFF7C3AED);

  static const Color physics = Color(0xFFF59E0B);
  static const Color physicsLight = Color(0xFFFEF3C7);
  static const Color physicsDark = Color(0xFFD97706);

  static Color of(String subject) {
    switch (subject.toLowerCase()) {
      case 'biology':
        return biology;
      case 'chemistry':
        return chemistry;
      case 'physics':
        return physics;
      default:
        return biology;
    }
  }

  static Color lightOf(String subject) {
    switch (subject.toLowerCase()) {
      case 'biology':
        return biologyLight;
      case 'chemistry':
        return chemistryLight;
      case 'physics':
        return physicsLight;
      default:
        return biologyLight;
    }
  }

  static Color darkOf(String subject) {
    switch (subject.toLowerCase()) {
      case 'biology':
        return biologyDark;
      case 'chemistry':
        return chemistryDark;
      case 'physics':
        return physicsDark;
      default:
        return biologyDark;
    }
  }
}
