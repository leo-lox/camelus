import 'package:camelus/config/palette.dart';
import 'package:flutter/material.dart';

Widget followButton({
  required bool isFollowing,
  required VoidCallback onPressed,
}) {
  if (isFollowing) {
    return Container(
      margin: const EdgeInsets.only(top: 0, right: 10),
      child: Builder(
        builder: (context) {
          return ElevatedButton(
            onPressed: () {
              onPressed();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Paletter.getBlack(context),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: Paletter.getWhite(context), width: 1),
              ),
            ),
            child: Text(
              'unfollow',
              style: TextStyle(
                color: Paletter.getWhite(context),
                fontSize: 16,
              ),
            ),
          );
        }
      ),
    );
  }
  return Container(
    margin: const EdgeInsets.only(top: 0, right: 10),
    child: Builder(
      builder: (context) {
        return ElevatedButton(
          onPressed: () {
            onPressed();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Paletter.getWhite(context),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: Paletter.getBlack(context), width: 1),
            ),
          ),
          child: Text(
            'follow',
            style: TextStyle(
              color: Paletter.getBlack(context),
              fontSize: 16,
            ),
          ),
        );
      }
    ),
  );
}
