import 'package:camelus/l10n/app_localizations.dart';
import 'package:camelus/presentation_layer/components/note_card/note_card.dart';
import 'package:camelus/helpers/helpers.dart';
import 'package:camelus/helpers/nevent_helper.dart';
import 'package:camelus/presentation_layer/components/note_card/skeleton_note.dart';
import 'package:camelus/presentation_layer/routing/route_paths.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/embed_note_cache_provider.dart';
import '../../providers/metadata_state_provider.dart';

/// embed, inline post
class NoteCardReference extends ConsumerWidget {
  final String word;

  const NoteCardReference({super.key, required this.word});

  String? _getNostrId(String word) {
    final cleanedWord = word.replaceAll("nostr:", "");

    if (cleanedWord.startsWith("note")) {
      try {
        return Helpers().decodeBech32(cleanedWord)[0];
      } catch (e) {
        return null;
      }
    }
    if (cleanedWord.startsWith("nevent")) {
      try {
        final map = NeventHelper().bech32ToMap(cleanedWord);
        return map["eventId"];
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nostrId = _getNostrId(word);

    if (nostrId == null) {
      return const SizedBox.shrink();
    }

    final embeddedPostAsync = ref.watch(embeddedParsedPostProvider(nostrId));

    return embeddedPostAsync.when(
      data: (parsedNote) => parsedNote != null
          ? Consumer(
              builder: (context, ref, child) {
                final metadata = ref
                    .watch(metadataStateProvider(parsedNote.pubkey))
                    .userMetadata;

                return Column(
                  children: [
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: () {
                        context.push(
                          RoutePaths.status(
                            pubkey: parsedNote.pubkey,
                            eventId: parsedNote.id,
                            scrollIntoView: parsedNote.id,
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                            width: 1.0,
                          ),
                        ),
                        child: NoteCard(
                          note: parsedNote,
                          myMetadata: metadata,
                          key: ValueKey(parsedNote.id),
                          hideBottomBar: true,
                        ),
                      ),
                    ),
                  ],
                );
              },
            )
          : const SizedBox.shrink(),
      loading: () => const Center(child: SkeletonNote(hideBottomAction: true)),
      error: (err, stack) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            width: 1.0,
          ),
        ),
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 0, vertical: 20),
            child: Text(
              " ${AppLocalizations.of(context)!.noteNotFound} $err",
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 17,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
