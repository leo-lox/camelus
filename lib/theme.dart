import 'package:flutter/material.dart';

final ThemeData lightTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.blue,
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

final ThemeData darkTheme = ThemeData.from(
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.blue,
    brightness: Brightness.dark,
  ),
);

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
