// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// **************************************************************************
// FloorGenerator
// **************************************************************************

// ignore: avoid_classes_with_only_static_members
class $FloorAppDatabase {
  /// Creates a database builder for a persistent database.
  /// Once a database is built, you should keep a reference to it and re-use it.
  static _$AppDatabaseBuilder databaseBuilder(String name) =>
      _$AppDatabaseBuilder(name);

  /// Creates a database builder for an in memory database.
  /// Information stored in an in memory database disappears when the process is killed.
  /// Once a database is built, you should keep a reference to it and re-use it.
  static _$AppDatabaseBuilder inMemoryDatabaseBuilder() =>
      _$AppDatabaseBuilder(null);
}

class _$AppDatabaseBuilder {
  _$AppDatabaseBuilder(this.name);

  final String? name;

  final List<Migration> _migrations = [];

  Callback? _callback;

  /// Adds migrations to the builder.
  _$AppDatabaseBuilder addMigrations(List<Migration> migrations) {
    _migrations.addAll(migrations);
    return this;
  }

  /// Adds a database [Callback] to the builder.
  _$AppDatabaseBuilder addCallback(Callback callback) {
    _callback = callback;
    return this;
  }

  /// Creates the database and initializes it.
  Future<AppDatabase> build() async {
    final path = name != null
        ? await sqfliteDatabaseFactory.getDatabasePath(name!)
        : ':memory:';
    final database = _$AppDatabase();
    database.database = await database.open(
      path,
      _migrations,
      _callback,
    );
    return database;
  }
}

class _$AppDatabase extends AppDatabase {
  _$AppDatabase([StreamController<String>? listener]) {
    changeListener = listener ?? StreamController<String>.broadcast();
  }

  NoteDao? _noteDaoInstance;

  TagDao? _tagDaoInstance;

