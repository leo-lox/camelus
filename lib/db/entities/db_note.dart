import 'package:camelus/db/entities/db_tag.dart';
import 'package:floor/floor.dart';

@Entity(tableName: 'Note', indices: [
  Index(value: ['kind'])
])
class DbNote {
  @primaryKey
  final String id;

  final String pubkey;

  // ignore: non_constant_identifier_names
  final int created_at;

  @ColumnInfo(name: 'kind')
  final int kind;

  //final List<String> tags;
  /// => forin key @see tag.dart

  final String content;

  final String sig;

  DbNote(
      this.id, this.pubkey, this.created_at, this.kind, this.content, this.sig);

  @override
  String toString() {
    return 'DbNote{id: $id, pubkey: $pubkey, created_at: $created_at, kind: $kind, content: $content, sig: $sig}';
  }
}
