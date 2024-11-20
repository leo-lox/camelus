import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain_layer/entities/nostr_note.dart';
import '../../../domain_layer/entities/nostr_tag.dart';
import '../../providers/metadata_state_provider.dart';
import 'in_reply_to.dart';
import 'note_card.dart';

class NoteCardContainer extends ConsumerWidget {
  final NostrNote note;

  const NoteCardContainer({super.key, required this.note});

  static void _onNoteTab(BuildContext context, NostrNote myNote) {
    var refEvents = myNote.getTagEvents;

    if (myNote.isRoot) {
      _navigateToEventViewPage(context, myNote.id, null);
      return;
    }

    NostrTag? root = myNote.getRootReply;
    NostrTag? reply = myNote.getDirectReply;

    // off spec support, sometimes not marked as root
    root ??= refEvents.first;

    _navigateToEventViewPage(context, root.value, reply?.value ?? myNote.id);
  }

  static void _navigateToEventViewPage(
    BuildContext context,
    String root,
    String? scrollIntoView,
  ) {
    Navigator.pushNamed(context, "/nostr/event", arguments: <String, String?>{
      "root": root,
      "scrollIntoView": scrollIntoView
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myMetadata =
        ref.watch(metadataStateProvider(note.pubkey)).userMetadata;

    return GestureDetector(
      onTap: () => _onNoteTab(context, note),
      child: Container(
        color: Colors.transparent,
        child: Column(
          children: [
            if (note.getTagEvents.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 15.0),
                child: InReplyTo(
                  key: ValueKey('in-reply-to-${note.id}'),
                  myNote: note,
                ),
              ),
            NoteCard(
              note: note,
              myMetadata: myMetadata,
              key: ValueKey('note-${note.id}'),
            ),
          ],
        ),
      ),
    );
  }
}
