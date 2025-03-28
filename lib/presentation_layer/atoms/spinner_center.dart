import 'package:camelus/config/palette.dart';
import 'package:flutter/material.dart';

class SpinnerCenter extends StatelessWidget {
  const SpinnerCenter({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        color: Palette.white,
      ),
    );
  }
}
