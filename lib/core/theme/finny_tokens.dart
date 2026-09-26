/// Finny Design Tokens
/// Единый источник правды для цветов, скруглений, отступов, анимаций.
library;

import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
//  ЦВЕТОВАЯ ПАЛИТРА
// ─────────────────────────────────────────────

abstract final class FinnyColors {
  // ── Brand ──
  static const Color primary = Color(0xFF6B3DC6);
  static const Color primaryLight = Color(0xFFEEE1FF);
  static const Color primaryDark = Color(0xFF4F269D);

  // ── Accent (Копилка / Цели) ──
  static const Color accent = Color(0xFF6C63FF);
  static const Color accentLight = Color(0xFFEEECFF);

  // ── Semantic ──
  static const Color success = Color(0xFF187B52);
  static const Color successLight = Color(0xFFDDF5E4);
  static const Color warning = Color(0xFF9D4A22);
  static const Color warningLight = Color(0xFFFFE8D2);
  static const Color danger = Color(0xFFEF4444);
  static const Color dangerLight = Color(0xFFFEF2F2);

  // ── Coin Gold ──
  static const Color coin = Color(0xFFF59E0B);
  static const Color coinLight = Color(0xFFFFE9A3);

  // ── Surfaces ──
  static const Color background = Color(0xFFFFF9ED);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceElevated = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF7F0E9);

  // ── Text ──
  static const Color textPrimary = Color(0xFF342B50);
  static const Color textSecondary = Color(0xFF586174);
  static const Color textTertiary = Color(0xFF6E7280);
  static const Color textInverse = Color(0xFFFFFFFF);

  // ── Borders & Dividers ──
  static const Color border = Color(0xFFD8D1DF);
  static const Color borderLight = Color(0xFFEDE5EA);
  static const Color divider = Color(0xFFEDE5EA);

  // ── Food ──
  static const Color food = Color(0xFF187B52);
  static const Color foodLight = Color(0xFFDDF5E4);

  // ── Piggy / Savings ──
  static const Color piggy = Color(0xFFB73778);
  static const Color piggyLight = Color(0xFFFCE4F1);
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
