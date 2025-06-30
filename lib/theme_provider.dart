import 'package:flutter/material.dart';
import 'themes.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeData _currentTheme;
  String _currentThemeName;

  ThemeProvider(this._currentTheme)
      : _currentThemeName = 'light'; // default theme name

  ThemeData get currentTheme => _currentTheme;
  String get currentThemeName => _currentThemeName;

  void setTheme(String themeName) {
  if (themeName == 'light') {
    _currentTheme = lightTheme;
  } else if (themeName == 'dark') {
    _currentTheme = darkTheme;
  } else if (themeName == 'pink') {
    _currentTheme = pinkTheme;
  } else if (themeName == 'blue') {
    _currentTheme = blueTheme;
  } else if (themeName == 'green') {
    _currentTheme = greenTheme;
  }
  _currentThemeName = themeName;
  notifyListeners();
}

}
