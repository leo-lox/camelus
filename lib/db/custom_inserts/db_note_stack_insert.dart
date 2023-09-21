import 'dart:async';
import 'dart:developer';

import 'package:camelus/db/entities/db_note.dart';
import 'package:camelus/models/nostr_note.dart';
import 'package:isar/isar.dart';

class DbNoteStackInsert {
  List<NostrNote> _toInsertNotes = [];
  Timer? _insertNotesTimer;

  Isar db;

  DbNoteStackInsert({required this.db});

  Future stackInsertNotes(List<NostrNote> notes) async {
    // stack insert after 100 notes or 1 seconds
    _toInsertNotes.addAll(notes);

    _toInsertNotes = _toInsertNotes.toSet().toList();

    if (_insertNotesTimer != null) {
      _insertNotesTimer!.cancel();
    }
    _insertNotesTimer = Timer(const Duration(milliseconds: 400), () async {
      var copy = [..._toInsertNotes];
      _toInsertNotes = [];
      await _insertNostrNotes(copy);
      return;
    });

    if (_toInsertNotes.length >= 20) {
      _insertNotesTimer!.cancel();
      var copy = [..._toInsertNotes];
      _toInsertNotes = [];
      await _insertNostrNotes(copy);
      return;
    }
    return;
  }

  Future<void> _insertNostrNotes(List<NostrNote> nostrNotes) async {
    var now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    // database.noteDao.stackInsertNotes([note]);

    List<DbNote> dbNotes = [];
    for (var note in nostrNotes) {
      final myIsarNote = DbNote(
        last_fetch: now,
        nostr_id: note.id,
        created_at: note.created_at,
        kind: note.kind,
        pubkey: note.pubkey,
        content: note.content,
        sig: note.sig,
        tags: note.tags
            .map((e) => DbTag(
                  type: e.type,
                  value: e.value,
                  recommended_relay: e.recommended_relay,
                  marker: e.marker,
                ))
            .toList(),
      );
      dbNotes.add(myIsarNote);
    }

    log('inserting ${dbNotes.length} notes');

    await db.writeTxn(() async {
      try {
        await db.dbNotes.putAllByNostr_id(dbNotes);
      } catch (e) {
        log("error: $e");
      }
    });
  }
}
