import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../config/palette.dart';
import '../../../domain_layer/entities/nostr_note.dart';
import '../../../helpers/helpers.dart';
import '../../providers/metadata_provider.dart';

class InReplyTo extends ConsumerStatefulWidget {
  const InReplyTo({
    super.key,
    required this.myNote,
  });

  final NostrNote myNote;

  @override
  ConsumerState<InReplyTo> createState() => _InReplyToState();
}

class _InReplyToState extends ConsumerState<InReplyTo> {
  String valueFirst = "";
  String pubkeyFirst = "";

  String valueSecond = "";
  String pubkeySecond = "";

  int othersCount = 0;

  void populateValues() {
    final note = widget.myNote;
    final notePubkeys = note.getTagPubkeys;

    // populate
    for (var i = 0; i < notePubkeys.length; i++) {
      var tag = notePubkeys[i];

      if (i == 0) {
        valueFirst = _formatPubkey(tag.value);
        pubkeyFirst = tag.value;
      } else if (i == 1) {
        valueSecond = _formatPubkey(tag.value);
        pubkeySecond = tag.value;
      } else {
        othersCount++;
      }
    }

    setState(() {
      valueFirst = valueFirst;
      valueSecond = valueSecond;
      othersCount = othersCount;
    });
  }

  void resolveMetadata() async {
    final metadata = ref.read(metadataProvider);

    if (pubkeyFirst.isEmpty) return;
    final firstFuture = metadata.getMetadataByPubkey(pubkeyFirst).toList();
    firstFuture.then((value) => {
          if (value.isNotEmpty) {valueFirst = value[0].name ?? valueFirst},
          if (mounted)
            {
              setState(() {
                valueFirst = valueFirst;
              })
            }
        });

    if (pubkeySecond.isEmpty) return;
    final secondFuture = metadata.getMetadataByPubkey(pubkeySecond).toList();
    secondFuture.then((value) => {
          if (value.isNotEmpty) {valueSecond = value[0].name ?? valueSecond},
          if (mounted)
            {
              setState(() {
                valueSecond = valueSecond;
              })
            }
        });
  }

  String _formatPubkey(String pubkey) {
    final pubkeyBech = Helpers().encodeBech32(pubkey, "npub");
    final pubkeyHr =
        "${pubkeyBech.substring(0, 4)}:${pubkeyBech.substring(pubkeyBech.length - 5)}";
    return pubkeyHr;
  }

  @override
  void initState() {
    super.initState();
    populateValues();
    resolveMetadata();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (valueFirst.isEmpty) {
      return const SizedBox();
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
