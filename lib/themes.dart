import 'package:flutter/material.dart';

final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  primarySwatch: Colors.deepOrange,
  colorScheme: const ColorScheme.light(
    primary: Colors.deepOrange,
    secondary: Colors.teal,
  ),
  scaffoldBackgroundColor: Colors.white,
);

final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  primarySwatch: Colors.deepOrange,
  colorScheme: const ColorScheme.dark(
    primary: Colors.deepOrange,
    secondary: Colors.tealAccent,
  ),
  scaffoldBackgroundColor: Color(0xFF121212),
);

