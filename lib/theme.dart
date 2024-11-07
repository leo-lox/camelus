import 'package:flutter/material.dart';

final Map<String, ThemeData> themeMap = {
  "LIGHT": lightTheme,
  "DARK": darkTheme
};

final ThemeData darkTheme = ThemeData(
  primaryColor: Colors.white70,
  colorScheme: const ColorScheme(
    background: Colors.black,
    brightness: Brightness.dark,
    error: Colors.red,
    onBackground: Colors.black,
    onError: Colors.orange,
    onPrimary: Colors.blue,
    onSecondary: Colors.blueAccent,
    onSurface: Colors.white,
    primary: Colors.blue,
    secondary: Colors.blueAccent,
    surface: Colors.white12,
  ),
);

final ThemeData lightTheme = ThemeData(
  primaryColor: Colors.black,
  colorScheme: const ColorScheme(
    background: Colors.white,
    brightness: Brightness.light,
    error: Colors.red,
    onBackground: Colors.white,
    onError: Colors.orange,
    onPrimary: Colors.blue,
    onSecondary: Colors.blueAccent,
    onSurface: Colors.teal,
    primary: Colors.blue,
    secondary: Colors.blueAccent,
    surface: Colors.teal,
  ),
);

const TextStyle smallTextStyle =
    TextStyle(color: Colors.white, fontSize: 10.0, letterSpacing: 0.09);

const TextStyle warningStyle = TextStyle(color: Colors.red, fontSize: 16.0);
