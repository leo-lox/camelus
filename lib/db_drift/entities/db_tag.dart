import 'package:camelus/db_drift/entities/db_note.dart';
import 'package:drift/drift.dart';

// this will generate a table called "todos" for us. The rows of that table will
// be represented by a class called "Todo".
@DataClassName('Tag')
class DbTag extends Table {
  @override
  Set<Column> get primaryKey => {note_id, value};

  TextColumn get note_id => text().references(
        DbNote,
        #id,
        onUpdate: KeyAction.cascade,
        onDelete: KeyAction.cascade,
      )();
  IntColumn get tag_index => integer()();
  TextColumn get type => text()();
  TextColumn get value => text()();
  TextColumn get recommended_relay => text().nullable()();
  TextColumn get marker => text().nullable()();
}
