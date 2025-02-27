import '../../../domain_layer/entities/nostr_note.dart';
import '../../../domain_layer/entities/tree_node.dart';

class RepliesTree {
  /// build a tree from the replies \
  /// [returns] a list of first level replies \
  /// the cildren are replies of replies
  static List<TreeNode<NostrNote>> buildRepliesTree({
    required String rootNoteId,
    required List<NostrNote> replies,
  }) {
    final List<NostrNote> workingList = List.from(replies, growable: true);
    workingList.sort((a, b) => a.created_at.compareTo(b.created_at));
    final List<TreeNode<NostrNote>> tree = [];

    // find top level replies
    for (var i = 0; i < workingList.length; i++) {
      final reply = workingList[i];

      if (reply.getDirectReply?.value == rootNoteId) {
        tree.add(TreeNode<NostrNote>(reply));
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
    required List<NostrNote> workingList,
    required TreeNode<NostrNote> parent,
  }) {
    for (var i = 0; i < workingList.length; i++) {
      final reply = workingList[i];

      if (reply.getDirectReply?.value == parent.value.id) {
        final child = TreeNode<NostrNote>(reply);
        parent.addChild(child);
        workingList.remove(reply);
        i--; // Adjust index after removal
        _buildSubtree(workingList: workingList, parent: child);
      }
    }
  }
}
