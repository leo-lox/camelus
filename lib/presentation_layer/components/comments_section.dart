import 'package:camelus/domain_layer/entities/user_metadata.dart';
import 'package:flutter/material.dart';

import '../../domain_layer/entities/nostr_note.dart';
import '../../domain_layer/entities/tree_node.dart';
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
          padding: EdgeInsets.only(left: depth * 16.0),
          child: NoteCard(
            note: node.value,
            myMetadata: UserMetadata(
                eventId: "eventId", pubkey: "pubkey", lastFetch: 0),
          ),
        ),
        ...node.children.map((child) => _buildCommentTree(child, depth + 1)),
      ],
    );
  }
}

/// use this as a widget
class CommentTreeBuilder extends StatefulWidget {
  final TreeNode<NostrNote> initialCommentTree;

  const CommentTreeBuilder({Key? key, required this.initialCommentTree})
      : super(key: key);

  @override
  _CommentTreeBuilderState createState() => _CommentTreeBuilderState();
}

class _CommentTreeBuilderState extends State<CommentTreeBuilder> {
  late TreeNode<NostrNote> commentTree;

  @override
  void initState() {
    super.initState();
    commentTree = widget.initialCommentTree;
  }

  void _addReply(TreeNode<NostrNote> parentNode, NostrNote reply) {
    setState(() {
      parentNode.addChild(TreeNode(reply));
    });
  }

  @override
  Widget build(BuildContext context) {
    return CommentSection(
      commentTree: commentTree,
      // onReply: (TreeNode<NostrNote> parentNode) {
      //   // Show a dialog or navigate to a new screen to get the reply content
      //   // For simplicity, we'll just add a dummy reply here
      //   _addReply(parentNode, NostrNote(content: "This is a reply"));
      // },
    );
  }
}
