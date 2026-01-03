import 'package:flutter/material.dart';

class AppColors {
  // Primary Branding Colors (from logo)
  static const Color primary = Color(0xFFD7A417); // Gold - main accent
  static const Color primaryVariant = Color(
    0xFF956333,
  ); // Deep Gold/Bronze tone

  // Secondary UI Supporting Shades
  static const Color secondary = Color(0xFFE2CC8C); // Soft gold shade
  static const Color secondaryVariant = Color(0xFFF6EDCE); // Light cream-gold

  // Background & Surface
  static const Color background = Color(0xFFFDFDF8); // Off-white (base)
  static const Color surface = Colors.white; // Cards, containers

  // State Colors
  static const Color error = Color(0xFFB00020);

  // Text / On-Color Contrast
  static const Color onPrimary = Colors.white; // Text on primary buttons
  static const Color onSecondary = Colors.black; // Text on lighter gold
  static const Color onBackground = Colors.black;
  static const Color onSurface = Colors.black;
  static const Color onError = Colors.white;
}
