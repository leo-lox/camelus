import 'package:camelus/presentation_layer/providers/get_notes_provider.dart';
import 'package:camelus/presentation_layer/providers/metadata_state_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';

import '../../../config/palette.dart';
import '../../../domain_layer/entities/nostr_note.dart';
import '../../../domain_layer/entities/nostr_tag.dart';
import '../../../helpers/helpers.dart';
import 'note_card_container.dart';
import 'skeleton_note.dart';

class NoteCardRepost extends ConsumerWidget {
  final NostrNote repostEvent;

  const NoteCardRepost({
    super.key,
    required this.repostEvent,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesP = ref.read(getNotesProvider);
    final repostedByMetadata =
        ref.watch(metadataStateProvider(repostEvent.pubkey)).userMetadata;

    final noteEtag = repostEvent.tags.cast<NostrTag?>().firstWhere(
          (element) => element?.type == 'e',
          orElse: () => null,
        );

    if (noteEtag == null) {
      return Text("Repost has no information where to fetch the post");
    }

    final displayNoteStream = notesP.getNote(
      noteEtag.value,
      explicitRelays: noteEtag.recommended_relay != null
          ? [noteEtag.recommended_relay!]
          : null,
    );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              SvgPicture.asset(
                'assets/icons/retweet.svg',
                height: 18,
                colorFilter: ColorFilter.mode(
                  Palette.repostActive,
                  BlendMode.srcATop,
                ),
              ),
              SizedBox(width: 10),
              GestureDetector(
                onTap: () {
                  // navigate to the profile of the user who reposted

                  Navigator.pushNamed(context, "/nostr/profile",
                      arguments: repostEvent.pubkey);
                },
                child: RichText(
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    style: TextStyle(color: Palette.gray),
                    children: [
                      TextSpan(
                        text: repostedByMetadata?.name ??
                            Helpers().shortHr(repostEvent.pubkey),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      TextSpan(
                        text: ' shared',
                        style: TextStyle(
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        StreamBuilder(
          stream: displayNoteStream,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Column(
                children: [
                  if (noteEtag.recommended_relay == null)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(
                              "loading might fail, the repost has no information where to fetch the post"),
                          SizedBox(height: 10),
                          Text(
                              "This is a bug, please report it to the developers"),
                          SizedBox(height: 10),
                          Text(
                            "repostId: ${repostEvent.id} ${repostEvent.sources}",
                            style: TextStyle(
                              fontSize: 10,
                              color: Palette.darkGray,
                            ),
                          ),
                        ],
                      ),
                    ),
                  SkeletonNote(hideBottomAction: true),
                ],
              );
            }

            return NoteCardContainer(
              key: PageStorageKey(repostEvent.id),
              note: snapshot.data!,
            );
          },
        ),
      ],
    );
  }
}
