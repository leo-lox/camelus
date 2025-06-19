import '../../../domain_layer/entities/parsed_post.dart';
import '../../../domain_layer/entities/tree_node.dart';

class RepliesTree {
  /// build a tree from the replies \
  /// [returns] a list of first level replies \
  /// the cildren are replies of replies
  static List<TreeNode<ParsedPost>> buildRepliesTree({
    required String rootNoteId,
    required List<ParsedPost> replies,
  }) {
    final List<ParsedPost> workingList = List.from(replies, growable: true);
    workingList.sort((a, b) => a.created_at.compareTo(b.created_at));
    final List<TreeNode<ParsedPost>> tree = [];

    // find top level replies
    for (var i = 0; i < workingList.length; i++) {
      final reply = workingList[i];

      if (reply.nostrNote.getDirectReply?.value == rootNoteId) {
        tree.add(TreeNode<ParsedPost>(reply));
        workingList.remove(reply);
        i--; // Adjust index after removal
      }
    }

    // build the tree
    for (final node in tree) {
      _buildSubtree(workingList: workingList, parent: node);
    }

    return tree;
  }

  /// recursive function to build the tree
  ///
  static _buildSubtree({
    required List<ParsedPost> workingList,
    required TreeNode<ParsedPost> parent,
  }) {
    for (var i = 0; i < workingList.length; i++) {
      final reply = workingList[i];

      if (reply.nostrNote.getDirectReply?.value == parent.value.id) {
        final child = TreeNode<ParsedPost>(reply);
        parent.addChild(child);
        workingList.remove(reply);
        i--; // Adjust index after removal
        _buildSubtree(workingList: workingList, parent: child);
      }
    }
  }
}
