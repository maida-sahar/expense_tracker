// lib/theme/app_theme.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  AppColors._();

  // CashFlow Pro Dark Emerald Palette (inspired by reference UI)
  static const primary = Color(0xFF10B981); // Mint green accent
  static const primaryLight = Color(0xFF34D399);
  static const primaryDark = Color(0xFF047857);

  static const income = Color(0xFF10B981);
  static const expense = Color(0xFFF97316); // Vibrant Coral / Neon Orange
  static const budgetWarn = Color(0xFFF59E0B);

  // CashFlow Pro Dark Backgrounds & Surfaces
  static const darkBg = Color(0xFF0B1513);
  static const darkSurface = Color(0xFF122320);
  static const darkCard = Color(0xFF162C27);
  static const darkBorder = Color(0xFF1F3D36);

  static const lightBg = Color(0xFFF3F6F5);
  static const lightSurface = Color(0xFFFFFFFF);

  static const heroGradientDark = [
    Color(0xFF071B17),
    Color(0xFF0E3029),
  ];

  static const heroGradientLight = [
    Color(0xFF0D9488),
    Color(0xFF10B981),
  ];
}

TextTheme _textTheme(Brightness brightness) {
  final base = brightness == Brightness.dark
      ? Typography.whiteMountainView
      : Typography.blackMountainView;
  final body = GoogleFonts.plusJakartaSansTextTheme(base);
  final display = GoogleFonts.outfitTextTheme(base);
  return body.copyWith(
    displayLarge: display.displayLarge?.copyWith(fontWeight: FontWeight.w800),
    displayMedium: display.displayMedium?.copyWith(fontWeight: FontWeight.w800),
    displaySmall: display.displaySmall?.copyWith(fontWeight: FontWeight.w700),
    headlineLarge: display.headlineLarge?.copyWith(fontWeight: FontWeight.w800),
    headlineMedium: display.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
    headlineSmall: display.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
    titleLarge: display.titleLarge?.copyWith(fontWeight: FontWeight.w700),
    titleMedium: display.titleMedium?.copyWith(fontWeight: FontWeight.w600),
    titleSmall: display.titleSmall?.copyWith(fontWeight: FontWeight.w600),
  );
}

ThemeData buildLightTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: Brightness.light,
  ).copyWith(
    primary: AppColors.primary,
    secondary: AppColors.primaryDark,
    error: AppColors.expense,
    surface: AppColors.lightSurface,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.lightBg,
    textTheme: _textTheme(Brightness.light),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      color: Colors.white,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFEDF2F1),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: Color(0xFF0F172A),
      elevation: 0,
      centerTitle: false,
    ),
  );
}

ThemeData buildDarkTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: Brightness.dark,
  ).copyWith(
    primary: AppColors.primary,
    secondary: AppColors.primaryLight,
    error: AppColors.expense,
    surface: AppColors.darkSurface,
    surfaceContainerHighest: AppColors.darkCard,
    onSurfaceVariant: const Color(0xFF94A3B8),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.darkBg,
    textTheme: _textTheme(Brightness.dark),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: AppColors.darkBorder, width: 1),
      ),
      color: AppColors.darkCard,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.darkSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.darkBorder, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.darkBorder, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
    ),
  );
}

