import 'package:flutter/material.dart';

import '../../config/palette.dart';
import '../../domain_layer/entities/nostr_note.dart';
import 'note_card/note_card_container.dart';

class FlattenedComment {
  final NostrNote note;
  final int depth;
  final List<bool> ancestorHasSibling;

  FlattenedComment({
    required this.note,
    required this.depth,
    required this.ancestorHasSibling,
  });
}

// Widget to display a flattened comment
class FlatCommentWidget extends StatelessWidget {
  final FlattenedComment comment;
  final bool isHighlighted;

  const FlatCommentWidget({
    super.key,
    required this.comment,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Depth indicator bars
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          child: DepthIndicator(
            isHighlighted: false,
            depth: comment.depth,
          ),
        ),
        Padding(
          padding: EdgeInsets.only(left: comment.depth * 16.0),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Highlight container if this is the openNoteId
              if (isHighlighted)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Palette.primary.withValues(alpha: 0.65),
                        width: 2.0,
                      ),
                      borderRadius: BorderRadius.circular(10.0),
                      color: Palette.primary.withValues(alpha: 0.05),
                    ),
                  ),
                ),
              // Render the main comment content
              NoteCardContainer(
                key: ValueKey(comment.note.id),
                note: comment.note,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class DepthIndicator extends StatelessWidget {
  final int depth;
  final bool isHighlighted;

  const DepthIndicator({
    super.key,
    required this.depth,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < depth; i++)
          Container(
            width: 1.1,
            height: double.infinity,
            margin: const EdgeInsets.only(left: 10),
            decoration: BoxDecoration(
              color: isHighlighted && i == depth - 1
                  ? Palette.primary
                  : Palette.lightGray
                      .withValues(alpha: _calculateOpacity(i + 1)),
              // borderRadius: BorderRadius.vertical(
              //   top: Radius.circular(25),
              //   bottom: Radius.circular(25),
              // ),
            ),
          )
      ],
    );
  }

  double _calculateOpacity(int lineDepth) {
    // If highlighted and this is the last line, use full opacity
    if (isHighlighted && lineDepth == depth) {
      return 1.0;
    }

    // For normal lines, calculate opacity based on depth
    if (lineDepth >= 12) {
      return 1.0;
    } else {
      return 0.35 + (lineDepth - 1) * (1 / 12);
    }
  }
}
