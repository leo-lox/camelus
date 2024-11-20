import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/palette.dart';
import '../../../domain_layer/entities/nostr_note.dart';
import '../../../domain_layer/entities/nostr_tag.dart';
import '../../../helpers/helpers.dart';
import '../../providers/metadata_provider.dart';
import '../../providers/metadata_state_provider.dart';

class InReplyTo extends ConsumerWidget {
  const InReplyTo({
    super.key,
    required this.myNote,
  });

  final NostrNote myNote;

  String _formatPubkey(String pubkey) {
    final pubkeyBech = Helpers().encodeBech32(pubkey, "npub");
    final pubkeyHr =
        "${pubkeyBech.substring(0, 4)}:${pubkeyBech.substring(pubkeyBech.length - 5)}";
    return pubkeyHr;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    List<NostrTag> notePubkeys = myNote.getTagPubkeys;

    // filter out root pubkey reference
    notePubkeys.removeWhere((element) => element.marker == 'root');

    if (notePubkeys.isEmpty) {
      return const SizedBox();
    }

    String valueFirst = "";
    String pubkeyFirst = "";
    String valueSecond = "";
    String pubkeySecond = "";
    int othersCount = 0;

    // populate
    for (var i = 0; i < notePubkeys.length; i++) {
      var tag = notePubkeys[i];

      if (i == 0) {
        pubkeyFirst = tag.value;
        final myMetadata =
            ref.watch(metadataStateProvider(pubkeyFirst)).userMetadata;
        valueFirst = myMetadata?.name ?? _formatPubkey(pubkeyFirst);
      } else if (i == 1) {
        pubkeySecond = tag.value;
        final myMetadata =
            ref.watch(metadataStateProvider(pubkeySecond)).userMetadata;
        valueSecond = myMetadata?.name ?? _formatPubkey(pubkeySecond);
      } else {
        othersCount++;
      }
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "reply to ",
          style: TextStyle(fontSize: 16, color: Palette.gray),
        ),
        GestureDetector(
          onTap: () {
            Navigator.pushNamed(context, "/nostr/profile",
                arguments: pubkeyFirst);
          },
          child: Text('@$valueFirst ',
              style: const TextStyle(
                  color: Palette.primary, fontSize: 16, height: 1.3)),
        ),
        if (valueSecond.isNotEmpty)
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, "/nostr/profile",
                  arguments: pubkeySecond);
            },
            child: Text('@$valueSecond ',
                style: const TextStyle(
                    color: Palette.primary, fontSize: 16, height: 1.3)),
          ),
        if (othersCount != 0)
          Text(' and $othersCount more',
              style: const TextStyle(
                  color: Palette.darkGray, fontSize: 16, height: 1.3))
      ],
    );
  }
}
