// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'db_settings.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetDbSettingsCollection on Isar {
  IsarCollection<DbSettings> get dbSettings => this.collection();
}

const DbSettingsSchema = CollectionSchema(
  name: r'DbSettings',
  id: 1097994837175927760,
  properties: {
    r'manualRelays': PropertySchema(
      id: 0,
      name: r'manualRelays',
      type: IsarType.objectList,
      target: r'DbManualRelay',
    )
  },
  estimateSize: _dbSettingsEstimateSize,
  serialize: _dbSettingsSerialize,
  deserialize: _dbSettingsDeserialize,
  deserializeProp: _dbSettingsDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {r'DbManualRelay': DbManualRelaySchema},
  getId: _dbSettingsGetId,
  getLinks: _dbSettingsGetLinks,
  attach: _dbSettingsAttach,
  version: '3.1.0+1',
);

int _dbSettingsEstimateSize(
  DbSettings object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final list = object.manualRelays;
    if (list != null) {
      bytesCount += 3 + list.length * 3;
      {
        final offsets = allOffsets[DbManualRelay]!;
        for (var i = 0; i < list.length; i++) {
          final value = list[i];
          bytesCount +=
              DbManualRelaySchema.estimateSize(value, offsets, allOffsets);
        }
      }
    }
  }
  return bytesCount;
}

void _dbSettingsSerialize(
  DbSettings object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeObjectList<DbManualRelay>(
    offsets[0],
    allOffsets,
    DbManualRelaySchema.serialize,
    object.manualRelays,
  );
}

DbSettings _dbSettingsDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = DbSettings();
  object.id = id;
  object.manualRelays = reader.readObjectList<DbManualRelay>(
    offsets[0],
    DbManualRelaySchema.deserialize,
    allOffsets,
    DbManualRelay(),
  );
  return object;
}

P _dbSettingsDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readObjectList<DbManualRelay>(
        offset,
        DbManualRelaySchema.deserialize,
        allOffsets,
        DbManualRelay(),
      )) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _dbSettingsGetId(DbSettings object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _dbSettingsGetLinks(DbSettings object) {
  return [];
}

void _dbSettingsAttach(IsarCollection<dynamic> col, Id id, DbSettings object) {
  object.id = id;
}

extension DbSettingsQueryWhereSort
    on QueryBuilder<DbSettings, DbSettings, QWhere> {
  QueryBuilder<DbSettings, DbSettings, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension DbSettingsQueryWhere
    on QueryBuilder<DbSettings, DbSettings, QWhereClause> {
  QueryBuilder<DbSettings, DbSettings, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<DbSettings, DbSettings, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<DbSettings, DbSettings, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<DbSettings, DbSettings, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<DbSettings, DbSettings, QAfterWhereClause> idBetween(
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
}

extension DbSettingsQueryFilter
    on QueryBuilder<DbSettings, DbSettings, QFilterCondition> {
  QueryBuilder<DbSettings, DbSettings, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<DbSettings, DbSettings, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<DbSettings, DbSettings, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<DbSettings, DbSettings, QAfterFilterCondition> idBetween(
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

  QueryBuilder<DbSettings, DbSettings, QAfterFilterCondition>
      manualRelaysIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'manualRelays',
      ));
    });
  }

  QueryBuilder<DbSettings, DbSettings, QAfterFilterCondition>
      manualRelaysIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'manualRelays',
      ));
    });
  }

  QueryBuilder<DbSettings, DbSettings, QAfterFilterCondition>
      manualRelaysLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'manualRelays',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<DbSettings, DbSettings, QAfterFilterCondition>
      manualRelaysIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'manualRelays',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<DbSettings, DbSettings, QAfterFilterCondition>
      manualRelaysIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'manualRelays',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<DbSettings, DbSettings, QAfterFilterCondition>
      manualRelaysLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'manualRelays',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<DbSettings, DbSettings, QAfterFilterCondition>
      manualRelaysLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'manualRelays',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<DbSettings, DbSettings, QAfterFilterCondition>
      manualRelaysLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'manualRelays',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }
}

extension DbSettingsQueryObject
    on QueryBuilder<DbSettings, DbSettings, QFilterCondition> {
  QueryBuilder<DbSettings, DbSettings, QAfterFilterCondition>
      manualRelaysElement(FilterQuery<DbManualRelay> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'manualRelays');
    });
  }
}

extension DbSettingsQueryLinks
    on QueryBuilder<DbSettings, DbSettings, QFilterCondition> {}

