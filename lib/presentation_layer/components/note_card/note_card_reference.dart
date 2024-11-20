import 'package:camelus/presentation_layer/components/note_card/note_card.dart';
import 'package:camelus/config/palette.dart';
import 'package:camelus/helpers/helpers.dart';
import 'package:camelus/helpers/nevent_helper.dart';
import 'package:camelus/domain_layer/entities/nostr_note.dart';
import 'package:camelus/presentation_layer/components/note_card/skeleton_note.dart';
import 'package:camelus/presentation_layer/providers/get_notes_provider.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/metadata_state_provider.dart';

/// embed, inline post
class NoteCardReference extends ConsumerWidget {
  final String word;

  const NoteCardReference({
    super.key,
    required this.word,
  });

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

    final notesProvider = ref.watch(getNotesProvider);

    return FutureBuilder<NostrNote?>(
      future: notesProvider.getNote(nostrId).first,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: SkeletonNote(hideBottomAction: true),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Palette.darkGray, width: 1.0),
            ),
            child: const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 0, vertical: 20),
                child: Text(
                  "Note not found",
                  style: TextStyle(color: Palette.white, fontSize: 17),
                ),
              ),
            ),
          );
        }

        final note = snapshot.data!;

        return Consumer(
          builder: (context, ref, child) {
            final metadata =
                ref.watch(metadataStateProvider(note.pubkey)).userMetadata;

            return Column(
              children: [
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, "/nostr/event", arguments: {
                      "root": note.id,
                      "scrollIntoView": note.id,
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Palette.darkGray, width: 1.0),
                    ),
                    child: NoteCard(
                      note: note,
                      myMetadata: metadata,
                      key: ValueKey(note.id),
                      hideBottomBar: true,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
