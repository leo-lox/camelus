import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain_layer/entities/nostr_note.dart';
import '../../../domain_layer/entities/nostr_tag.dart';
import '../../providers/metadata_state_provider.dart';
import 'in_reply_to.dart';
import 'note_card.dart';

/// this is a container for the note cards
/// its purpose is to wrap a note with additional information, like reply to

class NoteCardContainer extends ConsumerStatefulWidget {
  final NostrNote note;

  const NoteCardContainer({super.key, required this.note});

  @override
  ConsumerState<NoteCardContainer> createState() => _NoteCardContainerState();
}

class _NoteCardContainerState extends ConsumerState<NoteCardContainer> {
  void _onNoteTab(BuildContext context, NostrNote myNote) {
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

  void _navigateToEventViewPage(
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
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final myMetadataState =
        ref.watch(metadataStateProvider(widget.note.pubkey));

    final note = widget.note;
    return GestureDetector(
      onTap: () {
        _onNoteTab(context, note);
      },
      child: Container(
        color: Colors
            .transparent, // needed for comment lines and tab still working
        child: Column(
          children: [
            // check if reply
            if (note.getTagEvents.isNotEmpty)
              // for myNote.getTagPubkeys
              Padding(
                padding: const EdgeInsets.only(left: 15.0),
                child: InReplyTo(
                  key: ValueKey('in-reply-to-${note.id}'),
                  myNote: note,
                ),
              ),
            NoteCard(
              note: note,
              myMetadata: myMetadataState.userMetadata,
              key: ValueKey('note-${note.id}'),
            ),
          ],
        ),
      ),
    );
  }
}
