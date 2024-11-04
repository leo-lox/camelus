import 'package:camelus/config/palette.dart';
import 'package:camelus/domain_layer/entities/user_metadata.dart';
import 'package:camelus/presentation_layer/components/note_card/note_card_container.dart';
import 'package:flutter/material.dart';

import '../../domain_layer/entities/nostr_note.dart';
import '../../domain_layer/entities/tree_node.dart';
import '../atoms/rounded_corner_painer.dart';
import 'note_card/note_card.dart';

class CommentSection extends StatefulWidget {
  final TreeNode<NostrNote> commentTree;

  const CommentSection({super.key, required this.commentTree});

  @override
  State<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends State<CommentSection> {
  final repliesExpanded = <String, bool>{};

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: _buildCommentTree(widget.commentTree, 0, []),
    );
  }

  Widget _buildCommentTree(
    TreeNode<NostrNote> node,
    int depth,
    List<bool> ancestorHasSibling,
  ) {
    final Color lineColor = Palette.darkGray;

    List<bool> childAncestorHasSibling = List.from(ancestorHasSibling);
    childAncestorHasSibling.add(node.hasSiblings);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            // for loop
            for (int i = 0; i < depth; i++)
              if (ancestorHasSibling[i])
                Positioned(
                  left: 1.0 * i,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 2.0,
                    height: 60,
                    color: Palette.purple,
                  ),
                ),

            Padding(
              padding: EdgeInsets.only(left: depth * 16.0),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Rounded corner connecting horizontal and vertical lines
                  if (node.hasParent)
                    Positioned(
                      left: -15.0,
                      top: 0.0,
                      child: Column(
                        children: [
                          Container(
                            width: 2.0,
                            height: 60.0,
                            color: lineColor,
                          ),
                          Padding(
                            padding: EdgeInsets.only(left: 10.0),
                            child: CustomPaint(
                              size: Size(10.0, 10.0),
                              painter: RoundedCornerPainter(
                                color: lineColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (node.hasChildren)
                    Positioned(
                      left: 10.0,
                      top: 60,
                      bottom: 0,
                      child: Container(
                        width: 2.0,
                        height: 60,
                        color: lineColor,
                      ),
                    ),

                  NoteCardContainer(
                    key: ValueKey(node.value.id),
                    note: node.value,
                  ),
                  if (node.hasChildren)
                    // expand replies
                    Positioned(
                      left: 0.0,
                      //top: 60,
                      bottom: 20,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            repliesExpanded[node.value.id] =
                                !(repliesExpanded[node.value.id] ?? false);
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4.0),
                          decoration: BoxDecoration(
                            color: Palette.purple,
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                          child: Text(
                            repliesExpanded[node.value.id] ?? false
                                ? "Collapse"
                                : "Expand",
                            style: TextStyle(
                              color: Palette.white,
                              fontSize: 12.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        if (repliesExpanded[node.value.id] ?? false)
          ...node.children.map((child) => _buildCommentTree(
                child,
                depth + 1,
                childAncestorHasSibling,
              )),
      ],
    );
  }
}
