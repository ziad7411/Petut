import 'package:flutter/material.dart';

class AppColors {
  // Light Theme Colors
  static const Color background = Color(0xFFf7f3eb);
  static const Color fieldColor = Color(0xFFe5e2d3);
  static const Color gray = Color(0xFF8c8a80);
  static const Color gold = Color(0xFFd9a741);
  static const Color dark = Color(0xFF2c2c2c);
  static const Color error = Color(0xFFE53935);

  // Dark Theme Colors
  static const Color darkGrayBackground = Color(0xFF4A444A);
  static const Color darkText = Color(0xFFB0B0B0);
  static const Color yellow = Color(0xFFF7C948);
  static const Color goldDark = Color(0xFFE5B733);
  static const Color darkGold = Color(0xFFC29229);

  // Theme-aware colors
  static Color getBackgroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1a1a1a)
        : background;
  }

  static Color getSurfaceColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF2d2d2d)
        : fieldColor;
  }

  static Color getTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? darkText : dark;
  }

  static Color getSecondaryTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkText.withOpacity(0.7)
        : gray;
  }

  static Color getPrimaryColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? goldDark : gold;
  }

  static Color getErrorColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFCF6679)
        : error;
  }
}
