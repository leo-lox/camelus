import 'package:flutter/material.dart';

class NoMoreNotes extends StatelessWidget {
  final Function? renderCallback;

  final String text;

  const NoMoreNotes({
    super.key,
    this.renderCallback,
    this.text = "No more notes to show", // TODO translate
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
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(height: 50),
      ],
    );
  }
}
