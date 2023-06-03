import 'package:floor/floor.dart';

@Entity(tableName: 'note', indices: [
  Index(value: ['index_kind'])
])
class DbNote {
  @primaryKey
  final String id;

  final String pubkey;

  // ignore: non_constant_identifier_names
  final int created_at;

  @ColumnInfo(name: 'index_kind')
  final int kind;

  //final List<String> tags;
  /// => forin key @see tag.dart

  final String content;

  final String sig;

  DbNote(
      this.id, this.pubkey, this.created_at, this.kind, this.content, this.sig);
}
