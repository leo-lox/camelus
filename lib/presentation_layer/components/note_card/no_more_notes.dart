import 'package:camelus/presentation_layer/components/note_card/bottom_action_row.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../config/palette.dart';

class NoMoreNotes extends StatelessWidget {
  final Function? renderCallback;

  const NoMoreNotes({super.key, this.renderCallback});

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
        // horizontal line
        const Divider(
          color: Palette.darkGray,
          thickness: 1,
        ),
        const SizedBox(height: 10),
        Center(
          child: Text(
            "No more notes to show",
            style: TextStyle(
              color: Palette.darkGray,
              fontSize: 16,
            ),
          ),
        )
      ],
    );
  }
}
