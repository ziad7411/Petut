import 'package:flutter/material.dart';
import 'package:petut/app_colors.dart';


final ThemeData lightTheme = ThemeData(
  scaffoldBackgroundColor: AppColors.background,
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.background,
    foregroundColor: AppColors.dark,
  ),
  textTheme: const TextTheme(
    bodyMedium: TextStyle(color: AppColors.dark),
  ),
  iconTheme: const IconThemeData(color: AppColors.dark),
  colorScheme: const ColorScheme.light(
    primary: AppColors.gold,
    secondary: AppColors.gray,
    error: AppColors.error,
  ),
);