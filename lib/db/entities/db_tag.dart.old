// ignore_for_file: non_constant_identifier_names

import 'package:camelus/db/entities/db_note.dart';
import 'package:floor/floor.dart';

@Entity(
  tableName: 'Tag',
  primaryKeys: ['note_id', 'value'],
  foreignKeys: [
    ForeignKey(
      childColumns: ['note_id'],
      parentColumns: ['id'],
      entity: DbNote,
      onDelete: ForeignKeyAction.cascade,
      onUpdate: ForeignKeyAction.cascade,
    )
  ],
)
class DbTag {
  // forin key
  @ColumnInfo(name: 'note_id')
  final String note_id;

  @ColumnInfo(name: 'tag_index')
  final int tag_index;

  final String type;

  final String value;

  final String? recommended_relay;

  final String? marker;

  DbTag(
      {required this.note_id,
      required this.tag_index,
      required this.type,
      required this.value,
      this.recommended_relay,
      this.marker});
}