extension DbSettingsQuerySortBy
    on QueryBuilder<DbSettings, DbSettings, QSortBy> {}

extension DbSettingsQuerySortThenBy
    on QueryBuilder<DbSettings, DbSettings, QSortThenBy> {
  QueryBuilder<DbSettings, DbSettings, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<DbSettings, DbSettings, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }
}

extension DbSettingsQueryWhereDistinct
    on QueryBuilder<DbSettings, DbSettings, QDistinct> {}

extension DbSettingsQueryProperty
    on QueryBuilder<DbSettings, DbSettings, QQueryProperty> {
  QueryBuilder<DbSettings, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<DbSettings, List<DbManualRelay>?, QQueryOperations>
      manualRelaysProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'manualRelays');
    });
  }
}

// **************************************************************************
// IsarEmbeddedGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const DbManualRelaySchema = Schema(
  name: r'DbManualRelay',
  id: -4712046699654995771,
  properties: {
    r'read': PropertySchema(
      id: 0,
      name: r'read',
      type: IsarType.bool,
    ),
    r'url': PropertySchema(
      id: 1,
      name: r'url',
      type: IsarType.string,
    ),
    r'write': PropertySchema(
      id: 2,
      name: r'write',
      type: IsarType.bool,
    )
  },
  estimateSize: _dbManualRelayEstimateSize,
  serialize: _dbManualRelaySerialize,
  deserialize: _dbManualRelayDeserialize,
  deserializeProp: _dbManualRelayDeserializeProp,
);

int _dbManualRelayEstimateSize(
  DbManualRelay object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.url;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _dbManualRelaySerialize(
  DbManualRelay object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeBool(offsets[0], object.read);
  writer.writeString(offsets[1], object.url);
  writer.writeBool(offsets[2], object.write);
}

DbManualRelay _dbManualRelayDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = DbManualRelay(
    read: reader.readBoolOrNull(offsets[0]),
    url: reader.readStringOrNull(offsets[1]),
    write: reader.readBoolOrNull(offsets[2]),
  );
  return object;
}

P _dbManualRelayDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readBoolOrNull(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readBoolOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension DbManualRelayQueryFilter
    on QueryBuilder<DbManualRelay, DbManualRelay, QFilterCondition> {
  QueryBuilder<DbManualRelay, DbManualRelay, QAfterFilterCondition>
      readIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'read',
      ));
    });
  }

  QueryBuilder<DbManualRelay, DbManualRelay, QAfterFilterCondition>
      readIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'read',
      ));
    });
  }

  QueryBuilder<DbManualRelay, DbManualRelay, QAfterFilterCondition> readEqualTo(
      bool? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'read',
        value: value,
      ));
    });
  }

  QueryBuilder<DbManualRelay, DbManualRelay, QAfterFilterCondition>
      urlIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'url',
      ));
    });
  }

  QueryBuilder<DbManualRelay, DbManualRelay, QAfterFilterCondition>
      urlIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'url',
      ));
    });
  }

  QueryBuilder<DbManualRelay, DbManualRelay, QAfterFilterCondition> urlEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'url',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbManualRelay, DbManualRelay, QAfterFilterCondition>
      urlGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'url',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbManualRelay, DbManualRelay, QAfterFilterCondition> urlLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'url',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbManualRelay, DbManualRelay, QAfterFilterCondition> urlBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'url',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbManualRelay, DbManualRelay, QAfterFilterCondition>
      urlStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'url',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbManualRelay, DbManualRelay, QAfterFilterCondition> urlEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'url',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbManualRelay, DbManualRelay, QAfterFilterCondition> urlContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'url',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbManualRelay, DbManualRelay, QAfterFilterCondition> urlMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'url',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbManualRelay, DbManualRelay, QAfterFilterCondition>
      urlIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'url',
        value: '',
      ));
    });
  }

  QueryBuilder<DbManualRelay, DbManualRelay, QAfterFilterCondition>
      urlIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'url',
        value: '',
      ));
    });
  }

  QueryBuilder<DbManualRelay, DbManualRelay, QAfterFilterCondition>
      writeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'write',
      ));
    });
  }

  QueryBuilder<DbManualRelay, DbManualRelay, QAfterFilterCondition>
      writeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'write',
      ));
    });
  }

  QueryBuilder<DbManualRelay, DbManualRelay, QAfterFilterCondition>
      writeEqualTo(bool? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'write',
        value: value,
      ));
    });
  }
}

extension DbManualRelayQueryObject
    on QueryBuilder<DbManualRelay, DbManualRelay, QFilterCondition> {}
