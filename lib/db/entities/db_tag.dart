import 'package:camelus/db/entities/db_note.dart';
import 'package:floor/floor.dart';

@Entity(
  tableName: 'tag',
  primaryKeys: ['note_id', 'value'],
  foreignKeys: [
    ForeignKey(
      childColumns: ['note_id'],
      parentColumns: ['id'],
      entity: DbNote,
    )
  ],
)
class DbTag {
  // forin key
  final String note_id;

  final String type;

  final String value;

  final String? recommended_relay;

  final String? marker;

  DbTag(
      {required this.note_id,
      required this.type,
      required this.value,
      this.recommended_relay,
      this.marker});
}
