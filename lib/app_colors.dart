import 'package:flutter/material.dart';

class AppColors {
  // 🌞 Light Theme Colors
  static const Color lightPrimary = Color(0xFFFFC107);
  static const Color lightSecondary = Color(0xFF2196F3);
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFF5F5F5);
  static const Color lightTextPrimary = Color(0xFF212121);
  static const Color lightTextSecondary = Color(0xFF757575);
  static const Color lightAccent = Color(0xFFFF7043);

  // 🌚 Dark Theme Colors
  static const Color darkPrimary = Color(0xFFFFB300);
  static const Color darkSecondary = Color(0xFF1565C0);
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFBDBDBD);
  static const Color darkAccent = Color(0xFFFF8A65);

  // 🧠 Theme-aware Getters
  static Color getPrimaryColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? darkPrimary
          : lightPrimary;

  static Color getSecondaryColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? darkSecondary
          : lightSecondary;

  static Color getBackgroundColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? darkBackground
          : lightBackground;

  static Color getSurfaceColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? darkSurface
          : lightSurface;

  static Color getTextPrimaryColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? darkTextPrimary
          : lightTextPrimary;

  static Color getTextSecondaryColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? darkTextSecondary
          : lightTextSecondary;

  static Color getAccentColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? darkAccent
          : lightAccent;
}
