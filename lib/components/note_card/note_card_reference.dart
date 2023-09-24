import 'package:camelus/components/note_card/note_card.dart';
import 'package:camelus/config/palette.dart';
import 'package:camelus/db/entities/db_note.dart';
import 'package:camelus/db/queries/db_note_queries.dart';
import 'package:camelus/helpers/helpers.dart';
import 'package:camelus/models/nostr_note.dart';
import 'package:camelus/providers/database_provider.dart';
import 'package:flutter/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:isar/isar.dart';

class NoteCardReference extends ConsumerWidget {
  const NoteCardReference({
    super.key,
    required this.word,
  });

  final String word;

  @override
  Widget build(BuildContext context, ref) {
    final dbFuture = ref.watch(databaseProvider.future);

    //return Text("OKKKKK", style: const TextStyle(color: Palette.primary));
    final cleanedWord = word.replaceAll("nostr:", "");
    final String nostrId;
    try {
      nostrId = Helpers().decodeBech32(cleanedWord)[0];
    } catch (e) {
      return const Text("Error decoding note ref");
    }

    return Column(
      children: [
        const SizedBox(height: 20),
        FutureBuilder(
            future: dbFuture,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final db = snapshot.data as Isar;
                final noteStream =
                    DbNoteQueries.findNotebyIdStream(db, id: nostrId);

                return StreamBuilder<List<DbNote?>>(
                    stream: noteStream,
                    builder: ((context, snapshotStream) {
                      if (snapshotStream.hasData &&
                          snapshotStream.data!.isNotEmpty) {
                        final NostrNote note =
                            snapshotStream.data![0]!.toNostrNote();
                        final Key key = UniqueKey();
                        return GestureDetector(
                            onTap: () {
                              Navigator.pushNamed(context, "/nostr/event",
                                  arguments: {
                                    "root": note.id,
                                    "scrollIntoView": note.id,
                                  });
                            },
                            child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: Palette.darkGray, width: 1.0),
                                ),
                                child: NoteCard(
                                  note: note,
                                  key: key,
                                  hideBottomBar: true,
                                )));
                      }
                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border:
                              Border.all(color: Palette.darkGray, width: 1.0),
                        ),
                        child: const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 0, vertical: 20),
                            child: Text("note not found",
                                style: TextStyle(
                                    color: Palette.white, fontSize: 17)),
                          ),
                        ),
                      );
                    }));
              }
              return const Text("database not ready",
                  style: TextStyle(color: Palette.white, fontSize: 20));
            }),
      ],
    );
  }
}
