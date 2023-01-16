import 'package:flutter/material.dart';

final Map<String, ThemeData> themeMap = {
  "LIGHT": lightTheme,
  "DARK": darkTheme
};

final ThemeData darkTheme = ThemeData(
  primaryColor: Colors.white70,
  backgroundColor: Colors.black,
);

final ThemeData lightTheme = ThemeData(
  primaryColor: Colors.black,
  backgroundColor: Colors.white,
);

const TextStyle smallTextStyle =
    TextStyle(color: Colors.white, fontSize: 10.0, letterSpacing: 0.09);

const TextStyle warningStyle = TextStyle(color: Colors.red, fontSize: 16.0);
