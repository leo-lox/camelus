import 'package:camelus/config/palette.dart';
import 'package:flutter/material.dart';

Widget longButton({required String name, required Function() onPressed}) {
  return ElevatedButton(
    onPressed: onPressed,
    style: ElevatedButton.styleFrom(
      backgroundColor: Palette.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Palette.white, width: 1),
      ),
    ),
    child: Text(
      name,
      style: const TextStyle(
        color: Palette.white,
        fontSize: 18,
      ),
    ),
  );
}
