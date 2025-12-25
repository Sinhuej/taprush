import 'package:flutter/material.dart';

/// TapRush color palette (based on Option 3 icon)
class TapRushColors {
  // Background gradient (icon background)
  static const Color backgroundDark = Color(0xFF141229); // deep indigo
  static const Color backgroundLight = Color(0xFF262C5C); // blue-violet

  // Main accent (bright bar + glow)
  static const Color primary = Color(0xFF00D4FF); // cyan / electric blue

  // Secondary accent (hot pink)
  static const Color secondary = Color(0xFFFF4F9A);

  // Tertiary accent (lime / yellow bar)
  static const Color tertiary = Color(0xFFFFD44F);

  // Neutral for text
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFB7C0FF);

  // Card / surface
  static const Color surface = Color(0xFF1C1F3C);
}

ThemeData tapRushTheme = ThemeData(
  useMaterial3: true,
  fontFamily: 'Roboto', // or whatever you set in pubspec
  colorScheme: ColorScheme.fromSeed(
    seedColor: TapRushColors.primary,
    brightness: Brightness.dark,
    primary: TapRushColors.primary,
    secondary: TapRushColors.secondary,
    background: TapRushColors.backgroundDark,
    surface: TapRushColors.surface,
  ),
  scaffoldBackgroundColor: TapRushColors.backgroundDark,
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    elevation: 0,
    centerTitle: true,
    titleTextStyle: TextStyle(
      color: TapRushColors.textPrimary,
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
  ),
  textTheme: const TextTheme(
    bodyMedium: TextStyle(
      color: TapRushColors.textPrimary,
      fontSize: 16,
    ),
    labelLarge: TextStyle(
      color: TapRushColors.textPrimary,
      fontWeight: FontWeight.w600,
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: TapRushColors.primary,
      foregroundColor: TapRushColors.backgroundDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    ),
  ),
);
