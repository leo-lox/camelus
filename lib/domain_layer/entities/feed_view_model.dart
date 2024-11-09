import 'nostr_note.dart';

class FeedViewModel {
  List<NostrNote> timelineRootNotes;
  List<NostrNote> newRootNotes;

  /// if true then no more root notes are available
  bool endOfRootNotes;

  List<NostrNote> timelineRootAndReplyNotes;
  List<NostrNote> newRootAndReplyNotes;

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
    List<NostrNote>? timelineRootNotes,
    List<NostrNote>? newRootNotes,
    List<NostrNote>? timelineRootAndReplyNotes,
    List<NostrNote>? newRootAndReplyNotes,
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
