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
            'CREATE TABLE IF NOT EXISTS `Note` (`id` TEXT NOT NULL, `pubkey` TEXT NOT NULL, `created_at` INTEGER NOT NULL, `kind` INTEGER NOT NULL, `content` TEXT NOT NULL, `sig` TEXT NOT NULL, PRIMARY KEY (`id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `Tag` (`note_id` TEXT NOT NULL, `tag_index` INTEGER NOT NULL, `type` TEXT NOT NULL, `value` TEXT NOT NULL, `recommended_relay` TEXT, `marker` TEXT, FOREIGN KEY (`note_id`) REFERENCES `Note` (`id`) ON UPDATE CASCADE ON DELETE CASCADE, PRIMARY KEY (`note_id`, `value`))');
        await database
            .execute('CREATE INDEX `index_Note_kind` ON `Note` (`kind`)');
        await database
            .execute('CREATE INDEX `index_Note_pubkey` ON `Note` (`pubkey`)');
        await database.execute(
            'CREATE INDEX `index_Note_created_at` ON `Note` (`created_at`)');
        await database.execute(
            'CREATE VIEW IF NOT EXISTS `noteView` AS SELECT Note.*, GROUP_CONCAT(Tag.type) as tag_types, GROUP_CONCAT(Tag.value) as tag_values, GROUP_CONCAT(Tag.recommended_relay) as tag_recommended_relays, GROUP_CONCAT(Tag.marker) as tag_markers, GROUP_CONCAT(Tag.tag_index) as tag_index FROM Note LEFT JOIN Tag ON Note.id = Tag.note_id GROUP BY Note.id;');

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
            'Note',
            (DbNote item) => <String, Object?>{
                  'id': item.id,
                  'pubkey': item.pubkey,
                  'created_at': item.created_at,
                  'kind': item.kind,
                  'content': item.content,
                  'sig': item.sig
                },
            changeListener),
        _dbTagInsertionAdapter = InsertionAdapter(
            database,
            'Tag',
            (DbTag item) => <String, Object?>{
                  'note_id': item.note_id,
                  'tag_index': item.tag_index,
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
            row['kind'] as int,
            row['content'] as String,
            row['sig'] as String),
        queryableName: 'Note',
        isView: false);
  }

  @override
  Future<List<DbNoteView>> findAllNotes() async {
    return _queryAdapter.queryList('SELECT * FROM noteView',
        mapper: (Map<String, Object?> row) => DbNoteView(
            id: row['id'] as String,
            pubkey: row['pubkey'] as String,
            created_at: row['created_at'] as int,
            kind: row['kind'] as int,
            content: row['content'] as String,
            sig: row['sig'] as String,
            tag_index: row['tag_index'] as String?,
            tag_types: row['tag_types'] as String?,
            tag_values: row['tag_values'] as String?,
            tag_recommended_relays: row['tag_recommended_relays'] as String?,
            tag_markers: row['tag_markers'] as String?));
  }

  @override
  Future<List<DbNoteView>> findAllNotesByKind(int kind) async {
    return _queryAdapter.queryList('SELECT * FROM noteView WHERE kind = ?1',
        mapper: (Map<String, Object?> row) => DbNoteView(
            id: row['id'] as String,
            pubkey: row['pubkey'] as String,
            created_at: row['created_at'] as int,
            kind: row['kind'] as int,
            content: row['content'] as String,
            sig: row['sig'] as String,
            tag_index: row['tag_index'] as String?,
            tag_types: row['tag_types'] as String?,
            tag_values: row['tag_values'] as String?,
            tag_recommended_relays: row['tag_recommended_relays'] as String?,
            tag_markers: row['tag_markers'] as String?),
        arguments: [kind]);
  }

  @override
  Stream<List<DbNoteView>> findAllNotesByKindStream(int kind) {
    return _queryAdapter.queryListStream(
        'SELECT * FROM (         SELECT Note.*, GROUP_CONCAT(Tag.type) as tag_types, GROUP_CONCAT(Tag.value) as tag_values, GROUP_CONCAT(Tag.recommended_relay) as tag_recommended_relays, GROUP_CONCAT(Tag.marker) as tag_markers, GROUP_CONCAT(Tag.tag_index) as tag_index          FROM Note          LEFT JOIN Tag ON Note.id = Tag.note_id          GROUP BY Note.id         ) AS noteView         WHERE kind = ?1',
        mapper: (Map<String, Object?> row) => DbNoteView(
            id: row['id'] as String,
            pubkey: row['pubkey'] as String,
            created_at: row['created_at'] as int,
            kind: row['kind'] as int,
            content: row['content'] as String,
            sig: row['sig'] as String,
            tag_index: row['tag_index'] as String?,
            tag_types: row['tag_types'] as String?,
            tag_values: row['tag_values'] as String?,
            tag_recommended_relays: row['tag_recommended_relays'] as String?,
            tag_markers: row['tag_markers'] as String?),
        arguments: [kind],
        queryableName: 'Note',
        isView: true);
  }

  @override
  Future<List<DbNoteView?>> findNote(String id) async {
    return _queryAdapter.queryList('SELECT * FROM noteView WHERE id = ?1',
        mapper: (Map<String, Object?> row) => DbNoteView(
            id: row['id'] as String,
            pubkey: row['pubkey'] as String,
            created_at: row['created_at'] as int,
            kind: row['kind'] as int,
            content: row['content'] as String,
            sig: row['sig'] as String,
            tag_index: row['tag_index'] as String?,
            tag_types: row['tag_types'] as String?,
            tag_values: row['tag_values'] as String?,
            tag_recommended_relays: row['tag_recommended_relays'] as String?,
            tag_markers: row['tag_markers'] as String?),
        arguments: [id]);
  }

  @override
  Future<List<DbNoteView>> findPubkeyNotes(List<String> pubkeys) async {
    const offset = 1;
    final sqliteVariablesForPubkeys =
        Iterable<String>.generate(pubkeys.length, (i) => '?${i + offset}')
            .join(',');
    return _queryAdapter.queryList(
        'SELECT * FROM noteView WHERE noteView.pubkey IN ($sqliteVariablesForPubkeys)',
        mapper: (Map<String, Object?> row) => DbNoteView(
            id: row['id'] as String,
            pubkey: row['pubkey'] as String,
            created_at: row['created_at'] as int,
            kind: row['kind'] as int,
            content: row['content'] as String,
            sig: row['sig'] as String,
            tag_index: row['tag_index'] as String?,
            tag_types: row['tag_types'] as String?,
            tag_values: row['tag_values'] as String?,
            tag_recommended_relays: row['tag_recommended_relays'] as String?,
            tag_markers: row['tag_markers'] as String?),
        arguments: [...pubkeys]);
  }

  @override
  Stream<List<DbNoteView>> findPubkeyNotesStream(List<String> pubkeys) {
    const offset = 1;
    final sqliteVariablesForPubkeys =
        Iterable<String>.generate(pubkeys.length, (i) => '?${i + offset}')
            .join(',');
    return _queryAdapter.queryListStream(
        'SELECT * FROM noteView WHERE noteView.pubkey IN ($sqliteVariablesForPubkeys) ORDER BY created_at DESC',
        mapper: (Map<String, Object?> row) => DbNoteView(
            id: row['id'] as String,
            pubkey: row['pubkey'] as String,
            created_at: row['created_at'] as int,
            kind: row['kind'] as int,
            content: row['content'] as String,
            sig: row['sig'] as String,
            tag_index: row['tag_index'] as String?,
            tag_types: row['tag_types'] as String?,
            tag_values: row['tag_values'] as String?,
            tag_recommended_relays: row['tag_recommended_relays'] as String?,
            tag_markers: row['tag_markers'] as String?),
        arguments: [...pubkeys],
        queryableName: 'noteView',
        isView: true);
  }

  @override
  Future<List<DbNoteView>> findPubkeyNotesByKind(
    List<String> pubkeys,
    int kind,
  ) async {
    const offset = 2;
    final sqliteVariablesForPubkeys =
        Iterable<String>.generate(pubkeys.length, (i) => '?${i + offset}')
            .join(',');
    return _queryAdapter.queryList(
        'SELECT * FROM noteView WHERE noteView.pubkey IN ($sqliteVariablesForPubkeys) AND kind = (?1) ORDER BY created_at DESC',
        mapper: (Map<String, Object?> row) => DbNoteView(
            id: row['id'] as String,
            pubkey: row['pubkey'] as String,
            created_at: row['created_at'] as int,
            kind: row['kind'] as int,
            content: row['content'] as String,
            sig: row['sig'] as String,
            tag_index: row['tag_index'] as String?,
            tag_types: row['tag_types'] as String?,
            tag_values: row['tag_values'] as String?,
            tag_recommended_relays: row['tag_recommended_relays'] as String?,
            tag_markers: row['tag_markers'] as String?),
        arguments: [kind, ...pubkeys]);
  }

  @override
  Stream<List<DbNoteView>> findPubkeyNotesByKindStream(
    List<String> pubkeys,
    int kind,
  ) {
    const offset = 2;
    final sqliteVariablesForPubkeys =
        Iterable<String>.generate(pubkeys.length, (i) => '?${i + offset}')
            .join(',');
    return _queryAdapter.queryListStream(
        'SELECT * FROM noteView WHERE noteView.pubkey IN ($sqliteVariablesForPubkeys) AND kind = (?1) ORDER BY created_at DESC',
        mapper: (Map<String, Object?> row) => DbNoteView(
            id: row['id'] as String,
            pubkey: row['pubkey'] as String,
            created_at: row['created_at'] as int,
            kind: row['kind'] as int,
            content: row['content'] as String,
            sig: row['sig'] as String,
            tag_index: row['tag_index'] as String?,
            tag_types: row['tag_types'] as String?,
            tag_values: row['tag_values'] as String?,
            tag_recommended_relays: row['tag_recommended_relays'] as String?,
            tag_markers: row['tag_markers'] as String?),
        arguments: [kind, ...pubkeys],
        queryableName: 'noteView',
        isView: true);
  }

  @override
  Stream<List<DbNoteView>> findPubkeyNotesByKindStreamNotifyOnly(
    List<String> pubkeys,
    int kind,
  ) {
    const offset = 2;
    final sqliteVariablesForPubkeys =
        Iterable<String>.generate(pubkeys.length, (i) => '?${i + offset}')
            .join(',');
    return _queryAdapter.queryListStream(
        'SELECT * FROM Note WHERE Note.pubkey IN ($sqliteVariablesForPubkeys) AND kind = (?1) ORDER BY created_at DESC',
        mapper: (Map<String, Object?> row) => DbNoteView(
            id: row['id'] as String,
            pubkey: row['pubkey'] as String,
            created_at: row['created_at'] as int,
            kind: row['kind'] as int,
            content: row['content'] as String,
            sig: row['sig'] as String,
            tag_index: row['tag_index'] as String?,
            tag_types: row['tag_types'] as String?,
            tag_values: row['tag_values'] as String?,
            tag_recommended_relays: row['tag_recommended_relays'] as String?,
            tag_markers: row['tag_markers'] as String?),
        arguments: [kind, ...pubkeys],
        queryableName: 'Note',
        isView: true);
  }

  @override
  Stream<List<DbNoteView>> findPubkeyNotesStreamByKindAndTimestamp(
    List<String> pubkeys,
    int kind,
    int timestamp,
  ) {
    const offset = 3;
    final sqliteVariablesForPubkeys =
        Iterable<String>.generate(pubkeys.length, (i) => '?${i + offset}')
            .join(',');
    return _queryAdapter.queryListStream(
        'SELECT * FROM noteView WHERE noteView.pubkey IN ($sqliteVariablesForPubkeys) AND kind = (?1) AND created_at > (?2) ORDER BY created_at DESC',
        mapper: (Map<String, Object?> row) => DbNoteView(
            id: row['id'] as String,
            pubkey: row['pubkey'] as String,
            created_at: row['created_at'] as int,
            kind: row['kind'] as int,
            content: row['content'] as String,
            sig: row['sig'] as String,
            tag_index: row['tag_index'] as String?,
            tag_types: row['tag_types'] as String?,
            tag_values: row['tag_values'] as String?,
            tag_recommended_relays: row['tag_recommended_relays'] as String?,
            tag_markers: row['tag_markers'] as String?),
        arguments: [kind, timestamp, ...pubkeys],
        queryableName: 'noteView',
        isView: true);
  }

  @override
  Future<List<DbNoteView>> findPubkeyRootNotesByKind(
    List<String> pubkeys,
    int kind,
  ) async {
    const offset = 2;
    final sqliteVariablesForPubkeys =
        Iterable<String>.generate(pubkeys.length, (i) => '?${i + offset}')
            .join(',');
    return _queryAdapter.queryList(
        'SELECT * FROM noteView        WHERE noteView.pubkey        IN ($sqliteVariablesForPubkeys)       AND kind = (?1)       AND (NOT (\',\' || tag_types || \',\' LIKE \'%,e,%\')       OR (tag_types IS NULL))       ORDER BY created_at DESC',
        mapper: (Map<String, Object?> row) => DbNoteView(id: row['id'] as String, pubkey: row['pubkey'] as String, created_at: row['created_at'] as int, kind: row['kind'] as int, content: row['content'] as String, sig: row['sig'] as String, tag_index: row['tag_index'] as String?, tag_types: row['tag_types'] as String?, tag_values: row['tag_values'] as String?, tag_recommended_relays: row['tag_recommended_relays'] as String?, tag_markers: row['tag_markers'] as String?),
        arguments: [kind, ...pubkeys]);
  }

  @override
  Stream<List<DbNoteView>> findPubkeyRootNotesByKindStreamNotifyOnly(
    List<String> pubkeys,
    int kind,
  ) {
    const offset = 2;
    final sqliteVariablesForPubkeys =
        Iterable<String>.generate(pubkeys.length, (i) => '?${i + offset}')
            .join(',');
    return _queryAdapter.queryListStream(
        'SELECT * FROM (         SELECT Note.*, GROUP_CONCAT(Tag.type) as tag_types, GROUP_CONCAT(Tag.value) as tag_values, GROUP_CONCAT(Tag.recommended_relay) as tag_recommended_relays, GROUP_CONCAT(Tag.marker) as tag_markers, GROUP_CONCAT(Tag.tag_index) as tag_index          FROM Note          LEFT JOIN Tag ON Note.id = Tag.note_id          GROUP BY Note.id         ) AS noteView         WHERE noteView.pubkey IN ($sqliteVariablesForPubkeys)          AND kind = (?1)         AND NOT (\',\' || tag_types || \',\' LIKE \'%,e,%\')         OR (tag_types IS NULL AND kind = (?1))         IN ($sqliteVariablesForPubkeys)          ORDER BY created_at DESC',
        mapper: (Map<String, Object?> row) => DbNoteView(
            id: row['id'] as String,
            pubkey: row['pubkey'] as String,
            created_at: row['created_at'] as int,
            kind: row['kind'] as int,
            content: row['content'] as String,
            sig: row['sig'] as String,
            tag_index: row['tag_index'] as String?,
            tag_types: row['tag_types'] as String?,
            tag_values: row['tag_values'] as String?,
            tag_recommended_relays: row['tag_recommended_relays'] as String?,
            tag_markers: row['tag_markers'] as String?),
        arguments: [kind, ...pubkeys],
        queryableName: 'Note',
        isView: true);
  }

  @override
  Future<List<DbNoteView>> findRepliesByIdAndByKind(
    String id,
    int kind,
  ) async {
    return _queryAdapter.queryList(
        'SELECT * FROM noteView        WHERE noteView.id = ?1       AND kind = ?2       OR instr(\',\' || tag_values || \',\', ?1) > 0       ORDER BY created_at ASC',
        mapper: (Map<String, Object?> row) => DbNoteView(id: row['id'] as String, pubkey: row['pubkey'] as String, created_at: row['created_at'] as int, kind: row['kind'] as int, content: row['content'] as String, sig: row['sig'] as String, tag_index: row['tag_index'] as String?, tag_types: row['tag_types'] as String?, tag_values: row['tag_values'] as String?, tag_recommended_relays: row['tag_recommended_relays'] as String?, tag_markers: row['tag_markers'] as String?),
        arguments: [id, kind]);
  }

  @override
  Stream<List<DbNoteView>> findRepliesByIdAndByKindStream(
    String id,
    int kind,
  ) {
    return _queryAdapter.queryListStream(
        'SELECT * FROM (         SELECT Note.*, GROUP_CONCAT(Tag.type) as tag_types, GROUP_CONCAT(Tag.value) as tag_values, GROUP_CONCAT(Tag.recommended_relay) as tag_recommended_relays, GROUP_CONCAT(Tag.marker) as tag_markers, GROUP_CONCAT(Tag.tag_index) as tag_index          FROM Note          LEFT JOIN Tag ON Note.id = Tag.note_id          GROUP BY Note.id         ) AS noteView       WHERE noteView.id = ?1       AND kind = ?2       OR instr(\',\' || tag_values || \',\', ?1) > 0       ORDER BY created_at ASC',
        mapper: (Map<String, Object?> row) => DbNoteView(
            id: row['id'] as String,
            pubkey: row['pubkey'] as String,
            created_at: row['created_at'] as int,
            kind: row['kind'] as int,
            content: row['content'] as String,
            sig: row['sig'] as String,
            tag_index: row['tag_index'] as String?,
            tag_types: row['tag_types'] as String?,
            tag_values: row['tag_values'] as String?,
            tag_recommended_relays: row['tag_recommended_relays'] as String?,
            tag_markers: row['tag_markers'] as String?),
        arguments: [id, kind],
        queryableName: 'Note',
        isView: true);
  }

  @override
  Future<List<DbNoteView>> findTagByKind(
    int kind,
    String tag,
  ) async {
    return _queryAdapter.queryList(
        'SELECT * FROM noteView        WHERE  (\',\' || tag_types || \',\' LIKE \'%,t,%\')       AND (\',\' || tag_values || \',\' LIKE ?2)        AND kind = ?1       ORDER BY created_at DESC',
        mapper: (Map<String, Object?> row) => DbNoteView(id: row['id'] as String, pubkey: row['pubkey'] as String, created_at: row['created_at'] as int, kind: row['kind'] as int, content: row['content'] as String, sig: row['sig'] as String, tag_index: row['tag_index'] as String?, tag_types: row['tag_types'] as String?, tag_values: row['tag_values'] as String?, tag_recommended_relays: row['tag_recommended_relays'] as String?, tag_markers: row['tag_markers'] as String?),
        arguments: [kind, tag]);
  }

  @override
  Stream<List<DbNoteView>> findTagByKindStream(
    int kind,
    String tag,
  ) {
    return _queryAdapter.queryListStream(
        'SELECT * FROM (         SELECT Note.*, GROUP_CONCAT(Tag.type) as tag_types, GROUP_CONCAT(Tag.value) as tag_values, GROUP_CONCAT(Tag.recommended_relay) as tag_recommended_relays, GROUP_CONCAT(Tag.marker) as tag_markers, GROUP_CONCAT(Tag.tag_index) as tag_index          FROM Note          LEFT JOIN Tag ON Note.id = Tag.note_id          GROUP BY Note.id         ) AS noteView       WHERE  (\',\' || tag_types || \',\' LIKE \'%,t,%\')       AND (\',\' || tag_values || \',\' LIKE ?2)        AND kind = ?1       ORDER BY created_at DESC',
        mapper: (Map<String, Object?> row) => DbNoteView(
            id: row['id'] as String,
            pubkey: row['pubkey'] as String,
            created_at: row['created_at'] as int,
            kind: row['kind'] as int,
            content: row['content'] as String,
            sig: row['sig'] as String,
            tag_index: row['tag_index'] as String?,
            tag_types: row['tag_types'] as String?,
            tag_values: row['tag_values'] as String?,
            tag_recommended_relays: row['tag_recommended_relays'] as String?,
            tag_markers: row['tag_markers'] as String?),
        arguments: [kind, tag],
        queryableName: 'Note',
        isView: true);
  }

  @override
  Stream<List<String>> findAllNotesContentStream() {
    return _queryAdapter.queryListStream('SELECT content FROM note',
        mapper: (Map<String, Object?> row) => row.values.first as String,
        queryableName: 'note',
        isView: false);
  }

  @override
  Stream<DbNote?> findNoteByIdStream(int id) {
    return _queryAdapter.queryStream('SELECT * FROM Note WHERE id = ?1',
        mapper: (Map<String, Object?> row) => DbNote(
            row['id'] as String,
            row['pubkey'] as String,
            row['created_at'] as int,
            row['kind'] as int,
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
    final sqliteVariablesForIds =
        Iterable<String>.generate(ids.length, (i) => '?${i + offset}')
            .join(',');
    await _queryAdapter.queryNoReturn(
        'DELETE FROM Note WHERE id IN ($sqliteVariablesForIds)',
        arguments: [...ids]);
  }

  @override
  Future<void> deleteNotesByKind(int kind) async {
    await _queryAdapter
        .queryNoReturn('DELETE FROM Note WHERE kind = ?1', arguments: [kind]);
  }

  @override
  Future<void> insertNote(DbNote note) async {
    await _dbNoteInsertionAdapter.insert(note, OnConflictStrategy.ignore);
  }

  @override
  Future<List<int>> insertNotes(List<DbNote> notes) {
    return _dbNoteInsertionAdapter.insertListAndReturnIds(
        notes, OnConflictStrategy.ignore);
  }

  @override
  Future<List<int>> insertTags(List<DbTag> tags) {
    return _dbTagInsertionAdapter.insertListAndReturnIds(
        tags, OnConflictStrategy.ignore);
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

  @override
  Future<void> insertNostrNotes(List<NostrNote> nostrNotes) async {
    if (database is sqflite.Transaction) {
      await super.insertNostrNotes(nostrNotes);
    } else {
      await (database as sqflite.Database)
          .transaction<void>((transaction) async {
        final transactionDatabase = _$AppDatabase(changeListener)
          ..database = transaction;
        await transactionDatabase.noteDao.insertNostrNotes(nostrNotes);
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
            'Tag',
            (DbTag item) => <String, Object?>{
                  'note_id': item.note_id,
                  'tag_index': item.tag_index,
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
            tag_index: row['tag_index'] as int,
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
            tag_index: row['tag_index'] as int,
            type: row['type'] as String,
            value: row['value'] as String,
            recommended_relay: row['recommended_relay'] as String?,
            marker: row['marker'] as String?));
  }

  @override
  Stream<DbTag?> findNoteByNoteIdStream(int noteId) {
    return _queryAdapter.queryStream('SELECT * FROM Tag WHERE note_id = ?1',
        mapper: (Map<String, Object?> row) => DbTag(
            note_id: row['note_id'] as String,
            tag_index: row['tag_index'] as int,
            type: row['type'] as String,
            value: row['value'] as String,
            recommended_relay: row['recommended_relay'] as String?,
            marker: row['marker'] as String?),
        arguments: [noteId],
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
