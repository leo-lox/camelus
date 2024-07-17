import 'package:camelus/domain_layer/entities/user_metadata.dart';
import 'package:camelus/domain_layer/usecases/get_user_metadata.dart';
import 'package:camelus/presentation_layer/components/note_card/note_card.dart';
import 'package:camelus/config/palette.dart';
import 'package:camelus/helpers/helpers.dart';
import 'package:camelus/domain_layer/entities/nostr_note.dart';
import 'package:camelus/domain_layer/entities/nostr_tag.dart';
import 'package:camelus/presentation_layer/providers/metadata_provider.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'in_reply_to.dart';

/// this is a container for the note cards
/// its purpose is to hold connected notes (mostly replies) and paint connections between them
/// it also handles the logic on what to show => button to show more replies, etc

class NoteCardContainer extends ConsumerStatefulWidget {
  final List<NostrNote> notes;
  final List<NoteCardContainer> otherContainers;

  const NoteCardContainer(
      {super.key, required this.notes, this.otherContainers = const []});

  @override
  ConsumerState<NoteCardContainer> createState() => _NoteCardContainerState();
}

class _NoteCardContainerState extends ConsumerState<NoteCardContainer> {
  List<Widget> myWidgets = [];
  List<Widget> combinedWidgets = [];

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
      BuildContext context, String root, String? scrollIntoView) {
    Navigator.pushNamed(context, "/nostr/event", arguments: <String, String?>{
      "root": root,
      "scrollIntoView": scrollIntoView
    });
  }

  @override
  void initState() {
    super.initState();
    myWidgets = _buildContainerNotes(ref.read(metadataProvider), context);
    combinedWidgets = [...myWidgets, ...widget.otherContainers];
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void didUpdateWidget(NoteCardContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.notes != widget.notes) {
      setState(() {
        myWidgets = _buildContainerNotes(ref.read(metadataProvider), context);
        combinedWidgets = [...myWidgets, ...widget.otherContainers];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Container(
        color: Palette.background,
        child: ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: combinedWidgets.length,
          itemBuilder: (context, index) => combinedWidgets[index],
        ),
      ),
    );
  }

  List<Widget> _buildContainerNotes(
      GetUserMetadata metadata, BuildContext context) {
    List<Widget> widgets = [];
    for (int i = 0; i < widget.notes.length; i++) {
      var note = widget.notes[i];
      widgets.add(Stack(
        children: [
          // vertical line top
          if (i != 0)
            Positioned(
              left: 40,
              top: 0,
              height: 50,
              child: Container(
                width: 2,
                color: Palette.darkGray,
              ),
            ),
          // vertical line bottom
          if (i != widget.notes.length - 1)
            Positioned(
              left: 40,
              bottom: 0,
              // top - 50
              top: 50,
              child: Container(
                width: 2,
                color: Palette.darkGray,
              ),
            ),
          Container(
            padding: const EdgeInsets.only(top: 10),
            child: Column(
              children: [
                // check if reply
                if (note.getTagEvents.isNotEmpty)
                  // for myNote.getTagPubkeys
                  InReplyTo(
                    key: ValueKey('in-reply-to-${note.id}'),
                    myNote: note,
                    metadata: metadata,
                  ),

                GestureDetector(
                  onTap: () {
                    _onNoteTab(context, note);
                  },
                  child: NoteCard(
                    note: note,
                    myMetadata: null,
                    key: ValueKey('note-${note.id}'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ));
    }
    return widgets;
  }
}
