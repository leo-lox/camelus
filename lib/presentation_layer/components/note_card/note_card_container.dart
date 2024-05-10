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
                  _buildInReplyTo(note, metadata, context, i, widget.notes),

                GestureDetector(
                  onTap: () {
                    _onNoteTab(context, note);
                  },
                  child: Container(
                    //color: Palette.purple,
                    child: NoteCard(note: note),
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

  Row _buildInReplyTo(NostrNote myNote, GetUserMetadata metadata,
      BuildContext context, int index, List<NostrNote> notes) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (index != 0) SizedBox(width: notes.length > 1 ? 70 : 30),
        if (index == 0) const SizedBox(width: 30),
        const Text(
          "reply to ",
          style: TextStyle(fontSize: 16, color: Palette.gray),
        ),
        if (myNote.getTagPubkeys.length < 3)
          ...myNote.getTagPubkeys.map(
            (tag) => linkedUsername(tag.value, metadata, context),
          ),
        if (myNote.getTagPubkeys.length > 2)
          Expanded(
            child: Wrap(
              children: [
                linkedUsername(
                    myNote.getTagPubkeys[0].value, metadata, context),
                linkedUsername(
                    myNote.getTagPubkeys[1].value, metadata, context),
                Text(
                  " and ${myNote.getTagPubkeys.length - 2} ${myNote.getTagPubkeys.length > 3 ? 'others' : 'other'}",
                  style: const TextStyle(fontSize: 16, color: Palette.gray),
                )
              ],
            ),
          ),
      ],
    );
  }
}

Widget linkedUsername(
    String pubkey, GetUserMetadata metadata, BuildContext context) {
  return GestureDetector(
    onTap: () {
      Navigator.pushNamed(context, "/nostr/profile", arguments: pubkey);
    },
    child: StreamBuilder(
      builder: (context, AsyncSnapshot<UserMetadata?> snapshot) {
        var pubkeyBech = Helpers().encodeBech32(pubkey, "npub");
        var pubkeyHr =
            "${pubkeyBech.substring(0, 4)}:${pubkeyBech.substring(pubkeyBech.length - 5)}";
        if (snapshot.hasData) {
          return Text('@${snapshot.data?.name ?? pubkeyHr} ',
              style: const TextStyle(
                  color: Palette.primary, fontSize: 16, height: 1.3));
        } else {
          return Text(pubkeyHr,
              style: const TextStyle(
                  color: Palette.primary, fontSize: 16, height: 1.3));
        }
      },
      stream: metadata.getMetadataByPubkey(pubkey),
    ),
  );
}
