import 'package:drift/drift.dart';

// this will generate a table called "todos" for us. The rows of that table will
// be represented by a class called "Todo".
//@DataClassName('DbNote')
class DbNote extends Table {
  @override
  Set<Column> get primaryKey => {id};

  // indexes
  Index get indexKind => Index('idx_kind', 'kind');
  Index get indexPubkey => Index('idx_pubkey', 'pubkey');
  Index get indexCreatedAt => Index('idx_created_at', 'created_at');

  TextColumn get id => text()();
  TextColumn get pubkey => text()();
  // ignore: non_constant_identifier_names
  IntColumn get created_at => integer()();
  IntColumn get kind => integer()();
  TextColumn get content => text()();
  TextColumn get sig => text()();
}
