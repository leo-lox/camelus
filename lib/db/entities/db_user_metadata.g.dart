// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'db_user_metadata.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetDbUserMetadataCollection on Isar {
  IsarCollection<DbUserMetadata> get dbUserMetadatas => this.collection();
}

const DbUserMetadataSchema = CollectionSchema(
  name: r'DbUserMetadata',
  id: -3148165729401085605,
  properties: {
    r'about': PropertySchema(
      id: 0,
      name: r'about',
      type: IsarType.string,
    ),
    r'banner': PropertySchema(
      id: 1,
      name: r'banner',
      type: IsarType.string,
    ),
    r'last_fetch': PropertySchema(
      id: 2,
      name: r'last_fetch',
      type: IsarType.long,
    ),
    r'lud06': PropertySchema(
      id: 3,
      name: r'lud06',
      type: IsarType.string,
    ),
    r'lud16': PropertySchema(
      id: 4,
      name: r'lud16',
      type: IsarType.string,
    ),
    r'name': PropertySchema(
      id: 5,
      name: r'name',
      type: IsarType.string,
    ),
    r'nip05': PropertySchema(
      id: 6,
      name: r'nip05',
      type: IsarType.string,
    ),
    r'nostr_id': PropertySchema(
      id: 7,
      name: r'nostr_id',
      type: IsarType.string,
    ),
    r'picture': PropertySchema(
      id: 8,
      name: r'picture',
      type: IsarType.string,
    ),
    r'pubkey': PropertySchema(
      id: 9,
      name: r'pubkey',
      type: IsarType.string,
    ),
    r'website': PropertySchema(
      id: 10,
      name: r'website',
      type: IsarType.string,
    )
  },
  estimateSize: _dbUserMetadataEstimateSize,
  serialize: _dbUserMetadataSerialize,
  deserialize: _dbUserMetadataDeserialize,
  deserializeProp: _dbUserMetadataDeserializeProp,
  idName: r'id',
  indexes: {
    r'nostr_id': IndexSchema(
      id: 3163867815246860709,
      name: r'nostr_id',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'nostr_id',
          type: IndexType.value,
          caseSensitive: true,
        )
      ],
    ),
    r'pubkey': IndexSchema(
      id: -5440107494565194882,
      name: r'pubkey',
      unique: true,
      replace: false,
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
  embeddedSchemas: {},
  getId: _dbUserMetadataGetId,
  getLinks: _dbUserMetadataGetLinks,
  attach: _dbUserMetadataAttach,
  version: '3.1.0+1',
);

