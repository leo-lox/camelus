import 'package:camelus/config/palette.dart';
import 'package:flutter/material.dart';

class BackButtonRound extends StatelessWidget {
  const BackButtonRound({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(0),
      padding: const EdgeInsets.only(top: 10, right: 0, left: 0),
      child: ButtonTheme(
        minWidth: 10,
        height: 1,
        child: ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black54,
            padding: const EdgeInsets.all(0),
            shape: const CircleBorder(),
          ),
          child: const Icon(
            Icons.arrow_back,
            color: Palette.white,
            size: 20,
          ),
        ),
      ),
    );
  }
}
