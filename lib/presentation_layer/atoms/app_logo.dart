import 'package:flutter/material.dart';

import '../../config/palette.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      "camelus",
      style: TextStyle(
        letterSpacing: 1.2,
        color: Paletter.getLightGray(context),
        fontSize: 20,
        fontWeight: FontWeight.normal,
        fontFamily: "Poppins",
      ),
    );
  }
}
