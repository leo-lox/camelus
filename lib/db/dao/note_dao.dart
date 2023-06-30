import 'dart:async';
import 'dart:developer';

import 'package:camelus/db/entities/db_note_view.dart';
import 'package:camelus/db/entities/db_tag.dart';
import 'package:camelus/models/nostr_note.dart';
import 'package:floor/floor.dart';
import '../entities/db_note.dart';

@dao
abstract class NoteDao {
  @Query('SELECT * FROM Note')
  Stream<List<DbNote>> findAllNotesAsStream();

  @Query('SELECT * FROM noteView')
  Future<List<DbNoteView>> findAllNotes();

  @Query('SELECT * FROM noteView WHERE kind = :kind')
  Future<List<DbNoteView>> findAllNotesByKind(int kind);

  @Query('''
        SELECT * FROM (
        SELECT Note.*, GROUP_CONCAT(Tag.type) as tag_types, GROUP_CONCAT(Tag.value) as tag_values, GROUP_CONCAT(Tag.recommended_relay) as tag_recommended_relays, GROUP_CONCAT(Tag.marker) as tag_markers, GROUP_CONCAT(Tag.tag_index) as tag_index 
        FROM Note 
        LEFT JOIN Tag ON Note.id = Tag.note_id 
        GROUP BY Note.id
        ) AS noteView
        WHERE kind = :kind
        ''')
  Stream<List<DbNoteView>> findAllNotesByKindStream(int kind);

  @Query('SELECT * FROM noteView WHERE id = :id')
  Future<List<DbNoteView?>> findNote(String id);

  @Query("SELECT * FROM noteView WHERE noteView.pubkey IN (:pubkeys)")
  Future<List<DbNoteView>> findPubkeyNotes(List<String> pubkeys);

  @Query(
      "SELECT * FROM noteView WHERE noteView.pubkey IN (:pubkeys) ORDER BY created_at DESC")
  Stream<List<DbNoteView>> findPubkeyNotesStream(List<String> pubkeys);

  @Query(
      "SELECT * FROM noteView WHERE noteView.pubkey IN (:pubkeys) AND kind = (:kind) ORDER BY created_at DESC")
  Future<List<DbNoteView>> findPubkeyNotesByKind(
      List<String> pubkeys, int kind);

  @Query(
      "SELECT * FROM noteView WHERE noteView.pubkey IN (:pubkeys) AND kind = (:kind) ORDER BY created_at DESC ")
  Stream<List<DbNoteView>> findPubkeyNotesByKindStream(
      List<String> pubkeys, int kind);

  /// floor gets confused when streaming from a view, so instead use this to notify and then get notes from the view
  @Query(
      "SELECT * FROM Note WHERE Note.pubkey IN (:pubkeys) AND kind = (:kind) ORDER BY created_at DESC ")
  Stream<List<DbNoteView>> findPubkeyNotesByKindStreamNotifyOnly(
      List<String> pubkeys, int kind);

  @Query(
      "SELECT * FROM noteView WHERE noteView.pubkey IN (:pubkeys) AND kind = (:kind) AND created_at > (:timestamp) ORDER BY created_at DESC")
  Stream<List<DbNoteView>> findPubkeyNotesStreamByKindAndTimestamp(
      List<String> pubkeys, int kind, int timestamp);

  // find root notes
  @Query("""
      SELECT * FROM noteView 
      WHERE noteView.pubkey 
      IN (:pubkeys) 
      AND kind = (:kind)
      AND NOT (',' || tag_types || ',' LIKE '%,e,%')
      OR (tag_types IS NULL AND kind = (:kind))
      IN (:pubkeys) 

      ORDER BY created_at DESC
      """)
  Future<List<DbNoteView>> findPubkeyRootNotesByKind(
      List<String> pubkeys, int kind);

