// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'db_relay_tracker.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetDbRelayTrackerCollection on Isar {
  IsarCollection<DbRelayTracker> get dbRelayTrackers => this.collection();
}

const DbRelayTrackerSchema = CollectionSchema(
  name: r'DbRelayTracker',
  id: 7024473109955153198,
  properties: {
    r'pubkey': PropertySchema(
      id: 0,
      name: r'pubkey',
      type: IsarType.string,
    ),
    r'relays': PropertySchema(
      id: 1,
      name: r'relays',
      type: IsarType.objectList,
      target: r'DbRelayTrackerRelay',
    )
  },
  estimateSize: _dbRelayTrackerEstimateSize,
  serialize: _dbRelayTrackerSerialize,
  deserialize: _dbRelayTrackerDeserialize,
  deserializeProp: _dbRelayTrackerDeserializeProp,
  idName: r'id',
  indexes: {
    r'pubkey': IndexSchema(
      id: -5440107494565194882,
      name: r'pubkey',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'pubkey',
          type: IndexType.value,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {r'DbRelayTrackerRelay': DbRelayTrackerRelaySchema},
  getId: _dbRelayTrackerGetId,
  getLinks: _dbRelayTrackerGetLinks,
  attach: _dbRelayTrackerAttach,
  version: '3.1.0+1',
);

int _dbRelayTrackerEstimateSize(
  DbRelayTracker object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.pubkey.length * 3;
  bytesCount += 3 + object.relays.length * 3;
  {
    final offsets = allOffsets[DbRelayTrackerRelay]!;
    for (var i = 0; i < object.relays.length; i++) {
      final value = object.relays[i];
      bytesCount +=
          DbRelayTrackerRelaySchema.estimateSize(value, offsets, allOffsets);
    }
  }
  return bytesCount;
}

void _dbRelayTrackerSerialize(
  DbRelayTracker object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.pubkey);
  writer.writeObjectList<DbRelayTrackerRelay>(
    offsets[1],
    allOffsets,
    DbRelayTrackerRelaySchema.serialize,
    object.relays,
  );
}

DbRelayTracker _dbRelayTrackerDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = DbRelayTracker(
    pubkey: reader.readString(offsets[0]),
    relays: reader.readObjectList<DbRelayTrackerRelay>(
          offsets[1],
          DbRelayTrackerRelaySchema.deserialize,
          allOffsets,
          DbRelayTrackerRelay(),
        ) ??
        const [],
  );
  object.id = id;
  return object;
}

P _dbRelayTrackerDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readObjectList<DbRelayTrackerRelay>(
            offset,
            DbRelayTrackerRelaySchema.deserialize,
            allOffsets,
            DbRelayTrackerRelay(),
          ) ??
          const []) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _dbRelayTrackerGetId(DbRelayTracker object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _dbRelayTrackerGetLinks(DbRelayTracker object) {
  return [];
}

void _dbRelayTrackerAttach(
    IsarCollection<dynamic> col, Id id, DbRelayTracker object) {
  object.id = id;
}

extension DbRelayTrackerByIndex on IsarCollection<DbRelayTracker> {
  Future<DbRelayTracker?> getByPubkey(String pubkey) {
    return getByIndex(r'pubkey', [pubkey]);
  }

  DbRelayTracker? getByPubkeySync(String pubkey) {
    return getByIndexSync(r'pubkey', [pubkey]);
  }

  Future<bool> deleteByPubkey(String pubkey) {
    return deleteByIndex(r'pubkey', [pubkey]);
  }

  bool deleteByPubkeySync(String pubkey) {
    return deleteByIndexSync(r'pubkey', [pubkey]);
  }

  Future<List<DbRelayTracker?>> getAllByPubkey(List<String> pubkeyValues) {
    final values = pubkeyValues.map((e) => [e]).toList();
    return getAllByIndex(r'pubkey', values);
  }

  List<DbRelayTracker?> getAllByPubkeySync(List<String> pubkeyValues) {
    final values = pubkeyValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'pubkey', values);
  }

  Future<int> deleteAllByPubkey(List<String> pubkeyValues) {
    final values = pubkeyValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'pubkey', values);
  }

  int deleteAllByPubkeySync(List<String> pubkeyValues) {
    final values = pubkeyValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'pubkey', values);
  }

  Future<Id> putByPubkey(DbRelayTracker object) {
    return putByIndex(r'pubkey', object);
  }

  Id putByPubkeySync(DbRelayTracker object, {bool saveLinks = true}) {
    return putByIndexSync(r'pubkey', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByPubkey(List<DbRelayTracker> objects) {
    return putAllByIndex(r'pubkey', objects);
  }

  List<Id> putAllByPubkeySync(List<DbRelayTracker> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'pubkey', objects, saveLinks: saveLinks);
  }
}

