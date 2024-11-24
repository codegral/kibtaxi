import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> setTheme(ThemeMode themeMode) async {
    _themeMode = themeMode;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("theme", themeMode.toString());

    notifyListeners();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    String? theme = prefs.getString("theme");

    if (theme != null) {
      switch (theme) {
        case "ThemeMode.dark":
          _themeMode = ThemeMode.dark;
          break;

        case "ThemeMode.light":
          _themeMode = ThemeMode.light;
          break;

        default:
          _themeMode = ThemeMode.system;
          break;
      }
    }

    notifyListeners();
  }
}
