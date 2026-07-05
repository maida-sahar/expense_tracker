// lib/theme/app_theme.dart
//
// Centralized design tokens: palette, gradients, typography, and the
// light/dark ThemeData built from them. Keeping this in one file means the
// rest of the app pulls colors from Theme.of(context) rather than hardcoding
// hex values everywhere.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  AppColors._();

  // Brand — deep teal/emerald, distinct from the generic purple/blue most
  // finance-app templates default to.
  static const primary = Color.fromARGB(255, 54, 201, 179);
  static const primaryLight = Color.fromARGB(255, 61, 157, 138);
  static const primaryDark = Color(0xFF082E28);

  static const income = Color.fromARGB(255, 48, 193, 108);
  static const expense = Color(0xFFFF6B6B);
  static const budgetWarn = Color(0xFFFFB020);

  static const heroGradient = [Color.fromARGB(255, 31, 148, 130), Color.fromARGB(255, 41, 173, 147)];
  static const heroGradientDark = [Color(0xFF061F1B), Color(0xFF0E4F45)];

  static const lightBg = Color(0xFFF4F7F6);
  static const darkBg = Color(0xFF0B1210);
  static const darkSurface = Color(0xFF141F1C);
}

TextTheme _textTheme(Brightness brightness) {
  final base = brightness == Brightness.dark
      ? Typography.whiteMountainView
      : Typography.blackMountainView;
  final body = GoogleFonts.interTextTheme(base);
  final display = GoogleFonts.manropeTextTheme(base);
  return body.copyWith(
    displayLarge: display.displayLarge,
    displayMedium: display.displayMedium,
    displaySmall: display.displaySmall,
    headlineLarge: display.headlineLarge?.copyWith(fontWeight: FontWeight.w800),
    headlineMedium: display.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
    headlineSmall: display.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
    titleLarge: display.titleLarge?.copyWith(fontWeight: FontWeight.w700),
    titleMedium: display.titleMedium?.copyWith(fontWeight: FontWeight.w600),
  );
}

ThemeData buildLightTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: Brightness.light,
  ).copyWith(
    primary: AppColors.primary,
    error: AppColors.expense,
    surface: Colors.white,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.lightBg,
    textTheme: _textTheme(Brightness.light),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: Colors.white,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFEFF3F2),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      elevation: 0,
    ),
  );
}

ThemeData buildDarkTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.primaryLight,
    brightness: Brightness.dark,
  ).copyWith(
    primary: AppColors.primaryLight,
    error: AppColors.expense,
    surface: AppColors.darkSurface,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.darkBg,
    textTheme: _textTheme(Brightness.dark),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: AppColors.darkSurface,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withOpacity(0.06),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.primaryLight,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: AppColors.darkSurface,
      elevation: 0,
    ),
  );
}
