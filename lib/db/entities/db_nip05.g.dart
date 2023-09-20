// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'db_nip05.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetDbNip05Collection on Isar {
  IsarCollection<DbNip05> get dbNip05s => this.collection();
}

const DbNip05Schema = CollectionSchema(
  name: r'DbNip05',
  id: 6470192042308633429,
  properties: {
    r'lastCheck': PropertySchema(
      id: 0,
      name: r'lastCheck',
      type: IsarType.long,
    ),
    r'nip05': PropertySchema(
      id: 1,
      name: r'nip05',
      type: IsarType.string,
    ),
    r'relays': PropertySchema(
      id: 2,
      name: r'relays',
      type: IsarType.stringList,
    ),
    r'valid': PropertySchema(
      id: 3,
      name: r'valid',
      type: IsarType.bool,
    )
  },
  estimateSize: _dbNip05EstimateSize,
  serialize: _dbNip05Serialize,
  deserialize: _dbNip05Deserialize,
  deserializeProp: _dbNip05DeserializeProp,
  idName: r'id',
  indexes: {
    r'nip05': IndexSchema(
      id: 8096380905031948307,
      name: r'nip05',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'nip05',
          type: IndexType.value,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _dbNip05GetId,
  getLinks: _dbNip05GetLinks,
  attach: _dbNip05Attach,
  version: '3.1.0+1',
);

int _dbNip05EstimateSize(
  DbNip05 object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.nip05.length * 3;
  {
    final list = object.relays;
    if (list != null) {
      bytesCount += 3 + list.length * 3;
      {
        for (var i = 0; i < list.length; i++) {
          final value = list[i];
          bytesCount += value.length * 3;
        }
      }
    }
  }
  return bytesCount;
}

void _dbNip05Serialize(
  DbNip05 object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.lastCheck);
  writer.writeString(offsets[1], object.nip05);
  writer.writeStringList(offsets[2], object.relays);
  writer.writeBool(offsets[3], object.valid);
}

DbNip05 _dbNip05Deserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = DbNip05(
    lastCheck: reader.readLongOrNull(offsets[0]),
    nip05: reader.readString(offsets[1]),
    relays: reader.readStringList(offsets[2]),
    valid: reader.readBoolOrNull(offsets[3]) ?? false,
  );
  object.id = id;
  return object;
}

P _dbNip05DeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLongOrNull(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readStringList(offset)) as P;
    case 3:
      return (reader.readBoolOrNull(offset) ?? false) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _dbNip05GetId(DbNip05 object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _dbNip05GetLinks(DbNip05 object) {
  return [];
}

void _dbNip05Attach(IsarCollection<dynamic> col, Id id, DbNip05 object) {
  object.id = id;
}

extension DbNip05ByIndex on IsarCollection<DbNip05> {
  Future<DbNip05?> getByNip05(String nip05) {
    return getByIndex(r'nip05', [nip05]);
  }

  DbNip05? getByNip05Sync(String nip05) {
    return getByIndexSync(r'nip05', [nip05]);
  }

  Future<bool> deleteByNip05(String nip05) {
    return deleteByIndex(r'nip05', [nip05]);
  }

  bool deleteByNip05Sync(String nip05) {
    return deleteByIndexSync(r'nip05', [nip05]);
  }

  Future<List<DbNip05?>> getAllByNip05(List<String> nip05Values) {
    final values = nip05Values.map((e) => [e]).toList();
    return getAllByIndex(r'nip05', values);
  }

  List<DbNip05?> getAllByNip05Sync(List<String> nip05Values) {
    final values = nip05Values.map((e) => [e]).toList();
    return getAllByIndexSync(r'nip05', values);
  }

  Future<int> deleteAllByNip05(List<String> nip05Values) {
    final values = nip05Values.map((e) => [e]).toList();
    return deleteAllByIndex(r'nip05', values);
  }

  int deleteAllByNip05Sync(List<String> nip05Values) {
    final values = nip05Values.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'nip05', values);
  }

  Future<Id> putByNip05(DbNip05 object) {
    return putByIndex(r'nip05', object);
  }

  Id putByNip05Sync(DbNip05 object, {bool saveLinks = true}) {
    return putByIndexSync(r'nip05', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByNip05(List<DbNip05> objects) {
    return putAllByIndex(r'nip05', objects);
  }

  List<Id> putAllByNip05Sync(List<DbNip05> objects, {bool saveLinks = true}) {
    return putAllByIndexSync(r'nip05', objects, saveLinks: saveLinks);
  }
}

extension DbNip05QueryWhereSort on QueryBuilder<DbNip05, DbNip05, QWhere> {
  QueryBuilder<DbNip05, DbNip05, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<DbNip05, DbNip05, QAfterWhere> anyNip05() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'nip05'),
      );
    });
  }
}

