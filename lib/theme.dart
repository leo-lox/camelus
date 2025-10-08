import 'package:flutter/material.dart';

ThemeData buildLightTheme(Color seedColor) {
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: seedColor,
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return Colors.black;
        }
        return Colors.transparent;
      }),
    ),
  );
}

ThemeData buildDarkTheme(Color seedColor) {
  return ThemeData.from(
    colorScheme: ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
    ),
  );
}

// Legacy themes (kept for backwards compatibility)
final ThemeData lightTheme = buildLightTheme(Colors.blue);
final ThemeData darkTheme = buildDarkTheme(Colors.blue);

final ThemeData camelusTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.blue,
    brightness: Brightness.dark,
  ),
  scaffoldBackgroundColor: Colors.black,
  drawerTheme: DrawerThemeData(
    backgroundColor: Colors.black,
  ),
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: Colors.black,
  ),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: Colors.blue,
  ),
  dividerTheme: DividerThemeData(
    color: Colors.black,
  ),
  appBarTheme: AppBarThemeData(
    backgroundColor: Colors.black,
  ),
);
