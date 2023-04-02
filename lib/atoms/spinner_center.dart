import 'package:camelus/config/palette.dart';
import 'package:flutter/material.dart';

Widget spinnerCenter() {
  return const Center(
    child: CircularProgressIndicator(
      color: Palette.white,
    ),
  );
}