extension DbNip05QueryWhere on QueryBuilder<DbNip05, DbNip05, QWhereClause> {
  QueryBuilder<DbNip05, DbNip05, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<DbNip05, DbNip05, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<DbNip05, DbNip05, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<DbNip05, DbNip05, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<DbNip05, DbNip05, QAfterWhereClause> idBetween(
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

  QueryBuilder<DbNip05, DbNip05, QAfterWhereClause> nip05EqualTo(String nip05) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'nip05',
        value: [nip05],
      ));
    });
  }

  QueryBuilder<DbNip05, DbNip05, QAfterWhereClause> nip05NotEqualTo(
      String nip05) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'nip05',
              lower: [],
              upper: [nip05],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'nip05',
              lower: [nip05],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'nip05',
              lower: [nip05],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'nip05',
              lower: [],
              upper: [nip05],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<DbNip05, DbNip05, QAfterWhereClause> nip05GreaterThan(
    String nip05, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'nip05',
        lower: [nip05],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<DbNip05, DbNip05, QAfterWhereClause> nip05LessThan(
    String nip05, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'nip05',
        lower: [],
        upper: [nip05],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<DbNip05, DbNip05, QAfterWhereClause> nip05Between(
    String lowerNip05,
    String upperNip05, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'nip05',
        lower: [lowerNip05],
        includeLower: includeLower,
        upper: [upperNip05],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DbNip05, DbNip05, QAfterWhereClause> nip05StartsWith(
      String Nip05Prefix) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'nip05',
        lower: [Nip05Prefix],
        upper: ['$Nip05Prefix\u{FFFFF}'],
      ));
    });
  }

  QueryBuilder<DbNip05, DbNip05, QAfterWhereClause> nip05IsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'nip05',
        value: [''],
      ));
    });
  }

  QueryBuilder<DbNip05, DbNip05, QAfterWhereClause> nip05IsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.lessThan(
              indexName: r'nip05',
              upper: [''],
            ))
            .addWhereClause(IndexWhereClause.greaterThan(
              indexName: r'nip05',
              lower: [''],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.greaterThan(
              indexName: r'nip05',
              lower: [''],
            ))
            .addWhereClause(IndexWhereClause.lessThan(
              indexName: r'nip05',
              upper: [''],
            ));
      }
    });
  }
}

extension DbNip05QueryFilter
    on QueryBuilder<DbNip05, DbNip05, QFilterCondition> {
  QueryBuilder<DbNip05, DbNip05, QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<DbNip05, DbNip05, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<DbNip05, DbNip05, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<DbNip05, DbNip05, QAfterFilterCondition> idBetween(
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

  QueryBuilder<DbNip05, DbNip05, QAfterFilterCondition> lastCheckIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lastCheck',
      ));
    });
  }

  QueryBuilder<DbNip05, DbNip05, QAfterFilterCondition> lastCheckIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lastCheck',
      ));
    });
  }

  QueryBuilder<DbNip05, DbNip05, QAfterFilterCondition> lastCheckEqualTo(
      int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastCheck',
        value: value,
      ));
    });
  }

  QueryBuilder<DbNip05, DbNip05, QAfterFilterCondition> lastCheckGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastCheck',
        value: value,
      ));
    });
  }

  QueryBuilder<DbNip05, DbNip05, QAfterFilterCondition> lastCheckLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastCheck',
        value: value,
      ));
    });
  }

  QueryBuilder<DbNip05, DbNip05, QAfterFilterCondition> lastCheckBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastCheck',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DbNip05, DbNip05, QAfterFilterCondition> nip05EqualTo(
    String value, {
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

  QueryBuilder<DbNip05, DbNip05, QAfterFilterCondition> nip05GreaterThan(
    String value, {
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

  QueryBuilder<DbNip05, DbNip05, QAfterFilterCondition> nip05LessThan(
    String value, {
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

  QueryBuilder<DbNip05, DbNip05, QAfterFilterCondition> nip05Between(
    String lower,
    String upper, {
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

  QueryBuilder<DbNip05, DbNip05, QAfterFilterCondition> nip05StartsWith(
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

  QueryBuilder<DbNip05, DbNip05, QAfterFilterCondition> nip05EndsWith(
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

  QueryBuilder<DbNip05, DbNip05, QAfterFilterCondition> nip05Contains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'nip05',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbNip05, DbNip05, QAfterFilterCondition> nip05Matches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'nip05',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbNip05, DbNip05, QAfterFilterCondition> nip05IsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'nip05',
        value: '',
      ));
    });
  }

  QueryBuilder<DbNip05, DbNip05, QAfterFilterCondition> nip05IsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'nip05',
        value: '',
      ));
    });
  }

  QueryBuilder<DbNip05, DbNip05, QAfterFilterCondition> relaysIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'relays',
      ));
    });
  }

  QueryBuilder<DbNip05, DbNip05, QAfterFilterCondition> relaysIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'relays',
      ));
    });
  }

  QueryBuilder<DbNip05, DbNip05, QAfterFilterCondition> relaysElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'relays',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbNip05, DbNip05, QAfterFilterCondition>
      relaysElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'relays',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbNip05, DbNip05, QAfterFilterCondition> relaysElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'relays',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbNip05, DbNip05, QAfterFilterCondition> relaysElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'relays',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbNip05, DbNip05, QAfterFilterCondition> relaysElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'relays',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbNip05, DbNip05, QAfterFilterCondition> relaysElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'relays',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbNip05, DbNip05, QAfterFilterCondition> relaysElementContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'relays',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbNip05, DbNip05, QAfterFilterCondition> relaysElementMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'relays',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbNip05, DbNip05, QAfterFilterCondition> relaysElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'relays',
        value: '',
      ));
    });
  }

  QueryBuilder<DbNip05, DbNip05, QAfterFilterCondition>
      relaysElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'relays',
        value: '',
      ));
    });
  }

  QueryBuilder<DbNip05, DbNip05, QAfterFilterCondition> relaysLengthEqualTo(
      int length) {
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

  QueryBuilder<DbNip05, DbNip05, QAfterFilterCondition> relaysIsEmpty() {
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

  QueryBuilder<DbNip05, DbNip05, QAfterFilterCondition> relaysIsNotEmpty() {
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

  QueryBuilder<DbNip05, DbNip05, QAfterFilterCondition> relaysLengthLessThan(
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

  QueryBuilder<DbNip05, DbNip05, QAfterFilterCondition> relaysLengthGreaterThan(
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

  QueryBuilder<DbNip05, DbNip05, QAfterFilterCondition> relaysLengthBetween(
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

  QueryBuilder<DbNip05, DbNip05, QAfterFilterCondition> validEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'valid',
        value: value,
      ));
    });
  }
}

