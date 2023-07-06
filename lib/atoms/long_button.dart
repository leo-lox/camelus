import 'package:camelus/config/palette.dart';
import 'package:flutter/material.dart';

Widget longButton({
  required String name,
  required Function() onPressed,
  bool inverted = false,
  bool disabled = false,
}) {
  return ElevatedButton(
    onPressed: disabled ? null : onPressed,
    style: ElevatedButton.styleFrom(
      disabledBackgroundColor: Palette.darkGray,
      foregroundColor: inverted ? Palette.black : Palette.lightGray,
      backgroundColor: inverted ? Palette.extraLightGray : Palette.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Palette.white, width: 1),
      ),
    ),
    child: Text(
      name,
      style: TextStyle(
        color: inverted ? Palette.black : Palette.white,
        fontSize: 18,
      ),
    ),
  );
}
