import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'is_dark_mode';
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_themeKey) ?? false;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, _isDarkMode);
    notifyListeners();
  }

  ThemeData get currentTheme {
    return _isDarkMode
        ? ThemeData(
            brightness: Brightness.dark,
            primarySwatch: Colors.purple,
            colorScheme: ColorScheme.dark(
              primary: Colors.purpleAccent,
              secondary: Colors.purple,
              surface: Color(0xFF121212), 
            ),
            useMaterial3: true,
          )
        : ThemeData(
            brightness: Brightness.light,
            primarySwatch: Colors.purple,
            colorScheme: ColorScheme.light(
              primary: Colors.purple,
              secondary: Colors.purpleAccent,
            ),
            useMaterial3: true,
          );
  }
}
