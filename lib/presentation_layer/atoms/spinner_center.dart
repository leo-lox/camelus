import 'package:camelus/config/palette.dart';
import 'package:flutter/material.dart';

class SpinnerCenter extends StatelessWidget {
  const SpinnerCenter({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(
        color: Paletter.getWhite(context),
      ),
    );
  }
}
