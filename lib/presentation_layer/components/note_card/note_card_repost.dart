import 'package:camelus/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';

import '../../../domain_layer/entities/nostr_note.dart';
import '../../../domain_layer/entities/nostr_tag.dart';
import '../../../helpers/helpers.dart';
import '../../providers/get_notes_provider.dart';
import '../../providers/metadata_state_provider.dart';
import '../../providers/parsed_note_cache_provider.dart';
import '../../routing/route_paths.dart';
import 'note_card_container.dart';
import 'skeleton_note.dart';

class NoteCardRepost extends ConsumerStatefulWidget {
  final NostrNote repostEvent;

  const NoteCardRepost({super.key, required this.repostEvent});

  @override
  ConsumerState<NoteCardRepost> createState() => _NoteCardRepostState();
}

class _NoteCardRepostState extends ConsumerState<NoteCardRepost> {
  NostrTag? _noteEtag;
  Stream<NostrNote>? _displayNoteStream;

  @override
  void initState() {
    super.initState();
    _initNoteStream();
  }

  @override
  void didUpdateWidget(covariant NoteCardRepost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repostEvent.id != widget.repostEvent.id) {
      _initNoteStream();
    }
  }

  void _initNoteStream() {
    _noteEtag = widget.repostEvent.tags.cast<NostrTag?>().firstWhere(
      (element) => element?.type == 'e',
      orElse: () => null,
    );

    if (_noteEtag == null) {
      _displayNoteStream = null;
      return;
    }

    final notesP = ref.read(getNotesProvider);
    _displayNoteStream = notesP.getNote(
      _noteEtag!.value,
      explicitRelays: _noteEtag!.recommendedRelay != null
          ? [_noteEtag!.recommendedRelay!]
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final repostedByMetadata = ref.watch(
      metadataStateProvider(
        widget.repostEvent.pubkey,
      ).select((state) => state.userMetadata),
    );

    if (_noteEtag == null || _displayNoteStream == null) {
      return Text(AppLocalizations.of(context)!.repostHasNoInformation);
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              SvgPicture.asset(
                'assets/icons/retweet.svg',
                height: 18,
                colorFilter: const ColorFilter.mode(
                  Color.fromARGB(255, 22, 163, 74),
                  BlendMode.srcATop,
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () {
                  context.push(
                    RoutePaths.profile(pubkey: widget.repostEvent.pubkey),
                  );
                },
                child: RichText(
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.inverseSurface,
                    ),
                    children: [
                      TextSpan(
                        text:
                            repostedByMetadata?.name ??
                            Helpers().shortHr(widget.repostEvent.pubkey),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      TextSpan(
                        text: AppLocalizations.of(context)!.shared,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        StreamBuilder<NostrNote>(
          stream: _displayNoteStream,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Column(
                children: [
                  if (_noteEtag!.recommendedRelay == null)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Text(
                            'loading might fail, the repost has no information where to fetch the post',
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'This is a bug, please report it to the developers',
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'repostId: ${widget.repostEvent.id} ${widget.repostEvent.sources}',
                            style: TextStyle(
                              fontSize: 10,
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SkeletonNote(hideBottomAction: true),
                ],
              );
            }

            final parsedRepostAsync = ref.watch(
              parsedNoteCacheProvider(snapshot.data!),
            );
            return parsedRepostAsync.when(
              data: (parsedNote) {
                if (parsedNote == null) {
                  return const SizedBox.shrink();
                }

                return NoteCardContainer(
                  key: PageStorageKey(parsedNote.id),
                  note: parsedNote,
                );
              },
              loading: () => const SkeletonNote(hideBottomAction: true),
              error: (_, _) => const SizedBox.shrink(),
            );
          },
        ),
      ],
    );
  }
}
