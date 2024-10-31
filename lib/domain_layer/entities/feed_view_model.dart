import 'nostr_note.dart';

class FeedViewModel {
  List<NostrNote> timelineNotes;
  List<NostrNote> newNotes;

  FeedViewModel({
    required this.timelineNotes,
    required this.newNotes,
  });

  copyWith({
    List<NostrNote>? timelineNotes,
    List<NostrNote>? newNotes,
  }) {
    return FeedViewModel(
      timelineNotes: timelineNotes ?? this.timelineNotes,
      newNotes: newNotes ?? this.newNotes,
    );
  }
}
