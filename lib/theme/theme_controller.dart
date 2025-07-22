import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController with ChangeNotifier {
  bool _isDark = false;
  bool get isDark => _isDark;

  ThemeMode get themeMode => _isDark ? ThemeMode.dark : ThemeMode.light;

  ThemeController() {
    _loadThemeFromPrefs(); 
  }

  void toggleTheme() async {
    _isDark = !_isDark;
    notifyListeners();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDark);
  }

  Future<void> _loadThemeFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _isDark = prefs.getBool('isDarkMode') ?? false;
    notifyListeners(); 
  }

  ThemeData get lightTheme => ThemeData(
        brightness: Brightness.light,
        primaryColor: Color(0xFFFF7B00), // Orange (Main button color)
        scaffoldBackgroundColor: Color(0xFFF9F9F9),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(color: Colors.black, fontSize: 20),
        ),
        colorScheme: ColorScheme.light(
          primary: Color(0xFFFF7B00),
          secondary: Color(0xFF444444),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFFFF7B00), // Orange button
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );

  ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        primaryColor: Color(0xFFAE7EFF), // Purple
        scaffoldBackgroundColor: Color(0xFF1C1C1E),
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF1C1C1E),
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
        ),
        colorScheme: ColorScheme.dark(
          primary: Color(0xFFAE7EFF),
          secondary: Color(0xFFE0E0E0),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFFAE7EFF), // Purple button
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
}
