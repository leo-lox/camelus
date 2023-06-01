import 'package:camelus/db/entities/tag.dart';
import 'package:floor/floor.dart';
import '../entities/note.dart';

@dao
abstract class NoteDao {
  @Query('SELECT * FROM Note')
  Stream<List<Note>> findAllNotesAsStream();

  @Query('SELECT * FROM Note JOIN Tag ON Note.id = Tag.note_id')
  Future<List<Note>> findAllNotes();

  @Query('SELECT content FROM Note')
  Stream<List<String>> findAllNotesContentStream();

  @Query('SELECT * FROM Note WHERE id = :id')
  Stream<Note?> findNoteByIdStream(int id);

  @insert
  Future<void> insertNote(Note note);

  @insert
  Future<List<int>> insertNotes(List<Note> notes);

  @Query('DELETE FROM Note')
  Future<void> deleteAllNotes();

  @Query('DELETE FROM Note WHERE id = :id')
  Future<void> deleteNoteById(int id);

  @Query('DELETE FROM Note WHERE id IN (:ids)')
  Future<void> deleteNotesByIds(List<int> ids);
}
