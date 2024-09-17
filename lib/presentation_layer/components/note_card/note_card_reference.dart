import 'package:camelus/presentation_layer/components/note_card/note_card.dart';
import 'package:camelus/config/palette.dart';
import 'package:camelus/helpers/helpers.dart';
import 'package:camelus/helpers/nevent_helper.dart';
import 'package:camelus/domain_layer/entities/nostr_note.dart';
import 'package:camelus/presentation_layer/providers/get_notes_provider.dart';
import 'package:flutter/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

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
  late Widget body = Container();

  late final String? nostrId;

  _fetchNoteIfUnavailable() async {
    final notesProvider = ref.read(getNotesProvider);
    final result = notesProvider.getNote(nostrId!);
    if (result != null) {
      // note exits in db
      return;
    }
  }

  Widget? _buildBody() {
    //return Text("OKKKKK", style: const TextStyle(color: Palette.primary));

    if (nostrId == null) {
      return null;
    }

    return _myBody(nostrId!);
  }

  String? _getNostrId(String word) {
    final cleanedWord = widget.word.replaceAll("nostr:", "");

    if (cleanedWord.startsWith("note")) {
      final String res;
      try {
        res = Helpers().decodeBech32(cleanedWord)[0];
      } catch (e) {
        return null;
      }
      return res;
    }
    if (cleanedWord.startsWith("nevent")) {
      final String res;
      try {
        final map = NeventHelper().bech32ToMap(cleanedWord);
        res = map["eventId"];
      } catch (e) {
        return null;
      }
      return res;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();

    nostrId = _getNostrId(widget.word);

    _fetchNoteIfUnavailable();
    body = _buildBody() ?? Container();
  }

  @override
  void didUpdateWidget(NoteCardReference oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.word != widget.word) {
      body = _buildBody() ?? Container();
    }
  }

  @override
  Widget build(BuildContext context) {
    return body;
  }

  Column _myBody(String nostrId) {
    final notesProvider = ref.read(getNotesProvider);
    final noteStream = notesProvider.getNote(nostrId);
    return Column(
      children: [
        const SizedBox(height: 20),
        StreamBuilder<NostrNote?>(
          stream: noteStream,
          builder: (context, snapshotStream) {
            if (snapshotStream.hasData) {
              final NostrNote note = snapshotStream.data!;
              final Key key = UniqueKey();
              return GestureDetector(
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
                        myMetadata: null,
                        key: key,
                        hideBottomBar: true,
                      )));
            }
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Palette.darkGray, width: 1.0),
              ),
              child: const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 0, vertical: 20),
                  child: Text("note not found",
                      style: TextStyle(color: Palette.white, fontSize: 17)),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
