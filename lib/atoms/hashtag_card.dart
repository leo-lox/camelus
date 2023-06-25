import 'dart:developer';

import 'package:camelus/config/palette.dart';
import 'package:flutter/material.dart';

class HashtagCard extends StatelessWidget {
  final int index;
  final String hashtag;
  final int threadsCount;

  const HashtagCard({
    required this.index,
    required this.hashtag,
    required this.threadsCount,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        log("hashtag tapped");
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "${index + 1}. ",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: BorderSide.strokeAlignCenter,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  hashtag,
                  style: const TextStyle(
                    height: BorderSide.strokeAlignCenter,
                    letterSpacing: 1,
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                const SizedBox(width: 25),
                Text(
                  threadsCount.toString(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Palette.gray,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  "threads",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Palette.gray,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
