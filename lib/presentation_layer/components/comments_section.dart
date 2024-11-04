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

    bool isRepliesExpanded = repliesExpanded[node.value.id] ?? false;

    if (node.children.length < 2) {
      setState(() {
        repliesExpanded[node.value.id] = true;
        isRepliesExpanded = true;
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            // for (int i = 0; i < depth; i++)
            //   if (ancestorHasSibling[i])
            //     Positioned(
            //       left: 13.0 * i,
            //       top: 0,
            //       bottom: 0,
            //       child: Container(
            //         width: 2.0,
            //         height: 60,
            //         color: Palette.purple,
            //       ),
            //     ),

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
                      bottom: 40,
                      child: Container(
                        width: 2.0,
                        color: lineColor,
                      ),
                    ),

                  /// paint the gap that expand button is leaving
                  if (node.hasChildren && node.children.length == 1)
                    Positioned(
                      left: 10.0,
                      top: 60,
                      bottom: 0,
                      child: Container(
                        width: 2.0,
                        color: lineColor,
                      ),
                    ),

                  if (node.hasChildren && isRepliesExpanded)
                    Positioned(
                      left: 10.0,
                      bottom: 0,
                      child: Container(
                        width: 2.0,
                        height: 22,
                        color: lineColor,
                      ),
                    ),

                  NoteCardContainer(
                    key: ValueKey(node.value.id),
                    note: node.value,
                  ),

                  /// on only one child its expaded already
                  if (node.hasChildren && node.children.length > 1)
                    // expand replies
                    Positioned(
                      left: 0.0,
                      //top: 60,
                      bottom: 20,
                      child: GestureDetector(
                        onTap: () {
                          print("expand replies");
                          setState(() {
                            repliesExpanded[node.value.id] =
                                !(repliesExpanded[node.value.id] ?? false);
                            isRepliesExpanded =
                                repliesExpanded[node.value.id] ?? false;
                          });
                        },
                        child: Container(
                          //padding: const EdgeInsets.all(4.0),

                          child: isRepliesExpanded
                              ? Icon(
                                  Icons.remove_circle_outline,
                                  color: Palette.gray,
                                  size: 22.0,
                                )
                              : Icon(
                                  Icons.add_circle_outline,
                                  color: Palette.gray,
                                  size: 22.0,
                                ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        if (isRepliesExpanded)
          ...node.children.map((child) => _buildCommentTree(
                child,
                depth + 1,
                childAncestorHasSibling,
              )),
      ],
    );
  }
}
