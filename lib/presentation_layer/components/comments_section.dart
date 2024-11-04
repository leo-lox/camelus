import 'package:camelus/config/palette.dart';
import 'package:camelus/domain_layer/entities/user_metadata.dart';
import 'package:camelus/presentation_layer/components/note_card/note_card_container.dart';
import 'package:flutter/material.dart';

import '../../domain_layer/entities/nostr_note.dart';
import '../../domain_layer/entities/tree_node.dart';
import '../atoms/rounded_corner_painer.dart';
import 'note_card/note_card.dart';

class CommentSection extends StatelessWidget {
  final TreeNode<NostrNote> commentTree;

  const CommentSection({super.key, required this.commentTree});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: _buildCommentTree(commentTree, 0),
    );
  }

  Widget _buildCommentTree(TreeNode<NostrNote> node, int depth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: depth * 36.0),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Rounded corner connecting horizontal and vertical lines
              if (node.hasParent)
                Positioned(
                  left: -25.0,
                  top: 0.0,
                  child: Column(
                    children: [
                      Container(
                        width: 2.0,
                        height: 60.0,
                        color: Palette.gray,
                      ),
                      Padding(
                        padding: EdgeInsets.only(left: 15.0),
                        child: CustomPaint(
                          size: Size(15.0, 15.0),
                          painter: RoundedCornerPainter(
                            color: Palette.gray,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              if (node.hasChildren)
                Positioned(
                  left: 25.0,
                  top: 50,
                  bottom: 0,
                  child: Container(
                    width: 2.0,
                    height: 120,
                    color: Palette.gray,
                  ),
                ),

              NoteCardContainer(
                key: ValueKey(node.value.id),
                note: node.value,
              ),
            ],
          ),
        ),
        ...node.children.map((child) => _buildCommentTree(child, depth + 1)),
      ],
    );
  }
}
