import 'package:camelus/presentation_layer/components/note_card/note_card.dart';
import 'package:camelus/config/palette.dart';
import 'package:camelus/helpers/helpers.dart';
import 'package:camelus/helpers/nevent_helper.dart';
import 'package:camelus/domain_layer/entities/nostr_note.dart';
import 'package:camelus/presentation_layer/components/note_card/skeleton_note.dart';
import 'package:camelus/presentation_layer/providers/get_notes_provider.dart';
import 'package:camelus/domain_layer/entities/user_metadata.dart';
import 'package:camelus/presentation_layer/providers/metadata_provider.dart';
import 'package:flutter/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:rxdart/rxdart.dart';

final noteAndMetadataProvider =
    FutureProvider.family<(NostrNote, UserMetadata?), String>(
        (ref, nostrId) async {
  final notesProvider = ref.watch(getNotesProvider);
  final metadataP = ref.watch(metadataProvider);

  final noteStream = notesProvider.getNote(nostrId);
  final note = await noteStream.first;

  if (note == null) {
    throw Exception('Note not found');
  }

  final metadataStream = metadataP.getMetadataByPubkey(note.pubkey);
  final metadata = await metadataStream.first;

  return (note, metadata);
});

class NoteCardReference extends ConsumerStatefulWidget {
  final String word;

  const NoteCardReference({
    super.key,
    required this.word,
  });

  @override
  ConsumerState<NoteCardReference> createState() => _NoteCardReferenceState();
}

class _NoteCardReferenceState extends ConsumerState<NoteCardReference> {
  String? nostrId;

  @override
  void initState() {
    super.initState();
    nostrId = _getNostrId(widget.word);
  }

  @override
  void didUpdateWidget(NoteCardReference oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.word != widget.word) {
      nostrId = _getNostrId(widget.word);
    }
  }

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
  Widget build(BuildContext context) {
    if (nostrId == null) {
      return const SizedBox.shrink();
    }

    return Consumer(
      builder: (context, ref, child) {
        final noteAndMetadataAsync =
            ref.watch(noteAndMetadataProvider(nostrId!));

        return noteAndMetadataAsync.when(
          loading: () => const Center(child: SkeletonNote()),
          error: (error, stack) => Container(
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
          ),
          data: (data) {
            final (note, metadata) = data;
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