int _dbUserMetadataEstimateSize(
  DbUserMetadata object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.about;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.banner;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.lud06;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.lud16;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.name;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.nip05;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.nostr_id.length * 3;
  {
    final value = object.picture;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.pubkey.length * 3;
  {
    final value = object.website;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _dbUserMetadataSerialize(
  DbUserMetadata object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.about);
  writer.writeString(offsets[1], object.banner);
  writer.writeLong(offsets[2], object.last_fetch);
  writer.writeString(offsets[3], object.lud06);
  writer.writeString(offsets[4], object.lud16);
  writer.writeString(offsets[5], object.name);
  writer.writeString(offsets[6], object.nip05);
  writer.writeString(offsets[7], object.nostr_id);
  writer.writeString(offsets[8], object.picture);
  writer.writeString(offsets[9], object.pubkey);
  writer.writeString(offsets[10], object.website);
}

DbUserMetadata _dbUserMetadataDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = DbUserMetadata(
    about: reader.readStringOrNull(offsets[0]),
    banner: reader.readStringOrNull(offsets[1]),
    last_fetch: reader.readLong(offsets[2]),
    lud06: reader.readStringOrNull(offsets[3]),
    lud16: reader.readStringOrNull(offsets[4]),
    name: reader.readStringOrNull(offsets[5]),
    nip05: reader.readStringOrNull(offsets[6]),
    nostr_id: reader.readString(offsets[7]),
    picture: reader.readStringOrNull(offsets[8]),
    pubkey: reader.readString(offsets[9]),
    website: reader.readStringOrNull(offsets[10]),
  );
  object.id = id;
  return object;
}

P _dbUserMetadataDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readLong(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readStringOrNull(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    case 8:
      return (reader.readStringOrNull(offset)) as P;
    case 9:
      return (reader.readString(offset)) as P;
    case 10:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _dbUserMetadataGetId(DbUserMetadata object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _dbUserMetadataGetLinks(DbUserMetadata object) {
  return [];
}

void _dbUserMetadataAttach(
    IsarCollection<dynamic> col, Id id, DbUserMetadata object) {
  object.id = id;
}

extension DbUserMetadataByIndex on IsarCollection<DbUserMetadata> {
  Future<DbUserMetadata?> getByNostr_id(String nostr_id) {
    return getByIndex(r'nostr_id', [nostr_id]);
  }

  DbUserMetadata? getByNostr_idSync(String nostr_id) {
    return getByIndexSync(r'nostr_id', [nostr_id]);
  }

  Future<bool> deleteByNostr_id(String nostr_id) {
    return deleteByIndex(r'nostr_id', [nostr_id]);
  }

  bool deleteByNostr_idSync(String nostr_id) {
    return deleteByIndexSync(r'nostr_id', [nostr_id]);
  }

  Future<List<DbUserMetadata?>> getAllByNostr_id(List<String> nostr_idValues) {
    final values = nostr_idValues.map((e) => [e]).toList();
    return getAllByIndex(r'nostr_id', values);
  }

  List<DbUserMetadata?> getAllByNostr_idSync(List<String> nostr_idValues) {
    final values = nostr_idValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'nostr_id', values);
  }

  Future<int> deleteAllByNostr_id(List<String> nostr_idValues) {
    final values = nostr_idValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'nostr_id', values);
  }

  int deleteAllByNostr_idSync(List<String> nostr_idValues) {
    final values = nostr_idValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'nostr_id', values);
  }

  Future<Id> putByNostr_id(DbUserMetadata object) {
    return putByIndex(r'nostr_id', object);
  }

  Id putByNostr_idSync(DbUserMetadata object, {bool saveLinks = true}) {
    return putByIndexSync(r'nostr_id', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByNostr_id(List<DbUserMetadata> objects) {
    return putAllByIndex(r'nostr_id', objects);
  }

  List<Id> putAllByNostr_idSync(List<DbUserMetadata> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'nostr_id', objects, saveLinks: saveLinks);
  }

  Future<DbUserMetadata?> getByPubkey(String pubkey) {
    return getByIndex(r'pubkey', [pubkey]);
  }

  DbUserMetadata? getByPubkeySync(String pubkey) {
    return getByIndexSync(r'pubkey', [pubkey]);
  }

  Future<bool> deleteByPubkey(String pubkey) {
    return deleteByIndex(r'pubkey', [pubkey]);
  }

  bool deleteByPubkeySync(String pubkey) {
    return deleteByIndexSync(r'pubkey', [pubkey]);
  }

  Future<List<DbUserMetadata?>> getAllByPubkey(List<String> pubkeyValues) {
    final values = pubkeyValues.map((e) => [e]).toList();
    return getAllByIndex(r'pubkey', values);
  }

  List<DbUserMetadata?> getAllByPubkeySync(List<String> pubkeyValues) {
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

  Future<Id> putByPubkey(DbUserMetadata object) {
    return putByIndex(r'pubkey', object);
  }

  Id putByPubkeySync(DbUserMetadata object, {bool saveLinks = true}) {
    return putByIndexSync(r'pubkey', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByPubkey(List<DbUserMetadata> objects) {
    return putAllByIndex(r'pubkey', objects);
  }

  List<Id> putAllByPubkeySync(List<DbUserMetadata> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'pubkey', objects, saveLinks: saveLinks);
  }
}

extension DbUserMetadataQueryWhereSort
    on QueryBuilder<DbUserMetadata, DbUserMetadata, QWhere> {
  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterWhere> anyNostr_id() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'nostr_id'),
      );
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterWhere> anyPubkey() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'pubkey'),
      );
    });
  }
}

