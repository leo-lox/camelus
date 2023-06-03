import 'package:camelus/db/entities/db_tag.dart';
import 'package:floor/floor.dart';

@dao
abstract class TagDao {
  @Query('SELECT * FROM Tag')
  Stream<List<DbTag>> findAllNotesAsStream();

  @Query('SELECT * FROM Tag ')
  Future<List<DbTag>> findAllNotes();

  @Query('SELECT * FROM Tag WHERE id = :id')
  Stream<DbTag?> findNoteByIdStream(int id);

  @insert
  Future<void> insertTag(DbTag tag);

  @insert
  Future<List<int>> insertTags(List<DbTag> tags);
}
