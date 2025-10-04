import 'package:flutter/material.dart';

class Paletter {
  static const Color background = Color(0xFF000000);
  //static const Color blue = Color(0xFF1DA1F2);
  static const Color primary =
      Color(0xFF1DA1F2); // Color(0xFFf06595); // #f06595  in hex 0xFFf06595
  static const Color purple = Colors.purple;
  static const Color darkGray = Color.fromARGB(255, 75, 75, 75);
  static const Color gray = Color(0xFFAAB8C2);
  static const Color lightGray = Color(0xFFE1E8ED);
  static const Color extraLightGray = Color(0xFFF5F8FA);
  static const Color extraDarkGray = Color(0xFF1A1A1A);
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color warn = Color.fromARGB(255, 252, 127, 3);
  static const Color error = Color.fromARGB(255, 254, 29, 29);
  static const Color likeActive = Color.fromARGB(255, 230, 40, 85);
  static const Color repostActive = Color.fromARGB(255, 22, 163, 74);

  // Theme-aware methods
  static Color getBackground(BuildContext context) => Theme.of(context).colorScheme.surface;
  static Color getPrimary(BuildContext context) => Colors.blue;
  static Color getPurple(BuildContext context) => Colors.purple;
  static Color getDarkGray(BuildContext context) => Theme.of(context).colorScheme.surfaceContainerHighest;
  static Color getGray(BuildContext context) => Theme.of(context).colorScheme.inverseSurface;
  static Color getLightGray(BuildContext context) => Theme.of(context).colorScheme.inverseSurface;
  static Color getExtraLightGray(BuildContext context) => Theme.of(context).colorScheme.onSurface;
  static Color getExtraDarkGray(BuildContext context) => Theme.of(context).colorScheme.surface;
  static Color getWhite(BuildContext context) => Theme.of(context).colorScheme.onSurface;
  static Color getBlack(BuildContext context) => Theme.of(context).colorScheme.surface;
  static Color getWarn(BuildContext context) => Colors.amberAccent;
  static Color getError(BuildContext context) => Theme.of(context).colorScheme.error;
  static Color getLikeActive(BuildContext context) => const Color.fromARGB(255, 230, 40, 85);
  static Color getRepostActive(BuildContext context) => const Color.fromARGB(255, 22, 163, 74);
}