extension DbUserMetadataQueryWhere
    on QueryBuilder<DbUserMetadata, DbUserMetadata, QWhereClause> {
  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterWhereClause> idNotEqualTo(
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

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterWhereClause> idBetween(
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

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterWhereClause>
      nostr_idEqualTo(String nostr_id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'nostr_id',
        value: [nostr_id],
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterWhereClause>
      nostr_idNotEqualTo(String nostr_id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'nostr_id',
              lower: [],
              upper: [nostr_id],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'nostr_id',
              lower: [nostr_id],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'nostr_id',
              lower: [nostr_id],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'nostr_id',
              lower: [],
              upper: [nostr_id],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterWhereClause>
      nostr_idGreaterThan(
    String nostr_id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'nostr_id',
        lower: [nostr_id],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterWhereClause>
      nostr_idLessThan(
    String nostr_id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'nostr_id',
        lower: [],
        upper: [nostr_id],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterWhereClause>
      nostr_idBetween(
    String lowerNostr_id,
    String upperNostr_id, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'nostr_id',
        lower: [lowerNostr_id],
        includeLower: includeLower,
        upper: [upperNostr_id],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterWhereClause>
      nostr_idStartsWith(String Nostr_idPrefix) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'nostr_id',
        lower: [Nostr_idPrefix],
        upper: ['$Nostr_idPrefix\u{FFFFF}'],
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterWhereClause>
      nostr_idIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'nostr_id',
        value: [''],
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterWhereClause>
      nostr_idIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.lessThan(
              indexName: r'nostr_id',
              upper: [''],
            ))
            .addWhereClause(IndexWhereClause.greaterThan(
              indexName: r'nostr_id',
              lower: [''],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.greaterThan(
              indexName: r'nostr_id',
              lower: [''],
            ))
            .addWhereClause(IndexWhereClause.lessThan(
              indexName: r'nostr_id',
              upper: [''],
            ));
      }
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterWhereClause> pubkeyEqualTo(
      String pubkey) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'pubkey',
        value: [pubkey],
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterWhereClause>
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

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterWhereClause>
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

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterWhereClause>
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

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterWhereClause> pubkeyBetween(
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

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterWhereClause>
      pubkeyStartsWith(String PubkeyPrefix) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'pubkey',
        lower: [PubkeyPrefix],
        upper: ['$PubkeyPrefix\u{FFFFF}'],
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterWhereClause>
      pubkeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'pubkey',
        value: [''],
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterWhereClause>
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

extension DbUserMetadataQueryFilter
    on QueryBuilder<DbUserMetadata, DbUserMetadata, QFilterCondition> {
  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
      aboutIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'about',
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
      aboutIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'about',
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
      aboutEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'about',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
      aboutGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'about',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
      aboutLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'about',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
      aboutBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'about',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
      aboutStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'about',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
      aboutEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'about',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
      aboutContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'about',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
      aboutMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'about',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
      aboutIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'about',
        value: '',
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
      aboutIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'about',
        value: '',
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
      bannerIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'banner',
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
      bannerIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'banner',
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
      bannerEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'banner',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
      bannerGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'banner',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
      bannerLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'banner',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
      bannerBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'banner',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
      bannerStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'banner',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
      bannerEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'banner',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
      bannerContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'banner',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
      bannerMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'banner',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
      bannerIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'banner',
        value: '',
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
      bannerIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'banner',
        value: '',
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
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

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
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

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition> idBetween(
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

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
      last_fetchEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'last_fetch',
        value: value,
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
      last_fetchGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'last_fetch',
        value: value,
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
      last_fetchLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'last_fetch',
        value: value,
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
      last_fetchBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'last_fetch',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
      lud06IsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lud06',
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
      lud06IsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lud06',
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
      lud06EqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lud06',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
      lud06GreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lud06',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
      lud06LessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lud06',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
      lud06Between(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lud06',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
      lud06StartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'lud06',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
      lud06EndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'lud06',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
      lud06Contains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'lud06',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
      lud06Matches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'lud06',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
      lud06IsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lud06',
        value: '',
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
      lud06IsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'lud06',
        value: '',
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
      lud16IsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lud16',
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
      lud16IsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lud16',
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
      lud16EqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lud16',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
      lud16GreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lud16',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
      lud16LessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lud16',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
      lud16Between(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lud16',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
      lud16StartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'lud16',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
      lud16EndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'lud16',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
      lud16Contains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'lud16',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
      lud16Matches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'lud16',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
      lud16IsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lud16',
        value: '',
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
      lud16IsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'lud16',
        value: '',
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
      nameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'name',
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
      nameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'name',
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
      nameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
      nameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
      nameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
      nameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'name',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
      nameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
      nameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
      nameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
      nameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'name',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
      nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
      nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
      nip05IsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'nip05',
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
      nip05IsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'nip05',
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
      nip05EqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'nip05',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
      nip05GreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'nip05',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
      nip05LessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'nip05',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
      nip05Between(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'nip05',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
      nip05StartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'nip05',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
      nip05EndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'nip05',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
      nip05Contains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'nip05',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
      nip05Matches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'nip05',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
      nip05IsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'nip05',
        value: '',
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
      nip05IsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'nip05',
        value: '',
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
      nostr_idEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'nostr_id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
      nostr_idGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'nostr_id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
      nostr_idLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'nostr_id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
      nostr_idBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'nostr_id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
      nostr_idStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'nostr_id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
      nostr_idEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'nostr_id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
      nostr_idContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'nostr_id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
      nostr_idMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'nostr_id',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
      nostr_idIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'nostr_id',
        value: '',
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
      nostr_idIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'nostr_id',
        value: '',
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
      pictureIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'picture',
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
      pictureIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'picture',
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
      pictureEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'picture',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
      pictureGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'picture',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
      pictureLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'picture',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
      pictureBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'picture',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
      pictureStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'picture',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
      pictureEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'picture',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
      pictureContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'picture',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
      pictureMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'picture',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
      pictureIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'picture',
        value: '',
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
      pictureIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'picture',
        value: '',
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
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

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
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

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
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

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
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

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
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

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
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

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
      pubkeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'pubkey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
      pubkeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'pubkey',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
      pubkeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'pubkey',
        value: '',
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
      pubkeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'pubkey',
        value: '',
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
      websiteIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'website',
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
      websiteIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'website',
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
      websiteEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'website',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
      websiteGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'website',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
      websiteLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'website',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
      websiteBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'website',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
      websiteStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'website',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
      websiteEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'website',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
      websiteContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'website',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
      websiteMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'website',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
      websiteIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'website',
        value: '',
      ));
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterFilterCondition>
      websiteIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'website',
        value: '',
      ));
    });
  }
}

extension DbUserMetadataQueryObject
    on QueryBuilder<DbUserMetadata, DbUserMetadata, QFilterCondition> {}

extension DbUserMetadataQueryLinks
    on QueryBuilder<DbUserMetadata, DbUserMetadata, QFilterCondition> {}

extension DbUserMetadataQuerySortBy
    on QueryBuilder<DbUserMetadata, DbUserMetadata, QSortBy> {
  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterSortBy> sortByAbout() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'about', Sort.asc);
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterSortBy> sortByAboutDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'about', Sort.desc);
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterSortBy> sortByBanner() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'banner', Sort.asc);
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterSortBy>
      sortByBannerDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'banner', Sort.desc);
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterSortBy>
      sortByLast_fetch() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'last_fetch', Sort.asc);
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterSortBy>
      sortByLast_fetchDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'last_fetch', Sort.desc);
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterSortBy> sortByLud06() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lud06', Sort.asc);
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterSortBy> sortByLud06Desc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lud06', Sort.desc);
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterSortBy> sortByLud16() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lud16', Sort.asc);
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterSortBy> sortByLud16Desc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lud16', Sort.desc);
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterSortBy> sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterSortBy> sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterSortBy> sortByNip05() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nip05', Sort.asc);
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterSortBy> sortByNip05Desc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nip05', Sort.desc);
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterSortBy> sortByNostr_id() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nostr_id', Sort.asc);
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterSortBy>
      sortByNostr_idDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nostr_id', Sort.desc);
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterSortBy> sortByPicture() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'picture', Sort.asc);
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterSortBy>
      sortByPictureDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'picture', Sort.desc);
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterSortBy> sortByPubkey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pubkey', Sort.asc);
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterSortBy>
      sortByPubkeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pubkey', Sort.desc);
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterSortBy> sortByWebsite() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'website', Sort.asc);
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterSortBy>
      sortByWebsiteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'website', Sort.desc);
    });
  }
}

