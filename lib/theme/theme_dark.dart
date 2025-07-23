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
    ),
  ),
);
