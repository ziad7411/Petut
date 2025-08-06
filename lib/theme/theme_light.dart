import 'package:flutter/material.dart';
import 'package:petut/app_colors.dart';

final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  scaffoldBackgroundColor: AppColors.lightBackground,
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.lightBackground,
    foregroundColor: AppColors.lightTextPrimary,
    elevation: 0,
  ),
  textTheme: const TextTheme(
    bodyMedium: TextStyle(color: AppColors.lightTextPrimary),
  ),
  iconTheme: const IconThemeData(color: AppColors.lightTextPrimary),
  colorScheme: const ColorScheme.light(
    primary: AppColors.lightPrimary,
    secondary: AppColors.lightSecondary,
    error: Colors.red,
    background: AppColors.lightBackground,
    surface: AppColors.lightSurface,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onBackground: AppColors.lightTextPrimary,
    onSurface: AppColors.lightTextSecondary,
    onError: Colors.white,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.lightAccent,
      foregroundColor: Colors.white,
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.lightSurface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: Colors.grey.withOpacity(0.1), width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: AppColors.lightPrimary.withOpacity(0.5), width: 1.5),
    ),
  ),
  cardTheme: CardThemeData(
    elevation: 4,
    shadowColor: Colors.black.withOpacity(0.08),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
  ),
);