extension DbUserMetadataQuerySortThenBy
    on QueryBuilder<DbUserMetadata, DbUserMetadata, QSortThenBy> {
  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterSortBy> thenByAbout() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'about', Sort.asc);
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterSortBy> thenByAboutDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'about', Sort.desc);
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterSortBy> thenByBanner() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'banner', Sort.asc);
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterSortBy>
      thenByBannerDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'banner', Sort.desc);
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterSortBy>
      thenByLast_fetch() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'last_fetch', Sort.asc);
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterSortBy>
      thenByLast_fetchDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'last_fetch', Sort.desc);
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterSortBy> thenByLud06() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lud06', Sort.asc);
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterSortBy> thenByLud06Desc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lud06', Sort.desc);
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterSortBy> thenByLud16() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lud16', Sort.asc);
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterSortBy> thenByLud16Desc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lud16', Sort.desc);
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterSortBy> thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterSortBy> thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterSortBy> thenByNip05() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nip05', Sort.asc);
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterSortBy> thenByNip05Desc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nip05', Sort.desc);
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterSortBy> thenByNostr_id() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nostr_id', Sort.asc);
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterSortBy>
      thenByNostr_idDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nostr_id', Sort.desc);
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterSortBy> thenByPicture() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'picture', Sort.asc);
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterSortBy>
      thenByPictureDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'picture', Sort.desc);
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterSortBy> thenByPubkey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pubkey', Sort.asc);
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterSortBy>
      thenByPubkeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pubkey', Sort.desc);
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterSortBy> thenByWebsite() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'website', Sort.asc);
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QAfterSortBy>
      thenByWebsiteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'website', Sort.desc);
    });
  }
}