extension DbNip05QueryObject
    on QueryBuilder<DbNip05, DbNip05, QFilterCondition> {}

extension DbNip05QueryLinks
    on QueryBuilder<DbNip05, DbNip05, QFilterCondition> {}

extension DbNip05QuerySortBy on QueryBuilder<DbNip05, DbNip05, QSortBy> {
  QueryBuilder<DbNip05, DbNip05, QAfterSortBy> sortByLastCheck() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastCheck', Sort.asc);
    });
  }

  QueryBuilder<DbNip05, DbNip05, QAfterSortBy> sortByLastCheckDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastCheck', Sort.desc);
    });
  }

  QueryBuilder<DbNip05, DbNip05, QAfterSortBy> sortByNip05() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nip05', Sort.asc);
    });
  }

  QueryBuilder<DbNip05, DbNip05, QAfterSortBy> sortByNip05Desc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nip05', Sort.desc);
    });
  }

  QueryBuilder<DbNip05, DbNip05, QAfterSortBy> sortByValid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'valid', Sort.asc);
    });
  }

  QueryBuilder<DbNip05, DbNip05, QAfterSortBy> sortByValidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'valid', Sort.desc);
    });
  }
}

extension DbNip05QuerySortThenBy
    on QueryBuilder<DbNip05, DbNip05, QSortThenBy> {
  QueryBuilder<DbNip05, DbNip05, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<DbNip05, DbNip05, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<DbNip05, DbNip05, QAfterSortBy> thenByLastCheck() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastCheck', Sort.asc);
    });
  }

  QueryBuilder<DbNip05, DbNip05, QAfterSortBy> thenByLastCheckDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastCheck', Sort.desc);
    });
  }

  QueryBuilder<DbNip05, DbNip05, QAfterSortBy> thenByNip05() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nip05', Sort.asc);
    });
  }

  QueryBuilder<DbNip05, DbNip05, QAfterSortBy> thenByNip05Desc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nip05', Sort.desc);
    });
  }

  QueryBuilder<DbNip05, DbNip05, QAfterSortBy> thenByValid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'valid', Sort.asc);
    });
  }

  QueryBuilder<DbNip05, DbNip05, QAfterSortBy> thenByValidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'valid', Sort.desc);
    });
  }
}

extension DbNip05QueryWhereDistinct
    on QueryBuilder<DbNip05, DbNip05, QDistinct> {
  QueryBuilder<DbNip05, DbNip05, QDistinct> distinctByLastCheck() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastCheck');
    });
  }

  QueryBuilder<DbNip05, DbNip05, QDistinct> distinctByNip05(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'nip05', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DbNip05, DbNip05, QDistinct> distinctByRelays() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'relays');
    });
  }

  QueryBuilder<DbNip05, DbNip05, QDistinct> distinctByValid() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'valid');
    });
  }
}

extension DbNip05QueryProperty
    on QueryBuilder<DbNip05, DbNip05, QQueryProperty> {
  QueryBuilder<DbNip05, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<DbNip05, int?, QQueryOperations> lastCheckProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastCheck');
    });
  }

  QueryBuilder<DbNip05, String, QQueryOperations> nip05Property() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'nip05');
    });
  }

  QueryBuilder<DbNip05, List<String>?, QQueryOperations> relaysProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'relays');
    });
  }

  QueryBuilder<DbNip05, bool, QQueryOperations> validProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'valid');
    });
  }
}
