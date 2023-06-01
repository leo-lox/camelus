import 'package:floor/floor.dart';

@Entity(tableName: 'note', indices: [
  Index(value: ['index_kind'])
])
class Note {
  @primaryKey
  final String id;

  final String pubkey;

  final int created_at;

  @ColumnInfo(name: 'index_kind')
  final int kind;

  //final List<String> tags;
  /// => forin key @see tag.dart

  final String content;

  final String sig;

  Note(
      this.id, this.pubkey, this.created_at, this.kind, this.content, this.sig);
}
