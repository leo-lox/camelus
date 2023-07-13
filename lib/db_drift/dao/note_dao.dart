import 'package:camelus/db_drift/database.dart';
import 'package:camelus/db_drift/entities/db_note.dart';
import 'package:drift/drift.dart';

part 'note_dao.g.dart';

// the _TodosDaoMixin will be created by drift. It contains all the necessary
// fields for the tables. The <MyDatabase> type annotation is the database class
// that should use this dao.
@DriftAccessor(tables: [DbNote])
class NoteDao extends DatabaseAccessor<MyDatabase> with _$NoteDaoMixin {
  // this constructor is required so that the main database can create an instance
  // of this object.
  NoteDao(MyDatabase db) : super(db);

  Stream<List<DbNoteData>> findAllNotesAsStream() {
    return select(dbNote).watch();
  }

  Future<List<DbNoteData>> get allTodoEntries => select(dbNote).get();
}
