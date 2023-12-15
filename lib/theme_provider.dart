import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  // SharedPreferences key for storing the theme preference
  static const String _themeKey = 'theme_preference';

  // Constructor to load the theme preference on initialization
  ThemeProvider() {
    _loadThemeMode();
  }

  // Load the theme preference from SharedPreferences
  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final savedThemeMode = prefs.getString(_themeKey);

    if (savedThemeMode != null) {
      _themeMode = ThemeMode.values.firstWhere(
        (mode) => mode.toString() == savedThemeMode,
        orElse: () => ThemeMode.system,
      );
      notifyListeners();
    }
  }

  // Save the theme preference to SharedPreferences
  Future<void> _saveThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(_themeKey, _themeMode.toString());
  }

  // Set the theme mode and save it
  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
    _saveThemeMode();
  }
}
