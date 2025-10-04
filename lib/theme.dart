import 'package:flutter/material.dart';

final ThemeData lightTheme = ThemeData.from(
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.blue,
  ),
);

final ThemeData darkTheme = ThemeData.from(
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.blue,
    brightness: Brightness.dark,
  ),
);