  // copied view because otherwise floor change/stream detection gets confused
  @Query("""
        SELECT * FROM (
        SELECT Note.*, GROUP_CONCAT(Tag.type) as tag_types, GROUP_CONCAT(Tag.value) as tag_values, GROUP_CONCAT(Tag.recommended_relay) as tag_recommended_relays, GROUP_CONCAT(Tag.marker) as tag_markers, GROUP_CONCAT(Tag.tag_index) as tag_index 
        FROM Note 
        LEFT JOIN Tag ON Note.id = Tag.note_id 
        GROUP BY Note.id
        ) AS noteView
        WHERE noteView.pubkey IN (:pubkeys) 
        AND kind = (:kind)
        AND NOT (',' || tag_types || ',' LIKE '%,e,%')
        OR (tag_types IS NULL AND kind = (:kind))
        IN (:pubkeys) 
        ORDER BY created_at DESC
      """)
  Stream<List<DbNoteView>> findPubkeyRootNotesByKindStreamNotifyOnly(
      List<String> pubkeys, int kind);

  // event view
  @Query("""
      SELECT * FROM noteView 
      WHERE noteView.id = :id
      AND kind = :kind
      OR instr(',' || tag_values || ',', :id) > 0
      ORDER BY created_at ASC
      """)
  Future<List<DbNoteView>> findRepliesByIdAndByKind(String id, int kind);

  // event view
  @Query("""
       SELECT * FROM (
        SELECT Note.*, GROUP_CONCAT(Tag.type) as tag_types, GROUP_CONCAT(Tag.value) as tag_values, GROUP_CONCAT(Tag.recommended_relay) as tag_recommended_relays, GROUP_CONCAT(Tag.marker) as tag_markers, GROUP_CONCAT(Tag.tag_index) as tag_index 
        FROM Note 
        LEFT JOIN Tag ON Note.id = Tag.note_id 
        GROUP BY Note.id
        ) AS noteView
      WHERE noteView.id = :id
      AND kind = :kind
      OR instr(',' || tag_values || ',', :id) > 0
      ORDER BY created_at ASC
      """)
  Stream<List<DbNoteView>> findRepliesByIdAndByKindStream(String id, int kind);

  @Query('SELECT content FROM note')
  Stream<List<String>> findAllNotesContentStream();

  @Query('SELECT * FROM Note WHERE id = :id')
  Stream<DbNote?> findNoteByIdStream(int id);

  @Insert(onConflict: OnConflictStrategy.ignore)
  Future<void> insertNote(DbNote note);

  @Insert(onConflict: OnConflictStrategy.ignore)
  Future<List<int>> insertNotes(List<DbNote> notes);

  @Insert(onConflict: OnConflictStrategy.ignore)
  Future<List<int>> insertTags(List<DbTag> tags);

  @Query('DELETE FROM Note')
  Future<void> deleteAllNotes();

  @Query('DELETE FROM Note WHERE id = :id')
  Future<void> deleteNoteById(int id);

  @Query('DELETE FROM Note WHERE id IN (:ids)')
  Future<void> deleteNotesByIds(List<int> ids);

  @transaction
  Future<void> insertNostrNote(NostrNote nostrNote) async {
    try {
      await insertNote(nostrNote.toDbNote());
      await insertTags(nostrNote.toDbTag());
    } catch (e) {
      // problably already exists
    }
  }

  @transaction
  Future<void> insertNostrNotes(List<NostrNote> nostrNotes) async {
    try {
      await insertNotes(nostrNotes.map((e) => e.toDbNote()).toList());
      await insertTags(
          nostrNotes.map((e) => e.toDbTag()).expand((x) => x).toList());
    } catch (e) {
      // problably already exists
      log(e.toString());
    }
  }

  List<NostrNote> toInsertNotes = [];
  Timer? insertNotesTimer;
  stackInsertNotes(List<NostrNote> notes) async {
    // stack insert after 100 notes or 1 seconds
    toInsertNotes.addAll(notes);

    toInsertNotes = toInsertNotes.toSet().toList();

    if (insertNotesTimer != null) {
      insertNotesTimer!.cancel();
    }
    insertNotesTimer = Timer(const Duration(milliseconds: 100), () async {
      var copy = [...toInsertNotes];
      toInsertNotes = [];
      await insertNostrNotes(copy);
    });

    if (toInsertNotes.length > 100) {
      insertNotesTimer!.cancel();
      var copy = [...toInsertNotes];
      toInsertNotes = [];
      await insertNostrNotes(copy);
    }
  }
}
