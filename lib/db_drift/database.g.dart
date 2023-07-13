// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $DbNoteTable extends DbNote with TableInfo<$DbNoteTable, DbNoteData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DbNoteTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _pubkeyMeta = const VerificationMeta('pubkey');
  @override
  late final GeneratedColumn<String> pubkey = GeneratedColumn<String>(
      'pubkey', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _created_atMeta =
      const VerificationMeta('created_at');
  @override
  late final GeneratedColumn<int> created_at = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<int> kind = GeneratedColumn<int>(
      'kind', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _contentMeta =
      const VerificationMeta('content');
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
      'content', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sigMeta = const VerificationMeta('sig');
  @override
  late final GeneratedColumn<String> sig = GeneratedColumn<String>(
      'sig', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, pubkey, created_at, kind, content, sig];
  @override
  String get aliasedName => _alias ?? 'db_note';
  @override
  String get actualTableName => 'db_note';
  @override
  VerificationContext validateIntegrity(Insertable<DbNoteData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('pubkey')) {
      context.handle(_pubkeyMeta,
          pubkey.isAcceptableOrUnknown(data['pubkey']!, _pubkeyMeta));
    } else if (isInserting) {
      context.missing(_pubkeyMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
          _created_atMeta,
          created_at.isAcceptableOrUnknown(
              data['created_at']!, _created_atMeta));
    } else if (isInserting) {
      context.missing(_created_atMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
          _kindMeta, kind.isAcceptableOrUnknown(data['kind']!, _kindMeta));
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('content')) {
      context.handle(_contentMeta,
          content.isAcceptableOrUnknown(data['content']!, _contentMeta));
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('sig')) {
      context.handle(
          _sigMeta, sig.isAcceptableOrUnknown(data['sig']!, _sigMeta));
    } else if (isInserting) {
      context.missing(_sigMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DbNoteData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DbNoteData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      pubkey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}pubkey'])!,
      created_at: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      kind: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}kind'])!,
      content: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content'])!,
      sig: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sig'])!,
    );
  }

  @override
  $DbNoteTable createAlias(String alias) {
    return $DbNoteTable(attachedDatabase, alias);
  }
}

class DbNoteData extends DataClass implements Insertable<DbNoteData> {
  final String id;
  final String pubkey;
  final int created_at;
  final int kind;
  final String content;
  final String sig;
  const DbNoteData(
      {required this.id,
      required this.pubkey,
      required this.created_at,
      required this.kind,
      required this.content,
      required this.sig});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['pubkey'] = Variable<String>(pubkey);
    map['created_at'] = Variable<int>(created_at);
    map['kind'] = Variable<int>(kind);
    map['content'] = Variable<String>(content);
    map['sig'] = Variable<String>(sig);
    return map;
  }

  DbNoteCompanion toCompanion(bool nullToAbsent) {
    return DbNoteCompanion(
      id: Value(id),
      pubkey: Value(pubkey),
      created_at: Value(created_at),
      kind: Value(kind),
      content: Value(content),
      sig: Value(sig),
    );
  }

  factory DbNoteData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DbNoteData(
      id: serializer.fromJson<String>(json['id']),
      pubkey: serializer.fromJson<String>(json['pubkey']),
      created_at: serializer.fromJson<int>(json['created_at']),
      kind: serializer.fromJson<int>(json['kind']),
      content: serializer.fromJson<String>(json['content']),
      sig: serializer.fromJson<String>(json['sig']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'pubkey': serializer.toJson<String>(pubkey),
      'created_at': serializer.toJson<int>(created_at),
      'kind': serializer.toJson<int>(kind),
      'content': serializer.toJson<String>(content),
      'sig': serializer.toJson<String>(sig),
    };
  }

  DbNoteData copyWith(
          {String? id,
          String? pubkey,
          int? created_at,
          int? kind,
          String? content,
          String? sig}) =>
      DbNoteData(
        id: id ?? this.id,
        pubkey: pubkey ?? this.pubkey,
        created_at: created_at ?? this.created_at,
        kind: kind ?? this.kind,
        content: content ?? this.content,
        sig: sig ?? this.sig,
      );
  @override
  String toString() {
    return (StringBuffer('DbNoteData(')
          ..write('id: $id, ')
          ..write('pubkey: $pubkey, ')
          ..write('created_at: $created_at, ')
          ..write('kind: $kind, ')
          ..write('content: $content, ')
          ..write('sig: $sig')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, pubkey, created_at, kind, content, sig);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DbNoteData &&
          other.id == this.id &&
          other.pubkey == this.pubkey &&
          other.created_at == this.created_at &&
          other.kind == this.kind &&
          other.content == this.content &&
          other.sig == this.sig);
}

