import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      "camelus",
      style: TextStyle(
        letterSpacing: 1.2,
        color: Theme.of(context).colorScheme.inverseSurface,
        fontSize: 20,
        fontWeight: FontWeight.normal,
        fontFamily: "Poppins",
      ),
    );
  }
}
