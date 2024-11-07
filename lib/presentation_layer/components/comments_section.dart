import 'package:flutter/material.dart';
import 'package:camelus/config/palette.dart';
import 'package:camelus/domain_layer/entities/nostr_note.dart';
import 'package:camelus/domain_layer/entities/tree_node.dart';
import 'package:camelus/presentation_layer/components/note_card/note_card_container.dart';
import 'package:camelus/presentation_layer/atoms/rounded_corner_painer.dart';

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

class CommentTreeItem extends StatefulWidget {
  final TreeNode<NostrNote> node;
  final int depth;
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
  bool isExpanded = false;

  @override
  void initState() {
    super.initState();
    isExpanded = widget.node.children.length < 2;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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

class CommentCard extends StatelessWidget {
  final TreeNode<NostrNote> node;
  final int depth;
  final List<bool> ancestorHasSibling;
  final bool isExpanded;
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
              NoteCardContainer(
                key: ValueKey(node.value.id),
                note: node.value,
              ),
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
