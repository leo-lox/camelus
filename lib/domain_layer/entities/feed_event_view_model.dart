import 'parsed_post.dart';
import 'tree_node.dart';

class FeedEventViewModel {
  ParsedPost? rootNote;
  List<TreeNode<ParsedPost>> comments;
  Set<ParsedPost> unprocessedCommentsSet = {};

  FeedEventViewModel({
    required this.rootNote,
    required this.comments,
    required this.unprocessedCommentsSet,
  });

  FeedEventViewModel copyWith({
    ParsedPost? rootNote,
    List<TreeNode<ParsedPost>>? comments,
    Set<ParsedPost>? unprocessedCommentsSet,
  }) {
    return FeedEventViewModel(
      rootNote: rootNote ?? this.rootNote,
      comments: comments ?? this.comments,
      unprocessedCommentsSet:
          unprocessedCommentsSet ?? this.unprocessedCommentsSet,
    );
  }
}
