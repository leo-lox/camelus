import 'nostr_note.dart';

class FeedViewModel {
  List<NostrNote> timelineRootNotes;
  List<NostrNote> newRootNotes;

  List<NostrNote> timelineRootAndReplyNotes;
  List<NostrNote> newRootAndReplyNotes;

  FeedViewModel({
    required this.timelineRootNotes,
    required this.newRootNotes,
    required this.timelineRootAndReplyNotes,
    required this.newRootAndReplyNotes,
  });

  copyWith({
    List<NostrNote>? timelineRootNotes,
    List<NostrNote>? newRootNotes,
    List<NostrNote>? timelineRootAndReplyNotes,
    List<NostrNote>? newRootAndReplyNotes,
  }) {
    return FeedViewModel(
      timelineRootNotes: timelineRootNotes ?? this.timelineRootNotes,
      newRootNotes: newRootNotes ?? this.newRootNotes,
      timelineRootAndReplyNotes:
          timelineRootAndReplyNotes ?? this.timelineRootAndReplyNotes,
      newRootAndReplyNotes: newRootAndReplyNotes ?? this.newRootAndReplyNotes,
    );
  }
}