extension DbUserMetadataQueryWhereDistinct
    on QueryBuilder<DbUserMetadata, DbUserMetadata, QDistinct> {
  QueryBuilder<DbUserMetadata, DbUserMetadata, QDistinct> distinctByAbout(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'about', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QDistinct> distinctByBanner(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'banner', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QDistinct>
      distinctByLast_fetch() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'last_fetch');
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QDistinct> distinctByLud06(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lud06', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QDistinct> distinctByLud16(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lud16', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QDistinct> distinctByName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QDistinct> distinctByNip05(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'nip05', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QDistinct> distinctByNostr_id(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'nostr_id', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QDistinct> distinctByPicture(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'picture', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QDistinct> distinctByPubkey(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'pubkey', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DbUserMetadata, DbUserMetadata, QDistinct> distinctByWebsite(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'website', caseSensitive: caseSensitive);
    });
  }
}

extension DbUserMetadataQueryProperty
    on QueryBuilder<DbUserMetadata, DbUserMetadata, QQueryProperty> {
  QueryBuilder<DbUserMetadata, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<DbUserMetadata, String?, QQueryOperations> aboutProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'about');
    });
  }

  QueryBuilder<DbUserMetadata, String?, QQueryOperations> bannerProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'banner');
    });
  }

  QueryBuilder<DbUserMetadata, int, QQueryOperations> last_fetchProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'last_fetch');
    });
  }

  QueryBuilder<DbUserMetadata, String?, QQueryOperations> lud06Property() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lud06');
    });
  }

  QueryBuilder<DbUserMetadata, String?, QQueryOperations> lud16Property() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lud16');
    });
  }

  QueryBuilder<DbUserMetadata, String?, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }

  QueryBuilder<DbUserMetadata, String?, QQueryOperations> nip05Property() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'nip05');
    });
  }

  QueryBuilder<DbUserMetadata, String, QQueryOperations> nostr_idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'nostr_id');
    });
  }

  QueryBuilder<DbUserMetadata, String?, QQueryOperations> pictureProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'picture');
    });
  }

  QueryBuilder<DbUserMetadata, String, QQueryOperations> pubkeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'pubkey');
    });
  }

  QueryBuilder<DbUserMetadata, String?, QQueryOperations> websiteProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'website');
    });
  }
}
