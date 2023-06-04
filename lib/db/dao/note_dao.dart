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

  @Query("SELECT * FROM noteView WHERE noteView.pubkey IN (:pubkeys)")
  Future<List<DbNoteView>> findPubkeyNotes(List<String> pubkeys);

  @Query('SELECT content FROM note')
  Stream<List<String>> findAllNotesContentStream();

  @Query('SELECT * FROM Note WHERE id = :id')
  Stream<DbNote?> findNoteByIdStream(int id);

  @insert
  Future<void> insertNote(DbNote note);

  @insert
  Future<List<int>> insertNotes(List<DbNote> notes);

  @Query('DELETE FROM Note')
  Future<void> deleteAllNotes();

  @Query('DELETE FROM Note WHERE id = :id')
  Future<void> deleteNoteById(int id);

  @Query('DELETE FROM Note WHERE id IN (:ids)')
  Future<void> deleteNotesByIds(List<int> ids);

  @transaction
  Future<void> insertNostrNote(NostrNote nostrNote) async {
    await insertNote(nostrNote.toDbNote());
    await insertTags(nostrNote.toDbTag());
  }

  @insert
  Future<List<int>> insertTags(List<DbTag> tags);
}