import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../domain_layer/entities/nostr_note.dart';
import '../../../domain_layer/entities/nostr_tag.dart';
import '../../../helpers/helpers.dart';
import '../../routing/route_paths.dart';
import '../../providers/metadata_state_provider.dart';

class InReplyTo extends ConsumerWidget {
  const InReplyTo({super.key, required this.myNote});

  final NostrNote myNote;

  String _formatPubkey(String pubkey) {
    final pubkeyBech = Helpers.encodeBech32(pubkey, "npub");
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
        final myMetadata = ref
            .watch(metadataStateProvider(pubkeyFirst))
            .userMetadata;
        valueFirst = myMetadata?.name ?? _formatPubkey(pubkeyFirst);
      } else if (i == 1) {
        pubkeySecond = tag.value;
        final myMetadata = ref
            .watch(metadataStateProvider(pubkeySecond))
            .userMetadata;
        valueSecond = myMetadata?.name ?? _formatPubkey(pubkeySecond);
      } else {
        othersCount++;
      }
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "reply to ",
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).colorScheme.inverseSurface,
          ),
        ),
        GestureDetector(
          onTap: () {
            context.push(RoutePaths.profile(pubkey: pubkeyFirst));
          },
          child: Text(
            '@$valueFirst ',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 14,
              height: 1.3,
            ),
          ),
        ),
        if (valueSecond.isNotEmpty)
          GestureDetector(
            onTap: () {
              context.push(RoutePaths.profile(pubkey: pubkeySecond));
            },
            child: Text(
              '@$valueSecond ',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 14,
                height: 1.3,
              ),
            ),
          ),
        if (othersCount != 0)
          Text(
            ' and $othersCount more',
            style: TextStyle(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              fontSize: 14,
              height: 1.3,
            ),
          ),
      ],
    );
  }
}
