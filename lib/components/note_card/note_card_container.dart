import 'package:camelus/components/note_card/note_card.dart';
import 'package:camelus/models/nostr_note.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// this is a container for the note cards
/// its purpose is to hold connected notes (mostly replies) and paint connections between them
/// it also handles the logic on what to show => button to show more replies, etc

class NoteCardContainer extends ConsumerStatefulWidget {
  final List<NostrNote> notes;
  final List<NoteCardContainer> otherContainers;

  const NoteCardContainer(
      {Key? key, required this.notes, this.otherContainers = const []})
      : super(key: key);

  @override
  ConsumerState<NoteCardContainer> createState() => _NoteCardContainerState();
}

class _NoteCardContainerState extends ConsumerState<NoteCardContainer> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        children: [
          ...widget.notes.map((e) => NoteCard(note: e)).toList(),
          ...widget.otherContainers.map((e) => e).toList()
        ],
      ),
    );
  }
}
