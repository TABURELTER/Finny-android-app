/// Finny Theme — Полная тема Material 3 с локальным Nunito
///
/// Заменяет старую тему. Экспортирует обратно-совместимый `FinnyColors`
/// для плавной миграции старого кода (все поля переименованы на новые значения).
library;

import 'package:flutter/material.dart';

import 'finny_tokens.dart' as tokens;

// ─────────────────────────────────────────────
//  Backward-compatible FinnyColors
//  (старые экраны ссылаются на FinnyColors.textDark и т.д.)
// ─────────────────────────────────────────────

class FinnyColors {
  // Brand
  static Color get primary => tokens.FinnyColors.primary;
  static Color get primaryLight => tokens.FinnyColors.primaryLight;
  static Color get primaryDark => tokens.FinnyColors.primaryDark;

  // Coin
  static const Color coinGold = tokens.FinnyColors.coin;
  static const Color coinGoldLight = tokens.FinnyColors.coinLight;
  static const Color coinGoldDark = Color(0xFFD97706);

  // Piggy
  static const Color piggyPink = tokens.FinnyColors.piggy;
  static const Color piggyPinkLight = tokens.FinnyColors.piggyLight;

  // Food
  static const Color foodGreen = tokens.FinnyColors.food;
  static const Color foodGreenLight = tokens.FinnyColors.foodLight;

  // Sky/Info
  static const Color skyBlue = Color(0xFF3B82F6);
  static const Color skyBlueLight = Color(0xFFEFF6FF);

  // Surfaces
  static const Color background = tokens.FinnyColors.background;
  static const Color cardBackground = tokens.FinnyColors.surface;

  // Wood → deprecated → mapped to neutrals
  static const Color woodTrim = Color(0xFF94A3B8);
  static const Color woodLight = tokens.FinnyColors.surfaceMuted;
  static const Color woodFloor = tokens.FinnyColors.surfaceMuted;
  static const Color woodFloorBorder = tokens.FinnyColors.border;

  // Text
  static const Color textDark = tokens.FinnyColors.textPrimary;
  static const Color textMuted = tokens.FinnyColors.textSecondary;

  // Accent / Warning
  static Color get accentPurple => tokens.FinnyColors.accent;
  static const Color warningRed = tokens.FinnyColors.danger;
  static const Color borderSubtle = tokens.FinnyColors.border;

  static List<BoxShadow> get cardShadow => tokens.FinnyShadows.md;
}

// ─────────────────────────────────────────────
//  ThemeData
// ─────────────────────────────────────────────

class FinnyTheme {
  static ThemeData get lightTheme {
    final baseTextTheme = ThemeData(
      useMaterial3: true,
      fontFamily: 'Nunito',
    ).textTheme;

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Nunito',
      scaffoldBackgroundColor: tokens.FinnyColors.background,
      primaryColor: tokens.FinnyColors.primary,
      colorScheme: ColorScheme.fromSeed(
        seedColor: tokens.FinnyColors.primary,
        surface: tokens.FinnyColors.surface,
        onSurface: tokens.FinnyColors.textPrimary,
        primary: tokens.FinnyColors.primary,
        onPrimary: tokens.FinnyColors.textInverse,
        secondary: tokens.FinnyColors.accent,
        error: tokens.FinnyColors.danger,
        brightness: Brightness.light,
      ),
      textTheme: baseTextTheme.copyWith(
        headlineLarge: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: tokens.FinnyColors.textPrimary,
          letterSpacing: -0.5,
          height: 1.2,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: tokens.FinnyColors.textPrimary,
          height: 1.2,
        ),
        titleLarge: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: tokens.FinnyColors.textPrimary,
        ),
        titleMedium: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: tokens.FinnyColors.textPrimary,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: tokens.FinnyColors.textPrimary,
          height: 1.4,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: tokens.FinnyColors.textSecondary,
          height: 1.4,
        ),
        bodySmall: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: tokens.FinnyColors.textTertiary,
          height: 1.3,
        ),
        labelLarge: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: tokens.FinnyColors.textPrimary,
        ),
        labelMedium: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: tokens.FinnyColors.textSecondary,
        ),
        labelSmall: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: tokens.FinnyColors.textTertiary,
          letterSpacing: 0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: tokens.FinnyColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: tokens.FinnyRadius.cardRadius,
          side: const BorderSide(color: tokens.FinnyColors.border, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: tokens.FinnyColors.primary,
          foregroundColor: tokens.FinnyColors.textInverse,
          minimumSize: const Size(48, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: tokens.FinnyRadius.buttonRadius,
          ),
          textStyle: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: tokens.FinnyColors.primary,
          minimumSize: const Size(48, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          side: const BorderSide(color: tokens.FinnyColors.border, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: tokens.FinnyRadius.buttonRadius,
          ),
          textStyle: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: tokens.FinnyColors.primary,
          textStyle: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: tokens.FinnyColors.divider,
        space: 1,
        thickness: 1,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: tokens.FinnyColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: tokens.FinnyColors.textPrimary,
        ),
        iconTheme: const IconThemeData(
          color: tokens.FinnyColors.textSecondary,
          size: 22,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        modalBarrierColor: Color(0x33000000),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(tokens.FinnyRadius.xl),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: tokens.FinnyColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.FinnyRadius.xl),
        ),
        elevation: 0,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: tokens.FinnyColors.textPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.FinnyRadius.sm),
        ),
        contentTextStyle: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: tokens.FinnyColors.textInverse,
        ),
      ),
      tabBarTheme: TabBarThemeData(
        indicatorColor: tokens.FinnyColors.primary,
        labelColor: tokens.FinnyColors.primary,
        unselectedLabelColor: tokens.FinnyColors.textTertiary,
        labelStyle: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
