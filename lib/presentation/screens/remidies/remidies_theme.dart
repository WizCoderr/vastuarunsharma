// Design Tokens & Colors for Remidies Module
// Use this in your theme configuration

import 'package:flutter/material.dart';

class RemidiesColors {
  // Primary colors
  static const Color primary = Color(0xFFD4AF37); // Gold (₹ currency color)
  static const Color primaryDark = Color(0xFFB8941B);
  static const Color primaryLight = Color(0xFFE8C547);

  // Secondary colors
  static const Color secondary = Color(0xFF1B3A2D); // Dark green (hero banner)
  static const Color secondaryLight = Color(0xFF2D5A45);

  // Status colors
  static const Color success = Color(0xFF4CAF50); // Green (delivered, in stock)
  static const Color warning = Color(0xFFFFC107); // Amber (pending)
  static const Color error = Color(0xFFF44336); // Red (out of stock, cancelled)
  static const Color info = Color(0xFF2196F3); // Blue (paid)
  static const Color shipped = Color(0xFF9C27B0); // Purple (shipped)

  // Neutral colors
  static const Color dark = Color(0xFF212121);
  static const Color darkGrey = Color(0xFF424242);
  static const Color grey = Color(0xFF757575);
  static const Color lightGrey = Color(0xFFBDBDBD);
  static const Color light = Color(0xFFEEEEEE);
  static const Color white = Color(0xFFFFFFFF);

  // Background colors
  static const Color lightBackground = Color(0xFFF5F5F5);
  static const Color cardBackground = Color(0xFFFFFFFF);
}

class RemidiesTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: RemidiesColors.primary,
      scaffoldBackgroundColor: RemidiesColors.lightBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: RemidiesColors.white,
        foregroundColor: RemidiesColors.dark,
        elevation: 0,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: RemidiesColors.light,
        selectedColor: RemidiesColors.primary,
        labelStyle: const TextStyle(
          color: RemidiesColors.dark,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: RemidiesColors.primary,
          foregroundColor: RemidiesColors.white,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: RemidiesColors.primary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: RemidiesColors.light,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: RemidiesColors.lightGrey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: RemidiesColors.lightGrey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: RemidiesColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: RemidiesColors.dark,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: RemidiesColors.dark,
        ),
        headlineSmall: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: RemidiesColors.dark,
        ),
        titleLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: RemidiesColors.dark,
        ),
        titleMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: RemidiesColors.dark,
        ),
        bodyLarge: TextStyle(fontSize: 16, color: RemidiesColors.dark),
        bodyMedium: TextStyle(fontSize: 14, color: RemidiesColors.dark),
        labelSmall: TextStyle(fontSize: 12, color: RemidiesColors.grey),
      ),
    );
  }
}

class RemidiesIconSize {
  static const double small = 16;
  static const double medium = 24;
  static const double large = 32;
  static const double extraLarge = 48;
}

class RemidiesBorderRadius {
  static const double small = 4;
  static const double medium = 8;
  static const double large = 12;
  static const double extraLarge = 16;
  static const double full = 999;
}

class RemidiesPadding {
  static const double extraSmall = 4;
  static const double small = 8;
  static const double medium = 12;
  static const double large = 16;
  static const double extraLarge = 24;
}

class RemidiesSpacing {
  static const double extraSmall = 4;
  static const double small = 8;
  static const double medium = 12;
  static const double large = 16;
  static const double extraLarge = 24;
  static const double xxl = 32;
}
