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

final ThemeData camelusLightTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.blue,
  ),
  scaffoldBackgroundColor: Colors.white,
  drawerTheme: DrawerThemeData(
    backgroundColor: Colors.white,
  ),
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: Colors.white,
  ),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: Colors.blue,
  ),
  dividerTheme: DividerThemeData(
    color: Colors.white,
  ),
  appBarTheme: AppBarThemeData(
    backgroundColor: Colors.white,
  ),
);

final ThemeData camelusDarkTheme = ThemeData(
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

final ThemeData nostrLightTheme = ThemeData(
  colorScheme: ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xff342157),
    surfaceTint: Color(0xff68548e),
    onPrimary: Color(0xffffffff),
    primaryContainer: Color(0xff523f77),
    onPrimaryContainer: Color(0xffffffff),
    secondary: Color(0xff342157),
    onSecondary: Color(0xffffffff),
    secondaryContainer: Color(0xff523f77),
    onSecondaryContainer: Color(0xffffffff),
    tertiary: Color(0xff342157),
    onTertiary: Color(0xffffffff),
    tertiaryContainer: Color(0xff523f77),
    onTertiaryContainer: Color(0xffffffff),
    error: Color(0xff600004),
    onError: Color(0xffffffff),
    errorContainer: Color(0xff98000a),
    onErrorContainer: Color(0xffffffff),
    surface: Color(0xfffef7ff),
    onSurface: Color(0xff000000),
    onSurfaceVariant: Color(0xff000000),
    outline: Color(0xff2e2b33),
    outlineVariant: Color(0xff4c4751),
    shadow: Color(0xff000000),
    scrim: Color(0xff000000),
    inverseSurface: Color(0xff322f35),
    inversePrimary: Color(0xffd3bcfd),
    primaryFixed: Color(0xff523f77),
    onPrimaryFixed: Color(0xffffffff),
    primaryFixedDim: Color(0xff3b285e),
    onPrimaryFixedVariant: Color(0xffffffff),
    secondaryFixed: Color(0xff523f77),
    onSecondaryFixed: Color(0xffffffff),
    secondaryFixedDim: Color(0xff3b285e),
    onSecondaryFixedVariant: Color(0xffffffff),
    tertiaryFixed: Color(0xff523f77),
    onTertiaryFixed: Color(0xffffffff),
    tertiaryFixedDim: Color(0xff3b285e),
    onTertiaryFixedVariant: Color(0xffffffff),
    surfaceDim: Color(0xffbcb7bf),
    surfaceBright: Color(0xfffef7ff),
    surfaceContainerLowest: Color(0xffffffff),
    surfaceContainerLow: Color(0xfff5eff7),
    surfaceContainer: Color(0xffe7e0e8),
    surfaceContainerHigh: Color(0xffd8d2da),
    surfaceContainerHighest: Color(0xffcac4cc),
  ),
);

final ThemeData nostrDarkTheme = ThemeData(
  colorScheme: ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xfff6ecff),
    surfaceTint: Color(0xffd3bcfd),
    onPrimary: Color(0xff000000),
    primaryContainer: Color(0xffcfb8f9),
    onPrimaryContainer: Color(0xff110031),
    secondary: Color(0xfff6ecff),
    onSecondary: Color(0xff000000),
    secondaryContainer: Color(0xffcfb8f9),
    onSecondaryContainer: Color(0xff110031),
    tertiary: Color(0xfff6ecff),
    onTertiary: Color(0xff000000),
    tertiaryContainer: Color(0xffcfb8f9),
    onTertiaryContainer: Color(0xff110031),
    error: Color(0xffffece9),
    onError: Color(0xff000000),
    errorContainer: Color(0xffffaea4),
    onErrorContainer: Color(0xff220001),
    surface: Color(0xff151218),
    onSurface: Color(0xffffffff),
    onSurfaceVariant: Color(0xffffffff),
    outline: Color(0xfff5edf9),
    outlineVariant: Color(0xffc7c0cb),
    shadow: Color(0xff000000),
    scrim: Color(0xff000000),
    inverseSurface: Color(0xffe7e0e8),
    inversePrimary: Color(0xff513e75),
    primaryFixed: Color(0xffebddff),
    onPrimaryFixed: Color(0xff000000),
    primaryFixedDim: Color(0xffd3bcfd),
    onPrimaryFixedVariant: Color(0xff18023b),
    secondaryFixed: Color(0xffebddff),
    onSecondaryFixed: Color(0xff000000),
    secondaryFixedDim: Color(0xffd3bcfd),
    onSecondaryFixedVariant: Color(0xff18023b),
    tertiaryFixed: Color(0xffebddff),
    onTertiaryFixed: Color(0xff000000),
    tertiaryFixedDim: Color(0xffd3bcfd),
    onTertiaryFixedVariant: Color(0xff18023b),
    surfaceDim: Color(0xff151218),
    surfaceBright: Color(0xff524f55),
    surfaceContainerLowest: Color(0xff000000),
    surfaceContainerLow: Color(0xff211f24),
    surfaceContainer: Color(0xff322f35),
    surfaceContainerHigh: Color(0xff3d3a40),
    surfaceContainerHighest: Color(0xff49454c),
  ),
);
