import 'package:camelus/config/palette.dart';
import 'package:flutter/material.dart';

Widget newPostsAvailable({required String name, required Function onPressed}) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceAround,
    children: [
      Container(
        width: 120,
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Palette.primary,
        ),
        child: TextButton(
          onPressed: () {
            onPressed();
          },
          child: Text(
            name,
            style: const TextStyle(color: Palette.white),
          ),
        ),
      )
    ],
  );
}
