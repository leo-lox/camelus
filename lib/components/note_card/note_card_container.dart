import 'dart:developer';
import 'dart:ffi';

import 'package:camelus/components/note_card/note_card.dart';
import 'package:camelus/config/palette.dart';
import 'package:camelus/helpers/helpers.dart';
import 'package:camelus/models/nostr_note.dart';
import 'package:camelus/models/nostr_tag.dart';
import 'package:camelus/providers/nostr_service_provider.dart';
import 'package:camelus/services/nostr/nostr_service.dart';
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
  void _onNoteTab(NostrNote myNote) {
    var refEvents = myNote.getTagEvents;

    // try to find root note
    NostrTag? rootNote;
    NostrTag? replyNote;

    for (NostrTag tag in refEvents) {
      if (tag.marker == "root") {
        rootNote = tag;
      }
      if (tag.marker == "reply") {
        replyNote = tag;
      }
    }
    // in spec
    if (rootNote != null || replyNote != null) {
      log("is reply");
      // off spec support, sometimes not marked as root
      var root = rootNote?.value;
      root ??= refEvents.first.value;

      _navigateToEventViewPage(root, replyNote?.value ?? myNote.id);
      return;
    }

    // support off spec
    if (refEvents.length == 1) {
      log("is reply");
      _navigateToEventViewPage(refEvents[0].value, myNote.id);
      return;
    }

    // support off spec
    if (refEvents.length > 1) {
      log("is reply");
      var root = refEvents.first;
      var reply = refEvents.last;
      _navigateToEventViewPage(root.value, reply.value);
      return;
    }

    if (rootNote == null) {
      log("is root");
      _navigateToEventViewPage(myNote.id, null);
      return;
    }
  }

  _navigateToEventViewPage(String root, String? scrollIntoView) {
    Navigator.pushNamed(context, "/nostr/event", arguments: <String, String?>{
      "root": root,
      "scrollIntoView": scrollIntoView
    });
  }

  @override
  Widget build(BuildContext context) {
    final _nostrService = ref.read(nostrServiceProvider);

    return SizedBox(
      width: double.infinity,
      child: Container(
        color: Palette.background,
        child: Column(
          children: [
            ...widget.notes
                .map((myNote) => Container(
                      padding: const EdgeInsets.only(top: 10),
                      child: Column(
                        children: [
                          // check if reply
                          if (myNote.getTagEvents.isNotEmpty)
                            // for myNote.getTagPubkeys
                            Row(
                              children: [
                                const SizedBox(width: 25),
                                const Text(
                                  "in reply to ",
                                  style: TextStyle(
                                      fontSize: 16, color: Palette.gray),
                                ),
                                if (myNote.getTagPubkeys.length < 3)
                                  ...myNote.getTagPubkeys
                                      .map(
                                        (tag) => linkedUsername(
                                            tag.value, _nostrService, context),
                                      )
                                      .toList(),
                                if (myNote.getTagPubkeys.length > 2)
                                  Row(
                                    children: [
                                      linkedUsername(
                                          myNote.getTagPubkeys[0].value,
                                          _nostrService,
                                          context),
                                      linkedUsername(
                                          myNote.getTagPubkeys[1].value,
                                          _nostrService,
                                          context),
                                      Text(
                                        "and ${myNote.getTagPubkeys.length - 2} ${myNote.getTagPubkeys.length > 3 ? 'others' : 'other'}",
                                        style: const TextStyle(
                                            fontSize: 16, color: Palette.gray),
                                      )
                                    ],
                                  ),
                              ],
                            ),

                          GestureDetector(
                            onTap: () {
                              _onNoteTab(myNote);
                            },
                            child: Container(
                              color: Palette.background,
                              child: NoteCard(note: myNote),
                            ),
                          ),
                        ],
                      ),
                    ))
                .toList(),
            ...widget.otherContainers.map((e) => e).toList()
          ],
        ),
      ),
    );
  }
}

Widget linkedUsername(
    String pubkey, NostrService nostrService, BuildContext context) {
  return GestureDetector(
    onTap: () {
      Navigator.pushNamed(context, "/nostr/profile", arguments: pubkey);
    },
    child: FutureBuilder(
      builder: (context, AsyncSnapshot<Map> snapshot) {
        var pubkeyBech = Helpers().encodeBech32(pubkey, "npub");
        var pubkeyHr =
            "${pubkeyBech.substring(0, 5)}...${pubkeyBech.substring(pubkeyBech.length - 5)}";
        if (snapshot.hasData) {
          return Text('@${snapshot.data?['name'] ?? pubkeyHr} ',
              style: const TextStyle(
                  color: Palette.primary, fontSize: 17, height: 1.3));
        } else {
          return Text(pubkeyHr,
              style: const TextStyle(
                  color: Palette.primary, fontSize: 17, height: 1.3));
        }
      },
      future: nostrService.getUserMetadata(pubkey),
    ),
  );
}
