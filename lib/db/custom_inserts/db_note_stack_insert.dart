import 'dart:async';
import 'dart:developer';

import 'package:camelus/db/entities/db_note.dart';
import 'package:camelus/db/queries/db_note_queries.dart';
import 'package:camelus/helpers/bip340.dart';
import 'package:camelus/models/nostr_note.dart';
import 'package:hex/hex.dart';
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

    List<int> res = [];
    await db.writeTxn(() async {
      try {
        res = await db.dbNotes.putAllByNostr_id(dbNotes);
        log('inserted ${res.length} notes');
      } catch (e) {
        log("error: $e");
      }
    });
    _checkForUnverifiedNotes(res);
  }

  _checkForUnverifiedNotes(List<int> noteDbIds) async {
    final insertedNotes =
        await DbNoteQueries.findNotesByDbIdsFuture(db, dbIds: noteDbIds);

    for (var note in insertedNotes) {
      if (note.sig_valid == null) {
        verifyNote(note);
      }
    }
  }

  final Bip340 _bip340 = Bip340();
  verifyNote(DbNote note) async {
    bool valid = false;
    try {
      valid = _bip340.verify(
        note.nostr_id,
        note.sig,
        note.pubkey,
      );
    } catch (e) {
      log("error: $e");
    }

    // update note
    await db.writeTxn(() async {
      db.dbNotes.put(note..sig_valid = valid);
    });
  }
}
