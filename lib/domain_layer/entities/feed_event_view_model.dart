import 'nostr_note.dart';
import 'tree_node.dart';

class FeedEventViewModel {
  NostrNote? rootNote;
  List<TreeNode<NostrNote>> comments;
  Set<NostrNote> unprocessedCommentsSet = {};

  FeedEventViewModel({
    required this.rootNote,
    required this.comments,
    required this.unprocessedCommentsSet,
  });

  copyWith({
    NostrNote? rootNote,
    List<TreeNode<NostrNote>>? comments,
    Set<NostrNote>? unprocessedCommentsSet,
  }) {
    return FeedEventViewModel(
      rootNote: rootNote ?? this.rootNote,
      comments: comments ?? this.comments,
      unprocessedCommentsSet:
          unprocessedCommentsSet ?? this.unprocessedCommentsSet,
    );
  }
}
