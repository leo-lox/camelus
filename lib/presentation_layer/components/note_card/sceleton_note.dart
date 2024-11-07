import 'package:camelus/presentation_layer/components/note_card/bottom_action_row.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../config/palette.dart';

class SkeletonNote extends StatelessWidget {
  final Function? renderCallback;

  const SkeletonNote({super.key, this.renderCallback});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // This code will run after the widget has been rendered
      if (renderCallback != null) {
        renderCallback!();
      }
    });

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // profile picture
              Shimmer.fromColors(
                baseColor: Palette.extraDarkGray,
                highlightColor: Palette.darkGray,
                child: Container(
                  height: 60,
                  width: 60,
                  decoration: const BoxDecoration(
                    color: Palette.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person),
                ),
              ),
              Container(
                width: MediaQuery.of(context).size.width - 95,
                margin: const EdgeInsets.only(left: 5, right: 10),
                color: Palette.background,
                child: Padding(
                  padding: const EdgeInsets.only(left: 10.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // username
                      Shimmer.fromColors(
                        baseColor: Palette.extraDarkGray,
                        highlightColor: Palette.darkGray,
                        child: Container(
                          height: 18,
                          width: 120,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      Shimmer.fromColors(
                        baseColor: Palette.extraDarkGray,
                        highlightColor: Palette.darkGray,
                        child: Container(
                          height: 12,
                          width: MediaQuery.of(context).size.width / 2.5,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Shimmer.fromColors(
                        baseColor: Palette.extraDarkGray,
                        highlightColor: Palette.darkGray,
                        child: Container(
                          height: 12,
                          width: 50,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),

                      const SizedBox(height: 6),

                      Padding(
                        padding: const EdgeInsets.only(top: 10.0),
                        child: BottomActionRow(
                          onComment: () {},
                          onLike: () {},
                          onRetweet: () {},
                          onShare: () {},
                        ),
                      ),
                      const SizedBox(height: 20),
                      // show text if replies > 0
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