  Future<sqflite.Database> open(
    String path,
    List<Migration> migrations, [
    Callback? callback,
  ]) async {
    final databaseOptions = sqflite.OpenDatabaseOptions(
      version: 1,
      onConfigure: (database) async {
        await database.execute('PRAGMA foreign_keys = ON');
        await callback?.onConfigure?.call(database);
      },
      onOpen: (database) async {
        await callback?.onOpen?.call(database);
      },
      onUpgrade: (database, startVersion, endVersion) async {
        await MigrationAdapter.runMigrations(
            database, startVersion, endVersion, migrations);

        await callback?.onUpgrade?.call(database, startVersion, endVersion);
      },
      onCreate: (database, version) async {
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `note` (`id` TEXT NOT NULL, `pubkey` TEXT NOT NULL, `created_at` INTEGER NOT NULL, `index_kind` INTEGER NOT NULL, `content` TEXT NOT NULL, `sig` TEXT NOT NULL, PRIMARY KEY (`id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `tag` (`note_id` TEXT NOT NULL, `type` TEXT NOT NULL, `value` TEXT NOT NULL, `recommended_relay` TEXT, `marker` TEXT, FOREIGN KEY (`note_id`) REFERENCES `note` (`id`) ON UPDATE NO ACTION ON DELETE NO ACTION, PRIMARY KEY (`note_id`, `value`))');
        await database.execute(
            'CREATE INDEX `index_note_index_kind` ON `note` (`index_kind`)');

        await callback?.onCreate?.call(database, version);
      },
    );
    return sqfliteDatabaseFactory.openDatabase(path, options: databaseOptions);
  }

  @override
  NoteDao get noteDao {
    return _noteDaoInstance ??= _$NoteDao(database, changeListener);
  }

  @override
  TagDao get tagDao {
    return _tagDaoInstance ??= _$TagDao(database, changeListener);
  }
}

class _$NoteDao extends NoteDao {
  _$NoteDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database, changeListener),
        _dbNoteInsertionAdapter = InsertionAdapter(
            database,
            'note',
            (DbNote item) => <String, Object?>{
                  'id': item.id,
                  'pubkey': item.pubkey,
                  'created_at': item.created_at,
                  'index_kind': item.kind,
                  'content': item.content,
                  'sig': item.sig
                },
            changeListener),
        _dbTagInsertionAdapter = InsertionAdapter(
            database,
            'tag',
            (DbTag item) => <String, Object?>{
                  'note_id': item.note_id,
                  'type': item.type,
                  'value': item.value,
                  'recommended_relay': item.recommended_relay,
                  'marker': item.marker
                },
            changeListener);

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<DbNote> _dbNoteInsertionAdapter;

  final InsertionAdapter<DbTag> _dbTagInsertionAdapter;

  @override
  Stream<List<DbNote>> findAllNotesAsStream() {
    return _queryAdapter.queryListStream('SELECT * FROM Note',
        mapper: (Map<String, Object?> row) => DbNote(
            row['id'] as String,
            row['pubkey'] as String,
            row['created_at'] as int,
            row['index_kind'] as int,
            row['content'] as String,
            row['sig'] as String),
        queryableName: 'Note',
        isView: false);
  }

  @override
  Future<List<DbNote>> findAllNotes() async {
    return _queryAdapter.queryList(
        'SELECT * FROM Note JOIN Tag ON Note.id = Tag.note_id',
        mapper: (Map<String, Object?> row) => DbNote(
            row['id'] as String,
            row['pubkey'] as String,
            row['created_at'] as int,
            row['index_kind'] as int,
            row['content'] as String,
            row['sig'] as String));
  }

  @override
  Stream<List<String>> findAllNotesContentStream() {
    return _queryAdapter.queryListStream('SELECT content FROM Note',
        mapper: (Map<String, Object?> row) => row.values.first as String,
        queryableName: 'Note',
        isView: false);
  }

  @override
  Stream<DbNote?> findNoteByIdStream(int id) {
    return _queryAdapter.queryStream('SELECT * FROM Note WHERE id = ?1',
        mapper: (Map<String, Object?> row) => DbNote(
            row['id'] as String,
            row['pubkey'] as String,
            row['created_at'] as int,
            row['index_kind'] as int,
            row['content'] as String,
            row['sig'] as String),
        arguments: [id],
        queryableName: 'Note',
        isView: false);
  }

  @override
  Future<void> deleteAllNotes() async {
    await _queryAdapter.queryNoReturn('DELETE FROM Note');
  }

  @override
  Future<void> deleteNoteById(int id) async {
    await _queryAdapter
        .queryNoReturn('DELETE FROM Note WHERE id = ?1', arguments: [id]);
  }

  @override
  Future<void> deleteNotesByIds(List<int> ids) async {
    const offset = 1;
    final _sqliteVariablesForIds =
        Iterable<String>.generate(ids.length, (i) => '?${i + offset}')
            .join(',');
    await _queryAdapter.queryNoReturn(
        'DELETE FROM Note WHERE id IN (' + _sqliteVariablesForIds + ')',
        arguments: [...ids]);
  }

  @override
  Future<void> insertNote(DbNote note) async {
    await _dbNoteInsertionAdapter.insert(note, OnConflictStrategy.abort);
  }

  @override
  Future<List<int>> insertNotes(List<DbNote> notes) {
    return _dbNoteInsertionAdapter.insertListAndReturnIds(
        notes, OnConflictStrategy.abort);
  }

  @override
  Future<List<int>> insertTags(List<DbTag> tags) {
    return _dbTagInsertionAdapter.insertListAndReturnIds(
        tags, OnConflictStrategy.abort);
  }

  @override
  Future<void> insertNostrNote(NostrNote nostrNote) async {
    if (database is sqflite.Transaction) {
      await super.insertNostrNote(nostrNote);
    } else {
      await (database as sqflite.Database)
          .transaction<void>((transaction) async {
        final transactionDatabase = _$AppDatabase(changeListener)
          ..database = transaction;
        await transactionDatabase.noteDao.insertNostrNote(nostrNote);
      });
    }
  }
}

class _$TagDao extends TagDao {
  _$TagDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database, changeListener),
        _dbTagInsertionAdapter = InsertionAdapter(
            database,
            'tag',
            (DbTag item) => <String, Object?>{
                  'note_id': item.note_id,
                  'type': item.type,
                  'value': item.value,
                  'recommended_relay': item.recommended_relay,
                  'marker': item.marker
                },
            changeListener);

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<DbTag> _dbTagInsertionAdapter;

  @override
  Stream<List<DbTag>> findAllNotesAsStream() {
    return _queryAdapter.queryListStream('SELECT * FROM Tag',
        mapper: (Map<String, Object?> row) => DbTag(
            note_id: row['note_id'] as String,
            type: row['type'] as String,
            value: row['value'] as String,
            recommended_relay: row['recommended_relay'] as String?,
            marker: row['marker'] as String?),
        queryableName: 'Tag',
        isView: false);
  }

  @override
  Future<List<DbTag>> findAllNotes() async {
    return _queryAdapter.queryList('SELECT * FROM Tag',
        mapper: (Map<String, Object?> row) => DbTag(
            note_id: row['note_id'] as String,
            type: row['type'] as String,
            value: row['value'] as String,
            recommended_relay: row['recommended_relay'] as String?,
            marker: row['marker'] as String?));
  }

  @override
  Stream<DbTag?> findNoteByIdStream(int id) {
    return _queryAdapter.queryStream('SELECT * FROM Tag WHERE id = ?1',
        mapper: (Map<String, Object?> row) => DbTag(
            note_id: row['note_id'] as String,
            type: row['type'] as String,
            value: row['value'] as String,
            recommended_relay: row['recommended_relay'] as String?,
            marker: row['marker'] as String?),
        arguments: [id],
        queryableName: 'Tag',
        isView: false);
  }

  @override
  Future<void> insertTag(DbTag tag) async {
    await _dbTagInsertionAdapter.insert(tag, OnConflictStrategy.abort);
  }

  @override
  Future<List<int>> insertTags(List<DbTag> tags) {
    return _dbTagInsertionAdapter.insertListAndReturnIds(
        tags, OnConflictStrategy.abort);
  }
}
