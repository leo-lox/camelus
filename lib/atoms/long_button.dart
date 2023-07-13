import 'package:camelus/config/palette.dart';
import 'package:flutter/material.dart';

Widget longButton({
  required String name,
  required Function() onPressed,
  bool inverted = false,
  bool disabled = false,
  bool loading = false,
}) {
  return ElevatedButton(
    onPressed: disabled && !loading ? null : onPressed,
    style: ElevatedButton.styleFrom(
      disabledBackgroundColor: Palette.darkGray,
      foregroundColor: inverted ? Palette.black : Palette.lightGray,
      backgroundColor: inverted ? Palette.extraLightGray : Palette.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Palette.white, width: 1),
      ),
    ),
    child: loading
        ? _progress()
        : Text(
            name,
            style: TextStyle(
              color: inverted ? Palette.black : Palette.white,
              fontSize: 18,
            ),
          ),
  );
}

Widget _progress() {
  return const Padding(
    padding: EdgeInsets.only(left: 10, right: 10),
    child: LinearProgressIndicator(
      backgroundColor: Palette.gray,
      color: Palette.black,
    ),
  );
}
