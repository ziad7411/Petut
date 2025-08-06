import 'package:flutter/material.dart';
import 'package:petut/app_colors.dart';

final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: AppColors.darkBackground,
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.darkBackground,
    foregroundColor: AppColors.darkTextPrimary,
    elevation: 0,
  ),
  textTheme: const TextTheme(
    bodyMedium: TextStyle(color: AppColors.darkTextPrimary),
  ),
  iconTheme: const IconThemeData(color: AppColors.darkTextPrimary),
  colorScheme: const ColorScheme.dark(
    primary: AppColors.darkPrimary,
    secondary: AppColors.darkSecondary,
    error: Colors.red,
    background: AppColors.darkBackground,
    surface: AppColors.darkSurface,
    onPrimary: Colors.black,
    onSecondary: Colors.white,
    onBackground: AppColors.darkTextPrimary,
    onSurface: AppColors.darkTextSecondary,
    onError: Colors.black,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.darkAccent,
      foregroundColor: Colors.white,
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.darkSurface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: AppColors.darkPrimary.withOpacity(0.7), width: 1.5),
    ),
  ),
  cardTheme: CardThemeData(
    elevation: 4,
    shadowColor: Colors.black.withOpacity(0.3),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
  ),
);              


  