import 'package:camelus/db/entities/db_tag.dart';
import 'package:camelus/models/nostr_note.dart';
import 'package:floor/floor.dart';
import '../entities/db_note.dart';

@dao
abstract class NoteDao {
  @Query('SELECT * FROM Note')
  Stream<List<DbNote>> findAllNotesAsStream();

  @Query('SELECT * FROM Note LEFT JOIN Tag ON Note.id = Tag.note_id')
  Future<List<DbNote>> findAllNotes();

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
