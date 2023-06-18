import 'package:camelus/components/note_card/note_card.dart';
import 'package:camelus/config/palette.dart';
import 'package:camelus/helpers/helpers.dart';
import 'package:camelus/models/nostr_note.dart';
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
                          NoteCard(note: myNote),
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
        if (snapshot.hasData) {
          return Text('@${snapshot.data?['name'] ?? "unknown"} ',
              style: const TextStyle(
                  color: Palette.primary, fontSize: 17, height: 1.3));
        } else {
          var pubkeyBech = Helpers().encodeBech32(pubkey, "npub");
          var pubkeyHr =
              "${pubkeyBech.substring(0, 5)}...${pubkeyBech.substring(pubkeyBech.length - 5)}";
          return Text(pubkeyHr,
              style: const TextStyle(
                  color: Palette.primary, fontSize: 17, height: 1.3));
        }
      },
      future: nostrService.getUserMetadata(pubkey),
    ),
  );
}
