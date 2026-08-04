import 'package:flutter/material.dart';

class ThemeModel with ChangeNotifier {
  bool _isDark = false;

  bool get isDark => _isDark;

  void setDarkMode(bool value) {
    _isDark = value;
    notifyListeners();
  }

  void toggleTheme() {
    setDarkMode(!_isDark);
  }
}
