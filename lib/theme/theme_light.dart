import 'package:flutter/material.dart';
import 'package:petut/app_colors.dart';

final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  scaffoldBackgroundColor: AppColors.lightBackground,
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.lightBackground,
    foregroundColor: AppColors.lightTextPrimary,
    iconTheme: IconThemeData(color: AppColors.lightTextPrimary),
    titleTextStyle: TextStyle(
      color: AppColors.lightTextPrimary,
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
  ),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: AppColors.lightTextPrimary),
    bodyMedium: TextStyle(color: AppColors.lightTextSecondary),
  ),
  iconTheme: const IconThemeData(color: AppColors.lightTextPrimary),
  colorScheme: const ColorScheme.light(
    primary: AppColors.lightPrimary,
    secondary: AppColors.lightSecondary,
    background: AppColors.lightBackground,
    surface: AppColors.lightSurface,
    error: AppColors.lightAccent, // استخدمنا اللون البرتقالي كمثال للـ accent
    onPrimary: AppColors.lightTextPrimary,
    onSecondary: AppColors.lightTextPrimary,
    onBackground: AppColors.lightTextPrimary,
    onSurface: AppColors.lightTextPrimary,
    onError: AppColors.lightTextPrimary,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.lightAccent,
      foregroundColor: AppColors.lightTextPrimary,
    ),
  ),
);
