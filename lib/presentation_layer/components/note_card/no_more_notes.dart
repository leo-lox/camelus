import 'package:flutter/material.dart';
import '../../../config/palette.dart';

class NoMoreNotes extends StatelessWidget {
  final Function? renderCallback;

  final String text;

  const NoMoreNotes({
    super.key,
    this.renderCallback,
    this.text = "No more notes to show",
  });

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
        const SizedBox(height: 20),
        Center(
          child: Text(
            text,
            style: TextStyle(
              color: Palette.darkGray,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(height: 50),
      ],
    );
  }
}
