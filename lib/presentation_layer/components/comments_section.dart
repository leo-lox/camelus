import 'package:flutter/material.dart';
import 'package:camelus/config/palette.dart';
import 'package:camelus/domain_layer/entities/nostr_note.dart';
import 'package:camelus/domain_layer/entities/tree_node.dart';
import 'package:camelus/presentation_layer/components/note_card/note_card_container.dart';
import 'package:camelus/presentation_layer/atoms/rounded_corner_painer.dart';

/// A widget representing a section of comments
class CommentSection extends StatelessWidget {
  final TreeNode<NostrNote> comment;
  final String? openNoteId;

  const CommentSection({
    super.key,
    required this.comment,
    this.openNoteId,
  });

  @override
  Widget build(BuildContext context) {
    return CommentTreeItem(
      node: comment,
      depth: 0,
      ancestorHasSibling: [false],
      openNoteId: openNoteId,
    );
  }
}

class CommentTreeItem extends StatefulWidget {
  final TreeNode<NostrNote> node;
  final int depth;
  final List<bool> ancestorHasSibling;
  final String? openNoteId;

  const CommentTreeItem({
    super.key,
    required this.node,
    required this.depth,
    required this.ancestorHasSibling,
    this.openNoteId,
  });

  @override
  CommentTreeItemState createState() => CommentTreeItemState();
}

class CommentTreeItemState extends State<CommentTreeItem> {
  bool isExpanded = false;

  @override
  void initState() {
    super.initState();
    // Automatically expand nodes with fewer than 2 children
    isExpanded = widget.node.children.length < 2;

    if (widget.openNoteId != null) {
      if (widget.node.value.id == widget.openNoteId) {
        isExpanded = true;
      } else {
        // Check if any child contains the openNoteId
        _checkChildrenForOpenNote(widget.node);
      }
    }
  }

  // Recursively check if any child contains the openNoteId
  bool _checkChildrenForOpenNote(TreeNode<NostrNote> node) {
    for (final child in node.children) {
      if (child.value.id == widget.openNoteId) {
        isExpanded = true;
        return true;
      }
      if (_checkChildrenForOpenNote(child)) {
        isExpanded = true;
        return true;
      }
    }
    return false;
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
          isHighlighted: widget.node.value.id == widget.openNoteId,
          onToggleExpand: () {
            setState(() {
              isExpanded = !isExpanded;
            });
          },
        ),
        if (isExpanded)
          ...widget.node.children.asMap().entries.map((entry) {
            final index = entry.key;
            final child = entry.value;
            final isLastChild = index == widget.node.children.length - 1;

            return CommentTreeItem(
              node: child,
              depth: widget.depth + 1,
              ancestorHasSibling: [
                ...widget.ancestorHasSibling,
                !isLastChild, // Only show the line if it's not the last child
              ],
            );
          }),
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
  final bool isHighlighted;

  const CommentCard({
    super.key,
    required this.node,
    required this.depth,
    required this.ancestorHasSibling,
    required this.isExpanded,
    required this.onToggleExpand,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color lineColor = Palette.darkGray;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Reddit-style depth indicator bars
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          child: DepthIndicator(
            isHighlighted: isHighlighted,
            depth: depth,
            ancestorHasSibling: ancestorHasSibling,
          ),
        ),
        Padding(
          padding: EdgeInsets.only(left: depth * 16.0),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Highlight container if this is the openNoteId
              if (isHighlighted)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Palette.primary.withOpacity(0.7),
                        width: 2.0,
                      ),
                      borderRadius: BorderRadius.circular(8.0),
                      color: Palette.primary.withOpacity(0.1),
                    ),
                    // margin: const EdgeInsets.all(-4.0),
                  ),
                ),
              // Render the main comment content
              NoteCardContainer(
                key: ValueKey(node.value.id),
                note: node.value,
              ),
              // Expandable icon for nodes with multiple children
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

class DepthIndicator extends StatelessWidget {
  final int depth;
  final List<bool> ancestorHasSibling;
  final bool isHighlighted;

  const DepthIndicator({
    super.key,
    required this.depth,
    required this.ancestorHasSibling,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < depth; i++)
          if (true || i < ancestorHasSibling.length && ancestorHasSibling[i])
            Container(
              width: 2.0,
              height: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 7.0),
              color: isHighlighted && i == depth - 1
                  ? Palette.primary
                  : Palette.gray,
            )
          else
            SizedBox(width: 16.0),
      ],
    );
  }
}
