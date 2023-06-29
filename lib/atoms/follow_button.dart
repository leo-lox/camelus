import 'package:camelus/config/palette.dart';
import 'package:flutter/material.dart';

Widget followButton({
  required bool isFollowing,
  required VoidCallback onPressed,
}) {
  if (isFollowing) {
    return Container(
      margin: const EdgeInsets.only(top: 0, right: 10),
      child: ElevatedButton(
        onPressed: () {
          onPressed();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Palette.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Palette.white, width: 1),
          ),
        ),
        child: const Text(
          'Unfollow',
          style: TextStyle(
            color: Palette.white,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
  return Container(
    margin: const EdgeInsets.only(top: 0, right: 10),
    child: ElevatedButton(
      onPressed: () {
        onPressed();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Palette.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Palette.black, width: 1),
        ),
      ),
      child: const Text(
        'Follow',
        style: TextStyle(
          color: Palette.black,
          fontSize: 16,
        ),
      ),
    ),
  );
}
