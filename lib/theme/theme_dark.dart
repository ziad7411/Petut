import 'package:flutter/material.dart';
import 'package:petut/app_colors.dart';


final ThemeData darkTheme = ThemeData(
  scaffoldBackgroundColor: AppColors.darkGrayBackground,
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.darkGrayBackground,
    foregroundColor: Colors.white,
  ),
  textTheme: const TextTheme(
    bodyMedium: TextStyle(color: AppColors.darkText),
  ),
  iconTheme: const IconThemeData(color: Colors.white),
  colorScheme: const ColorScheme.dark(
    primary: AppColors.yellow,
    secondary: AppColors.darkGold,
    error: AppColors.error,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.goldDark,
      foregroundColor: Colors.black,
    ),
  ),
);
