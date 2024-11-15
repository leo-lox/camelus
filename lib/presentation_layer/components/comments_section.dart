import 'package:flutter/material.dart'; 
import 'package:camelus/config/palette.dart';
import 'package:camelus/domain_layer/entities/nostr_note.dart';
import 'package:camelus/domain_layer/entities/tree_node.dart';
import 'package:camelus/presentation_layer/components/note_card/note_card_container.dart';
import 'package:camelus/presentation_layer/atoms/rounded_corner_painer.dart';

/// A widget representing a section of comments 
class CommentSection extends StatelessWidget {
  final TreeNode<NostrNote> comment;

  const CommentSection({
    super.key,
    required this.comment,
  });

  @override
  Widget build(BuildContext context) {
    return CommentTreeItem(
      node: comment,
      depth: 0,
      ancestorHasSibling: [false],
    );
  }
}

/// A widget that represents an individual comment 
class CommentTreeItem extends StatefulWidget {
  /// The current comment node.
  final TreeNode<NostrNote> node;

  /// The depth of the current comment in the tree structure.
  final int depth;

  /// A list indicating if ancestor nodes have siblings.
  final List<bool> ancestorHasSibling;

  const CommentTreeItem({
    super.key,
    required this.node,
    required this.depth,
    required this.ancestorHasSibling,
  });

  @override
  CommentTreeItemState createState() => CommentTreeItemState();
}

class CommentTreeItemState extends State<CommentTreeItem> {
  /// Tracks whether the current comment's children are expanded.
  bool isExpanded = false;

  @override
  void initState() {
    super.initState();
    // Automatically expand nodes with fewer than 2 children.
    isExpanded = widget.node.children.length < 2;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Render the comment card for the current node.
        CommentCard(
          node: widget.node,
          depth: widget.depth,
          ancestorHasSibling: widget.ancestorHasSibling,
          isExpanded: isExpanded,
          onToggleExpand: () {
            setState(() {
              isExpanded = !isExpanded;
            });
          },
        ),
        if (isExpanded)
          ...widget.node.children.map((child) => CommentTreeItem(
                node: child,
                depth: widget.depth + 1,
                ancestorHasSibling: [
                  ...widget.ancestorHasSibling,
                  widget.node.hasSiblings
                ],
              )),
      ],
    );
  }
}

/// A widget representing a single comment card, including its visual elements.
class CommentCard extends StatelessWidget {
  /// The current comment node.
  final TreeNode<NostrNote> node;

  /// The depth of the current comment in the tree.
  final int depth;

  /// A list indicating if ancestor nodes have siblings.
  final List<bool> ancestorHasSibling;


  final bool isExpanded;

  /// Callback to toggle the expansion state of the current comment.
  final VoidCallback onToggleExpand;

  const CommentCard({
    super.key,
    required this.node,
    required this.depth,
    required this.ancestorHasSibling,
    required this.isExpanded,
    required this.onToggleExpand,
  });

  @override
  Widget build(BuildContext context) {
    final Color lineColor = Palette.darkGray;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Padding(
          padding: EdgeInsets.only(left: depth * 16.0),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Draw lines to indicate the parent-child relationship.
              if (node.hasParent)
                Positioned(
                  left: -15.0,
                  top: 0.0,
                  child: Column(
                    children: [
                      // Vertical line connecting to the parent.
                      Container(
                        width: 2.0,
                        height: 60.0,
                        color: lineColor,
                      ),
                      // Rounded corner at the connection point.
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
              // Vertical line for child comments.
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
              // Adjusted vertical line for nodes with a single child.
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
              // Short vertical line for expanded nodes.
              if (node.hasChildren && isExpanded)
                Positioned(
                  left: 10.0,
                  bottom: 0,
                  child: Container(
                    width: 2.0,
                    height: 22,
                    color: lineColor,
                  ),
                ),
              // Render the main comment content.
              NoteCardContainer(
                key: ValueKey(node.value.id),
                note: node.value,
              ),
              // Render an expandable icon for nodes with multiple children.
              if (node.hasChildren && node.children.length > 1)
                Positioned(
                  left: -14.0,
                  bottom: 20,
                  child: SizedBox(
                    width: 50.0,
                    height: 50.0,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(50.0),
                      onTap: onToggleExpand,
                      child: Container(
                        child: isExpanded
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
                ),
            ],
          ),
        ),
      ],
    );
  }
}
