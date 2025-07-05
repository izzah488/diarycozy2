import 'package:flutter/material.dart';
import 'themes.dart'; // contains lightTheme and darkTheme

class ThemeProvider extends ChangeNotifier {
  ThemeData _theme = lightTheme;
  String _themeName = 'light';

  ThemeData get theme => _theme;
  String get themeName => _themeName;

  void setTheme(String themeKey) {
    if (themeKey == 'light') {
      _theme = lightTheme;
      _themeName = 'light';
    } else {
      _theme = darkTheme;
      _themeName = 'dark';
    }
    notifyListeners();
  }

  void toggleTheme() {
    if (_themeName == 'light') {
      _theme = darkTheme;
      _themeName = 'dark';
    } else {
      _theme = lightTheme;
      _themeName = 'light';
    }
    notifyListeners();
  }
}