class DbNoteCompanion extends UpdateCompanion<DbNoteData> {
  final Value<String> id;
  final Value<String> pubkey;
  final Value<int> created_at;
  final Value<int> kind;
  final Value<String> content;
  final Value<String> sig;
  final Value<int> rowid;
  const DbNoteCompanion({
    this.id = const Value.absent(),
    this.pubkey = const Value.absent(),
    this.created_at = const Value.absent(),
    this.kind = const Value.absent(),
    this.content = const Value.absent(),
    this.sig = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DbNoteCompanion.insert({
    required String id,
    required String pubkey,
    required int created_at,
    required int kind,
    required String content,
    required String sig,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        pubkey = Value(pubkey),
        created_at = Value(created_at),
        kind = Value(kind),
        content = Value(content),
        sig = Value(sig);
  static Insertable<DbNoteData> custom({
    Expression<String>? id,
    Expression<String>? pubkey,
    Expression<int>? created_at,
    Expression<int>? kind,
    Expression<String>? content,
    Expression<String>? sig,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (pubkey != null) 'pubkey': pubkey,
      if (created_at != null) 'created_at': created_at,
      if (kind != null) 'kind': kind,
      if (content != null) 'content': content,
      if (sig != null) 'sig': sig,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DbNoteCompanion copyWith(
      {Value<String>? id,
      Value<String>? pubkey,
      Value<int>? created_at,
      Value<int>? kind,
      Value<String>? content,
      Value<String>? sig,
      Value<int>? rowid}) {
    return DbNoteCompanion(
      id: id ?? this.id,
      pubkey: pubkey ?? this.pubkey,
      created_at: created_at ?? this.created_at,
      kind: kind ?? this.kind,
      content: content ?? this.content,
      sig: sig ?? this.sig,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (pubkey.present) {
      map['pubkey'] = Variable<String>(pubkey.value);
    }
    if (created_at.present) {
      map['created_at'] = Variable<int>(created_at.value);
    }
    if (kind.present) {
      map['kind'] = Variable<int>(kind.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (sig.present) {
      map['sig'] = Variable<String>(sig.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DbNoteCompanion(')
          ..write('id: $id, ')
          ..write('pubkey: $pubkey, ')
          ..write('created_at: $created_at, ')
          ..write('kind: $kind, ')
          ..write('content: $content, ')
          ..write('sig: $sig, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DbTagTable extends DbTag with TableInfo<$DbTagTable, Tag> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DbTagTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _note_idMeta =
      const VerificationMeta('note_id');
  @override
  late final GeneratedColumn<String> note_id = GeneratedColumn<String>(
      'note_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES db_note (id) ON UPDATE CASCADE ON DELETE CASCADE'));
  static const VerificationMeta _tag_indexMeta =
      const VerificationMeta('tag_index');
  @override
  late final GeneratedColumn<int> tag_index = GeneratedColumn<int>(
      'tag_index', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
      'value', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _recommended_relayMeta =
      const VerificationMeta('recommended_relay');
  @override
  late final GeneratedColumn<String> recommended_relay =
      GeneratedColumn<String>('recommended_relay', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _markerMeta = const VerificationMeta('marker');
  @override
  late final GeneratedColumn<String> marker = GeneratedColumn<String>(
      'marker', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [note_id, tag_index, type, value, recommended_relay, marker];
  @override
  String get aliasedName => _alias ?? 'db_tag';
  @override
  String get actualTableName => 'db_tag';
  @override
  VerificationContext validateIntegrity(Insertable<Tag> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('note_id')) {
      context.handle(_note_idMeta,
          note_id.isAcceptableOrUnknown(data['note_id']!, _note_idMeta));
    } else if (isInserting) {
      context.missing(_note_idMeta);
    }
    if (data.containsKey('tag_index')) {
      context.handle(_tag_indexMeta,
          tag_index.isAcceptableOrUnknown(data['tag_index']!, _tag_indexMeta));
    } else if (isInserting) {
      context.missing(_tag_indexMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('recommended_relay')) {
      context.handle(
          _recommended_relayMeta,
          recommended_relay.isAcceptableOrUnknown(
              data['recommended_relay']!, _recommended_relayMeta));
    }
    if (data.containsKey('marker')) {
      context.handle(_markerMeta,
          marker.isAcceptableOrUnknown(data['marker']!, _markerMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {note_id, value};
  @override
  Tag map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Tag(
      note_id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note_id'])!,
      tag_index: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}tag_index'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}value'])!,
      recommended_relay: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}recommended_relay']),
      marker: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}marker']),
    );
  }

  @override
  $DbTagTable createAlias(String alias) {
    return $DbTagTable(attachedDatabase, alias);
  }
}

class Tag extends DataClass implements Insertable<Tag> {
  final String note_id;
  final int tag_index;
  final String type;
  final String value;
  final String? recommended_relay;
  final String? marker;
  const Tag(
      {required this.note_id,
      required this.tag_index,
      required this.type,
      required this.value,
      this.recommended_relay,
      this.marker});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['note_id'] = Variable<String>(note_id);
    map['tag_index'] = Variable<int>(tag_index);
    map['type'] = Variable<String>(type);
    map['value'] = Variable<String>(value);
    if (!nullToAbsent || recommended_relay != null) {
      map['recommended_relay'] = Variable<String>(recommended_relay);
    }
    if (!nullToAbsent || marker != null) {
      map['marker'] = Variable<String>(marker);
    }
    return map;
  }

  DbTagCompanion toCompanion(bool nullToAbsent) {
    return DbTagCompanion(
      note_id: Value(note_id),
      tag_index: Value(tag_index),
      type: Value(type),
      value: Value(value),
      recommended_relay: recommended_relay == null && nullToAbsent
          ? const Value.absent()
          : Value(recommended_relay),
      marker:
          marker == null && nullToAbsent ? const Value.absent() : Value(marker),
    );
  }

  factory Tag.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Tag(
      note_id: serializer.fromJson<String>(json['note_id']),
      tag_index: serializer.fromJson<int>(json['tag_index']),
      type: serializer.fromJson<String>(json['type']),
      value: serializer.fromJson<String>(json['value']),
      recommended_relay:
          serializer.fromJson<String?>(json['recommended_relay']),
      marker: serializer.fromJson<String?>(json['marker']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'note_id': serializer.toJson<String>(note_id),
      'tag_index': serializer.toJson<int>(tag_index),
      'type': serializer.toJson<String>(type),
      'value': serializer.toJson<String>(value),
      'recommended_relay': serializer.toJson<String?>(recommended_relay),
      'marker': serializer.toJson<String?>(marker),
    };
  }

  Tag copyWith(
          {String? note_id,
          int? tag_index,
          String? type,
          String? value,
          Value<String?> recommended_relay = const Value.absent(),
          Value<String?> marker = const Value.absent()}) =>
      Tag(
        note_id: note_id ?? this.note_id,
        tag_index: tag_index ?? this.tag_index,
        type: type ?? this.type,
        value: value ?? this.value,
        recommended_relay: recommended_relay.present
            ? recommended_relay.value
            : this.recommended_relay,
        marker: marker.present ? marker.value : this.marker,
      );
  @override
  String toString() {
    return (StringBuffer('Tag(')
          ..write('note_id: $note_id, ')
          ..write('tag_index: $tag_index, ')
          ..write('type: $type, ')
          ..write('value: $value, ')
          ..write('recommended_relay: $recommended_relay, ')
          ..write('marker: $marker')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(note_id, tag_index, type, value, recommended_relay, marker);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Tag &&
          other.note_id == this.note_id &&
          other.tag_index == this.tag_index &&
          other.type == this.type &&
          other.value == this.value &&
          other.recommended_relay == this.recommended_relay &&
          other.marker == this.marker);
}

class DbTagCompanion extends UpdateCompanion<Tag> {
  final Value<String> note_id;
  final Value<int> tag_index;
  final Value<String> type;
  final Value<String> value;
  final Value<String?> recommended_relay;
  final Value<String?> marker;
  final Value<int> rowid;
  const DbTagCompanion({
    this.note_id = const Value.absent(),
    this.tag_index = const Value.absent(),
    this.type = const Value.absent(),
    this.value = const Value.absent(),
    this.recommended_relay = const Value.absent(),
    this.marker = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DbTagCompanion.insert({
    required String note_id,
    required int tag_index,
    required String type,
    required String value,
    this.recommended_relay = const Value.absent(),
    this.marker = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : note_id = Value(note_id),
        tag_index = Value(tag_index),
        type = Value(type),
        value = Value(value);
  static Insertable<Tag> custom({
    Expression<String>? note_id,
    Expression<int>? tag_index,
    Expression<String>? type,
    Expression<String>? value,
    Expression<String>? recommended_relay,
    Expression<String>? marker,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (note_id != null) 'note_id': note_id,
      if (tag_index != null) 'tag_index': tag_index,
      if (type != null) 'type': type,
      if (value != null) 'value': value,
      if (recommended_relay != null) 'recommended_relay': recommended_relay,
      if (marker != null) 'marker': marker,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DbTagCompanion copyWith(
      {Value<String>? note_id,
      Value<int>? tag_index,
      Value<String>? type,
      Value<String>? value,
      Value<String?>? recommended_relay,
      Value<String?>? marker,
      Value<int>? rowid}) {
    return DbTagCompanion(
      note_id: note_id ?? this.note_id,
      tag_index: tag_index ?? this.tag_index,
      type: type ?? this.type,
      value: value ?? this.value,
      recommended_relay: recommended_relay ?? this.recommended_relay,
      marker: marker ?? this.marker,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (note_id.present) {
      map['note_id'] = Variable<String>(note_id.value);
    }
    if (tag_index.present) {
      map['tag_index'] = Variable<int>(tag_index.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (recommended_relay.present) {
      map['recommended_relay'] = Variable<String>(recommended_relay.value);
    }
    if (marker.present) {
      map['marker'] = Variable<String>(marker.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DbTagCompanion(')
          ..write('note_id: $note_id, ')
          ..write('tag_index: $tag_index, ')
          ..write('type: $type, ')
          ..write('value: $value, ')
          ..write('recommended_relay: $recommended_relay, ')
          ..write('marker: $marker, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$MyDatabase extends GeneratedDatabase {
  _$MyDatabase(QueryExecutor e) : super(e);
  late final $DbNoteTable dbNote = $DbNoteTable(this);
  late final $DbTagTable dbTag = $DbTagTable(this);
  late final NoteDao noteDao = NoteDao(this as MyDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [dbNote, dbTag];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules(
        [
          WritePropagation(
            on: TableUpdateQuery.onTableName('db_note',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('db_tag', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('db_note',
                limitUpdateKind: UpdateKind.update),
            result: [
              TableUpdate('db_tag', kind: UpdateKind.update),
            ],
          ),
        ],
      );
}
