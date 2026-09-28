/// Finny Design Tokens
/// Единый источник правды для цветов, скруглений, отступов, анимаций.
library;

import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
//  ЦВЕТОВАЯ ПАЛИТРА
// ─────────────────────────────────────────────

abstract final class FinnyColors {
  // ── Brand ──
  static Color primary = const Color(0xFFC94C19);
  static Color primaryLight = const Color(0xFFFFE5D5);
  static Color primaryDark = const Color(0xFF9F3815);

  // ── Accent (Копилка / Цели) ──
  static Color accent = const Color(0xFFC94C19);
  static Color accentLight = const Color(0xFFFFE5D5);

  static void setAccent(Color chosen) {
    if (chosen == const Color(0xFF6B3DC6) ||
        chosen == const Color(0xFF5B249B) ||
        chosen == const Color(0xFFD65321) ||
        chosen == const Color(0xFFC94C19)) {
      primary = const Color(0xFFC94C19);
      primaryDark = const Color(0xFF9F3815);
      primaryLight = const Color(0xFFFFE5D5);
      accent = primary;
      accentLight = primaryLight;
      return;
    }
    final hsv = HSVColor.fromColor(chosen);
    // Keep white button labels readable even when a very pale hue is picked.
    var value = hsv.value;
    primary = hsv.withValue(value).toColor();
    while (primary.computeLuminance() > .26 && value > .15) {
      value *= .9;
      primary = hsv.withValue(value).toColor();
    }
    primaryDark = Color.lerp(primary, Colors.black, .25)!;
    primaryLight = Color.lerp(primary, Colors.white, .86)!;
    accent = primary;
    accentLight = primaryLight;
  }

  // ── Semantic ──
  static const Color success = Color(0xFF19855D);
  static const Color successLight = Color(0xFFE5F4EB);
  static const Color warning = Color(0xFFAC6324);
  static const Color warningLight = Color(0xFFFFEBCF);
  static const Color danger = Color(0xFFC74747);
  static const Color dangerLight = Color(0xFFFBE8E6);

  // ── Coin Gold ──
  static const Color coin = Color(0xFFD59020);
  static const Color coinLight = Color(0xFFFFE8AB);

  // ── Surfaces ──
  static const Color background = Color(0xFFF8F6F2);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceElevated = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF4EFE9);

  // ── Text ──
  static const Color textPrimary = Color(0xFF232326);
  static const Color textSecondary = Color(0xFF595A60);
  static const Color textTertiary = Color(0xFF77777E);
  static const Color textInverse = Color(0xFFFFFFFF);

  // ── Borders & Dividers ──
  static const Color border = Color(0xFFE1DCD5);
  static const Color borderLight = Color(0xFFEDE9E3);
  static const Color divider = Color(0xFFEDE9E3);

  // ── Food ──
  static const Color food = Color(0xFF19855D);
  static const Color foodLight = Color(0xFFE5F4EB);

  // ── Piggy / Savings ──
  static const Color piggy = Color(0xFFB35F78);
  static const Color piggyLight = Color(0xFFF9E7EE);
}

// ─────────────────────────────────────────────
//  СКРУГЛЕНИЯ
// ─────────────────────────────────────────────

abstract final class FinnyRadius {
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double full = 999;

  static BorderRadius get cardRadius => BorderRadius.circular(md);
  static BorderRadius get sheetRadius =>
      const BorderRadius.vertical(top: Radius.circular(xl));
  static BorderRadius get buttonRadius => BorderRadius.circular(sm);
  static BorderRadius get chipRadius => BorderRadius.circular(full);
  static BorderRadius get badgeRadius => BorderRadius.circular(xs);
}

// ─────────────────────────────────────────────
//  ОТСТУПЫ
// ─────────────────────────────────────────────

abstract final class FinnySpacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 48;

  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: lg,
    vertical: md,
  );
  static const EdgeInsets cardPadding = EdgeInsets.all(lg);
  static const EdgeInsets sheetPadding = EdgeInsets.symmetric(
    horizontal: xl,
    vertical: lg,
  );
}

// ─────────────────────────────────────────────
//  ТЕНИ
// ─────────────────────────────────────────────

abstract final class FinnyShadows {
  static List<BoxShadow> get sm => [
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.04),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> get md => [
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.06),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get lg => [
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.08),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get glow => [
    BoxShadow(
      color: FinnyColors.primary.withValues(alpha: 0.2),
      blurRadius: 20,
      spreadRadius: 2,
    ),
  ];
}

// ─────────────────────────────────────────────
//  ДЛИТЕЛЬНОСТИ АНИМАЦИЙ
// ─────────────────────────────────────────────

abstract final class FinnyDurations {
  static const Duration instant = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration entrance = Duration(milliseconds: 400);
  static const Duration stagger = Duration(milliseconds: 80);
}

// ─────────────────────────────────────────────
//  КРИВЫЕ
// ─────────────────────────────────────────────

abstract final class FinnyCurves {
  static const Curve defaultCurve = Curves.easeOutCubic;
  static const Curve bounce = Curves.elasticOut;
  static const Curve entrance = Curves.easeOutQuart;
  static const Curve exit = Curves.easeInCubic;
}
