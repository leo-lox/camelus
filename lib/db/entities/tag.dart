import 'package:camelus/db/entities/note.dart';
import 'package:floor/floor.dart';

@Entity(
  tableName: 'tag',
  foreignKeys: [
    ForeignKey(
      childColumns: ['note_id'],
      parentColumns: ['id'],
      entity: Note,
    )
  ],
)
class Tag {
  @primaryKey
  final int id;

  // forin key
  final String note_id;

  final String pubkey;

  final String? recommended_relay;

  Tag(
      {required this.id,
      required this.note_id,
      required this.pubkey,
      this.recommended_relay});
}
