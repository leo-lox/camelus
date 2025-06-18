import 'nostr_note.dart';
import 'parsed_post.dart';

class FeedViewModel {
  List<ParsedPost> timelineRootNotes;
  List<ParsedPost> newRootNotes;

  /// if true then no more root notes are available
  bool endOfRootNotes;

  List<ParsedPost> timelineRootAndReplyNotes;
  List<ParsedPost> newRootAndReplyNotes;

  bool endOfRootAndReplyNotes;

  FeedViewModel({
    required this.timelineRootNotes,
    required this.newRootNotes,
    required this.timelineRootAndReplyNotes,
    required this.newRootAndReplyNotes,
    this.endOfRootNotes = false,
    this.endOfRootAndReplyNotes = false,
  });

  copyWith({
    List<ParsedPost>? timelineRootNotes,
    List<ParsedPost>? newRootNotes,
    List<ParsedPost>? timelineRootAndReplyNotes,
    List<ParsedPost>? newRootAndReplyNotes,
    bool? endOfRootNotes,
    bool? endOfRootAndReplyNotes,
  }) {
    return FeedViewModel(
      timelineRootNotes: timelineRootNotes ?? this.timelineRootNotes,
      newRootNotes: newRootNotes ?? this.newRootNotes,
      endOfRootNotes: endOfRootNotes ?? this.endOfRootNotes,
      timelineRootAndReplyNotes:
          timelineRootAndReplyNotes ?? this.timelineRootAndReplyNotes,
      newRootAndReplyNotes: newRootAndReplyNotes ?? this.newRootAndReplyNotes,
      endOfRootAndReplyNotes:
          endOfRootAndReplyNotes ?? this.endOfRootAndReplyNotes,
    );
  }
}
