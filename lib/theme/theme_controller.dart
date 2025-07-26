import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/scheduler.dart';

class ThemeController with ChangeNotifier {
  bool? _isDark; // nullable to differentiate if not set
  bool get isDark {
    if (_isDark != null) return _isDark!;
    // Default to system brightness
    var brightness = SchedulerBinding.instance.window.platformBrightness;
    return brightness == Brightness.dark;
  }

  ThemeMode get themeMode {
    if (_isDark == null) return ThemeMode.system;
    return _isDark! ? ThemeMode.dark : ThemeMode.light;
  }

  ThemeController() {
    _loadThemeFromPrefs();
  }

  Future<void> toggleTheme() async {
    _isDark = !isDark; // Toggle current mode
    notifyListeners();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDark!);
  }

  Future<void> _loadThemeFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('isDarkMode')) {
      _isDark = prefs.getBool('isDarkMode');
    } else {
      _isDark = null; // Use system default
    }
    notifyListeners();
  }
}