extension DbRelayTrackerQueryWhereSort
    on QueryBuilder<DbRelayTracker, DbRelayTracker, QWhere> {
  QueryBuilder<DbRelayTracker, DbRelayTracker, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<DbRelayTracker, DbRelayTracker, QAfterWhere> anyPubkey() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'pubkey'),
      );
    });
  }
}

extension DbRelayTrackerQueryWhere
    on QueryBuilder<DbRelayTracker, DbRelayTracker, QWhereClause> {
  QueryBuilder<DbRelayTracker, DbRelayTracker, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<DbRelayTracker, DbRelayTracker, QAfterWhereClause> idNotEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<DbRelayTracker, DbRelayTracker, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<DbRelayTracker, DbRelayTracker, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<DbRelayTracker, DbRelayTracker, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DbRelayTracker, DbRelayTracker, QAfterWhereClause> pubkeyEqualTo(
      String pubkey) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'pubkey',
        value: [pubkey],
      ));
    });
  }

  QueryBuilder<DbRelayTracker, DbRelayTracker, QAfterWhereClause>
      pubkeyNotEqualTo(String pubkey) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'pubkey',
              lower: [],
              upper: [pubkey],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'pubkey',
              lower: [pubkey],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'pubkey',
              lower: [pubkey],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'pubkey',
              lower: [],
              upper: [pubkey],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<DbRelayTracker, DbRelayTracker, QAfterWhereClause>
      pubkeyGreaterThan(
    String pubkey, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'pubkey',
        lower: [pubkey],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<DbRelayTracker, DbRelayTracker, QAfterWhereClause>
      pubkeyLessThan(
    String pubkey, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'pubkey',
        lower: [],
        upper: [pubkey],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<DbRelayTracker, DbRelayTracker, QAfterWhereClause> pubkeyBetween(
    String lowerPubkey,
    String upperPubkey, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'pubkey',
        lower: [lowerPubkey],
        includeLower: includeLower,
        upper: [upperPubkey],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DbRelayTracker, DbRelayTracker, QAfterWhereClause>
      pubkeyStartsWith(String PubkeyPrefix) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'pubkey',
        lower: [PubkeyPrefix],
        upper: ['$PubkeyPrefix\u{FFFFF}'],
      ));
    });
  }

  QueryBuilder<DbRelayTracker, DbRelayTracker, QAfterWhereClause>
      pubkeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'pubkey',
        value: [''],
      ));
    });
  }

  QueryBuilder<DbRelayTracker, DbRelayTracker, QAfterWhereClause>
      pubkeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.lessThan(
              indexName: r'pubkey',
              upper: [''],
            ))
            .addWhereClause(IndexWhereClause.greaterThan(
              indexName: r'pubkey',
              lower: [''],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.greaterThan(
              indexName: r'pubkey',
              lower: [''],
            ))
            .addWhereClause(IndexWhereClause.lessThan(
              indexName: r'pubkey',
              upper: [''],
            ));
      }
    });
  }
}

