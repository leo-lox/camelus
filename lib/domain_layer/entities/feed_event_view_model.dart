import 'nostr_note.dart';
import 'tree_node.dart';

class FeedEventViewModel {
  NostrNote? rootNote;
  List<TreeNode<NostrNote>> comments;

  FeedEventViewModel({
    required this.rootNote,
    required this.comments,
  });

  copyWith({
    NostrNote? rootNote,
    List<TreeNode<NostrNote>>? comments,
  }) {
    return FeedEventViewModel(
      rootNote: rootNote ?? this.rootNote,
      comments: comments ?? this.comments,
    );
  }
}
