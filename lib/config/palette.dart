import 'package:flutter/material.dart';

@Deprecated('Use Theme.of(context) instead')
class Paletter {
  static const Color darkGray = Color.fromARGB(255, 75, 75, 75);
  static const Color gray = Color(0xFFAAB8C2);
  static const Color lightGray = Color(0xFFE1E8ED);
  static const Color extraLightGray = Color(0xFFF5F8FA);
  static const Color extraDarkGray = Color(0xFF1A1A1A);

  static Color getDarkGray(BuildContext context) => Theme.of(context).colorScheme.surfaceContainerHighest;
  static Color getGray(BuildContext context) => Theme.of(context).colorScheme.inverseSurface;
  static Color getLightGray(BuildContext context) => Theme.of(context).colorScheme.inverseSurface;
  static Color getExtraLightGray(BuildContext context) => Theme.of(context).colorScheme.onSurface;
  static Color getExtraDarkGray(BuildContext context) => Theme.of(context).colorScheme.surface;
}
