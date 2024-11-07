import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../config/palette.dart';
import '../../../domain_layer/entities/nostr_note.dart';
import '../../../domain_layer/entities/nostr_tag.dart';
import '../../../domain_layer/entities/user_metadata.dart';
import '../../providers/metadata_provider.dart';
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
  UserMetadata? myUserNoteMetadata;

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

  Future<UserMetadata?> _getMetadata(String pubkey) async {
    final mProvider = ref.read(metadataProvider);

    final myMetadata = await mProvider.getMetadataByPubkey(pubkey).toList();

    if (myMetadata.isEmpty) {
      return null;
    }

    return myMetadata[0];
  }

  @override
  void initState() {
    super.initState();
    _getMetadata(widget.note.pubkey).then((data) {
      if (mounted) {
        setState(() {
          myUserNoteMetadata = data;
        });
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              myMetadata: myUserNoteMetadata,
              key: ValueKey('note-${note.id}'),
            ),
          ],
        ),
      ),
    );
  }
}