extension DbRelayTrackerQueryFilter
    on QueryBuilder<DbRelayTracker, DbRelayTracker, QFilterCondition> {
  QueryBuilder<DbRelayTracker, DbRelayTracker, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<DbRelayTracker, DbRelayTracker, QAfterFilterCondition>
      idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<DbRelayTracker, DbRelayTracker, QAfterFilterCondition>
      idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<DbRelayTracker, DbRelayTracker, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DbRelayTracker, DbRelayTracker, QAfterFilterCondition>
      pubkeyEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'pubkey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbRelayTracker, DbRelayTracker, QAfterFilterCondition>
      pubkeyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'pubkey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbRelayTracker, DbRelayTracker, QAfterFilterCondition>
      pubkeyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'pubkey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbRelayTracker, DbRelayTracker, QAfterFilterCondition>
      pubkeyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'pubkey',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbRelayTracker, DbRelayTracker, QAfterFilterCondition>
      pubkeyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'pubkey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbRelayTracker, DbRelayTracker, QAfterFilterCondition>
      pubkeyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'pubkey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbRelayTracker, DbRelayTracker, QAfterFilterCondition>
      pubkeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'pubkey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbRelayTracker, DbRelayTracker, QAfterFilterCondition>
      pubkeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'pubkey',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbRelayTracker, DbRelayTracker, QAfterFilterCondition>
      pubkeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'pubkey',
        value: '',
      ));
    });
  }

  QueryBuilder<DbRelayTracker, DbRelayTracker, QAfterFilterCondition>
      pubkeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'pubkey',
        value: '',
      ));
    });
  }

  QueryBuilder<DbRelayTracker, DbRelayTracker, QAfterFilterCondition>
      relaysLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'relays',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<DbRelayTracker, DbRelayTracker, QAfterFilterCondition>
      relaysIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'relays',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<DbRelayTracker, DbRelayTracker, QAfterFilterCondition>
      relaysIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'relays',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<DbRelayTracker, DbRelayTracker, QAfterFilterCondition>
      relaysLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'relays',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<DbRelayTracker, DbRelayTracker, QAfterFilterCondition>
      relaysLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'relays',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<DbRelayTracker, DbRelayTracker, QAfterFilterCondition>
      relaysLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'relays',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }
}

extension DbRelayTrackerQueryObject
    on QueryBuilder<DbRelayTracker, DbRelayTracker, QFilterCondition> {
  QueryBuilder<DbRelayTracker, DbRelayTracker, QAfterFilterCondition>
      relaysElement(FilterQuery<DbRelayTrackerRelay> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'relays');
    });
  }
}

extension DbRelayTrackerQueryLinks
    on QueryBuilder<DbRelayTracker, DbRelayTracker, QFilterCondition> {}

extension DbRelayTrackerQuerySortBy
    on QueryBuilder<DbRelayTracker, DbRelayTracker, QSortBy> {
  QueryBuilder<DbRelayTracker, DbRelayTracker, QAfterSortBy> sortByPubkey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pubkey', Sort.asc);
    });
  }

  QueryBuilder<DbRelayTracker, DbRelayTracker, QAfterSortBy>
      sortByPubkeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pubkey', Sort.desc);
    });
  }
}

extension DbRelayTrackerQuerySortThenBy
    on QueryBuilder<DbRelayTracker, DbRelayTracker, QSortThenBy> {
  QueryBuilder<DbRelayTracker, DbRelayTracker, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<DbRelayTracker, DbRelayTracker, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<DbRelayTracker, DbRelayTracker, QAfterSortBy> thenByPubkey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pubkey', Sort.asc);
    });
  }

  QueryBuilder<DbRelayTracker, DbRelayTracker, QAfterSortBy>
      thenByPubkeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pubkey', Sort.desc);
    });
  }
}

extension DbRelayTrackerQueryWhereDistinct
    on QueryBuilder<DbRelayTracker, DbRelayTracker, QDistinct> {
  QueryBuilder<DbRelayTracker, DbRelayTracker, QDistinct> distinctByPubkey(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'pubkey', caseSensitive: caseSensitive);
    });
  }
}

extension DbRelayTrackerQueryProperty
    on QueryBuilder<DbRelayTracker, DbRelayTracker, QQueryProperty> {
  QueryBuilder<DbRelayTracker, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<DbRelayTracker, String, QQueryOperations> pubkeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'pubkey');
    });
  }

  QueryBuilder<DbRelayTracker, List<DbRelayTrackerRelay>, QQueryOperations>
      relaysProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'relays');
    });
  }
}

// **************************************************************************
// IsarEmbeddedGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const DbRelayTrackerRelaySchema = Schema(
  name: r'DbRelayTrackerRelay',
  id: -3746857561852798498,
  properties: {
    r'lastFetched': PropertySchema(
      id: 0,
      name: r'lastFetched',
      type: IsarType.long,
    ),
    r'lastSuggestedKind3': PropertySchema(
      id: 1,
      name: r'lastSuggestedKind3',
      type: IsarType.long,
    ),
    r'lastSuggestedNip05': PropertySchema(
      id: 2,
      name: r'lastSuggestedNip05',
      type: IsarType.long,
    ),
    r'lastSuggestedTag': PropertySchema(
      id: 3,
      name: r'lastSuggestedTag',
      type: IsarType.long,
    ),
    r'relayUrl': PropertySchema(
      id: 4,
      name: r'relayUrl',
      type: IsarType.string,
    )
  },
  estimateSize: _dbRelayTrackerRelayEstimateSize,
  serialize: _dbRelayTrackerRelaySerialize,
  deserialize: _dbRelayTrackerRelayDeserialize,
  deserializeProp: _dbRelayTrackerRelayDeserializeProp,
);

