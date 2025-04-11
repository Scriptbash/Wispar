import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  Locale? _locale;

  Locale? get locale => _locale;

  LocaleProvider() {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString('locale');
    if (code != null) {
      _locale = Locale(code);
      notifyListeners();
    }
  }

  Future<void> setLocale(String code) async {
    _locale = Locale(code);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale', code);
    notifyListeners();
  }

  Future<void> clearLocale() async {
    _locale = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('locale');
    notifyListeners();
  }
}
