import 'dart:ui';

import 'package:camelus/config/palette.dart';
import 'package:camelus/models/tweet.dart';
import 'package:flutter/material.dart';

void openBottomSheetShare(context, Tweet tweet) {
  showModalBottomSheet(
      isScrollControlled: false,
      elevation: 10,
      backgroundColor: Palette.background,
      isDismissible: true,
      enableDrag: true,
      context: context,
      builder: (ctx) => BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
            child: Padding(
                padding: EdgeInsets.only(bottom: 20),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "share post",
                        style: TextStyle(color: Palette.white, fontSize: 30),
                      )
                    ],
                  ),
                )),
          ));
}