int _dbRelayTrackerRelayEstimateSize(
  DbRelayTrackerRelay object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.relayUrl;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _dbRelayTrackerRelaySerialize(
  DbRelayTrackerRelay object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.lastFetched);
  writer.writeLong(offsets[1], object.lastSuggestedKind3);
  writer.writeLong(offsets[2], object.lastSuggestedNip05);
  writer.writeLong(offsets[3], object.lastSuggestedTag);
  writer.writeString(offsets[4], object.relayUrl);
}

DbRelayTrackerRelay _dbRelayTrackerRelayDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = DbRelayTrackerRelay(
    lastSuggestedKind3: reader.readLongOrNull(offsets[1]),
    lastSuggestedNip05: reader.readLongOrNull(offsets[2]),
    lastSuggestedTag: reader.readLongOrNull(offsets[3]),
    relayUrl: reader.readStringOrNull(offsets[4]),
  );
  object.lastFetched = reader.readLongOrNull(offsets[0]);
  return object;
}

P _dbRelayTrackerRelayDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLongOrNull(offset)) as P;
    case 1:
      return (reader.readLongOrNull(offset)) as P;
    case 2:
      return (reader.readLongOrNull(offset)) as P;
    case 3:
      return (reader.readLongOrNull(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension DbRelayTrackerRelayQueryFilter on QueryBuilder<DbRelayTrackerRelay,
    DbRelayTrackerRelay, QFilterCondition> {
  QueryBuilder<DbRelayTrackerRelay, DbRelayTrackerRelay, QAfterFilterCondition>
      lastFetchedIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lastFetched',
      ));
    });
  }

  QueryBuilder<DbRelayTrackerRelay, DbRelayTrackerRelay, QAfterFilterCondition>
      lastFetchedIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lastFetched',
      ));
    });
  }

  QueryBuilder<DbRelayTrackerRelay, DbRelayTrackerRelay, QAfterFilterCondition>
      lastFetchedEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastFetched',
        value: value,
      ));
    });
  }

  QueryBuilder<DbRelayTrackerRelay, DbRelayTrackerRelay, QAfterFilterCondition>
      lastFetchedGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastFetched',
        value: value,
      ));
    });
  }

  QueryBuilder<DbRelayTrackerRelay, DbRelayTrackerRelay, QAfterFilterCondition>
      lastFetchedLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastFetched',
        value: value,
      ));
    });
  }

  QueryBuilder<DbRelayTrackerRelay, DbRelayTrackerRelay, QAfterFilterCondition>
      lastFetchedBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastFetched',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DbRelayTrackerRelay, DbRelayTrackerRelay, QAfterFilterCondition>
      lastSuggestedKind3IsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lastSuggestedKind3',
      ));
    });
  }

  QueryBuilder<DbRelayTrackerRelay, DbRelayTrackerRelay, QAfterFilterCondition>
      lastSuggestedKind3IsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lastSuggestedKind3',
      ));
    });
  }

  QueryBuilder<DbRelayTrackerRelay, DbRelayTrackerRelay, QAfterFilterCondition>
      lastSuggestedKind3EqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastSuggestedKind3',
        value: value,
      ));
    });
  }

  QueryBuilder<DbRelayTrackerRelay, DbRelayTrackerRelay, QAfterFilterCondition>
      lastSuggestedKind3GreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastSuggestedKind3',
        value: value,
      ));
    });
  }

  QueryBuilder<DbRelayTrackerRelay, DbRelayTrackerRelay, QAfterFilterCondition>
      lastSuggestedKind3LessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastSuggestedKind3',
        value: value,
      ));
    });
  }

  QueryBuilder<DbRelayTrackerRelay, DbRelayTrackerRelay, QAfterFilterCondition>
      lastSuggestedKind3Between(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastSuggestedKind3',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DbRelayTrackerRelay, DbRelayTrackerRelay, QAfterFilterCondition>
      lastSuggestedNip05IsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lastSuggestedNip05',
      ));
    });
  }

  QueryBuilder<DbRelayTrackerRelay, DbRelayTrackerRelay, QAfterFilterCondition>
      lastSuggestedNip05IsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lastSuggestedNip05',
      ));
    });
  }

  QueryBuilder<DbRelayTrackerRelay, DbRelayTrackerRelay, QAfterFilterCondition>
      lastSuggestedNip05EqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastSuggestedNip05',
        value: value,
      ));
    });
  }

  QueryBuilder<DbRelayTrackerRelay, DbRelayTrackerRelay, QAfterFilterCondition>
      lastSuggestedNip05GreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastSuggestedNip05',
        value: value,
      ));
    });
  }

  QueryBuilder<DbRelayTrackerRelay, DbRelayTrackerRelay, QAfterFilterCondition>
      lastSuggestedNip05LessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastSuggestedNip05',
        value: value,
      ));
    });
  }

  QueryBuilder<DbRelayTrackerRelay, DbRelayTrackerRelay, QAfterFilterCondition>
      lastSuggestedNip05Between(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastSuggestedNip05',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DbRelayTrackerRelay, DbRelayTrackerRelay, QAfterFilterCondition>
      lastSuggestedTagIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lastSuggestedTag',
      ));
    });
  }

  QueryBuilder<DbRelayTrackerRelay, DbRelayTrackerRelay, QAfterFilterCondition>
      lastSuggestedTagIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lastSuggestedTag',
      ));
    });
  }

  QueryBuilder<DbRelayTrackerRelay, DbRelayTrackerRelay, QAfterFilterCondition>
      lastSuggestedTagEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastSuggestedTag',
        value: value,
      ));
    });
  }

  QueryBuilder<DbRelayTrackerRelay, DbRelayTrackerRelay, QAfterFilterCondition>
      lastSuggestedTagGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastSuggestedTag',
        value: value,
      ));
    });
  }

  QueryBuilder<DbRelayTrackerRelay, DbRelayTrackerRelay, QAfterFilterCondition>
      lastSuggestedTagLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastSuggestedTag',
        value: value,
      ));
    });
  }

  QueryBuilder<DbRelayTrackerRelay, DbRelayTrackerRelay, QAfterFilterCondition>
      lastSuggestedTagBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastSuggestedTag',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DbRelayTrackerRelay, DbRelayTrackerRelay, QAfterFilterCondition>
      relayUrlIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'relayUrl',
      ));
    });
  }

  QueryBuilder<DbRelayTrackerRelay, DbRelayTrackerRelay, QAfterFilterCondition>
      relayUrlIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'relayUrl',
      ));
    });
  }

  QueryBuilder<DbRelayTrackerRelay, DbRelayTrackerRelay, QAfterFilterCondition>
      relayUrlEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'relayUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbRelayTrackerRelay, DbRelayTrackerRelay, QAfterFilterCondition>
      relayUrlGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'relayUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbRelayTrackerRelay, DbRelayTrackerRelay, QAfterFilterCondition>
      relayUrlLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'relayUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbRelayTrackerRelay, DbRelayTrackerRelay, QAfterFilterCondition>
      relayUrlBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'relayUrl',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbRelayTrackerRelay, DbRelayTrackerRelay, QAfterFilterCondition>
      relayUrlStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'relayUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbRelayTrackerRelay, DbRelayTrackerRelay, QAfterFilterCondition>
      relayUrlEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'relayUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbRelayTrackerRelay, DbRelayTrackerRelay, QAfterFilterCondition>
      relayUrlContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'relayUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbRelayTrackerRelay, DbRelayTrackerRelay, QAfterFilterCondition>
      relayUrlMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'relayUrl',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbRelayTrackerRelay, DbRelayTrackerRelay, QAfterFilterCondition>
      relayUrlIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'relayUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<DbRelayTrackerRelay, DbRelayTrackerRelay, QAfterFilterCondition>
      relayUrlIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'relayUrl',
        value: '',
      ));
    });
  }
}

extension DbRelayTrackerRelayQueryObject on QueryBuilder<DbRelayTrackerRelay,
    DbRelayTrackerRelay, QFilterCondition> {}
