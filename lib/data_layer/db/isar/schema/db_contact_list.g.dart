// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'db_contact_list.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetDbContactListCollection on Isar {
  IsarCollection<DbContactList> get dbContactLists => this.collection();
}

const DbContactListSchema = CollectionSchema(
  name: r'DbContactList',
  id: -2180727215935296073,
  properties: {
    r'contactRelays': PropertySchema(
      id: 0,
      name: r'contactRelays',
      type: IsarType.stringList,
    ),
    r'contacts': PropertySchema(
      id: 1,
      name: r'contacts',
      type: IsarType.stringList,
    ),
    r'createdAt': PropertySchema(
      id: 2,
      name: r'createdAt',
      type: IsarType.long,
    ),
    r'followedCommunities': PropertySchema(
      id: 3,
      name: r'followedCommunities',
      type: IsarType.stringList,
    ),
    r'followedEvents': PropertySchema(
      id: 4,
      name: r'followedEvents',
      type: IsarType.stringList,
    ),
    r'followedTags': PropertySchema(
      id: 5,
      name: r'followedTags',
      type: IsarType.stringList,
    ),
    r'loadedTimestamp': PropertySchema(
      id: 6,
      name: r'loadedTimestamp',
      type: IsarType.long,
    ),
    r'petnames': PropertySchema(
      id: 7,
      name: r'petnames',
      type: IsarType.stringList,
    ),
    r'pubKey': PropertySchema(
      id: 8,
      name: r'pubKey',
      type: IsarType.string,
    ),
    r'sources': PropertySchema(
      id: 9,
      name: r'sources',
      type: IsarType.stringList,
    )
  },
  estimateSize: _dbContactListEstimateSize,
  serialize: _dbContactListSerialize,
  deserialize: _dbContactListDeserialize,
  deserializeProp: _dbContactListDeserializeProp,
  idName: r'dbId',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _dbContactListGetId,
  getLinks: _dbContactListGetLinks,
  attach: _dbContactListAttach,
  version: '3.1.0+1',
);

int _dbContactListEstimateSize(
  DbContactList object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.contactRelays.length * 3;
  {
    for (var i = 0; i < object.contactRelays.length; i++) {
      final value = object.contactRelays[i];
      bytesCount += value.length * 3;
    }
  }
  bytesCount += 3 + object.contacts.length * 3;
  {
    for (var i = 0; i < object.contacts.length; i++) {
      final value = object.contacts[i];
      bytesCount += value.length * 3;
    }
  }
  bytesCount += 3 + object.followedCommunities.length * 3;
  {
    for (var i = 0; i < object.followedCommunities.length; i++) {
      final value = object.followedCommunities[i];
      bytesCount += value.length * 3;
    }
  }
  bytesCount += 3 + object.followedEvents.length * 3;
  {
    for (var i = 0; i < object.followedEvents.length; i++) {
      final value = object.followedEvents[i];
      bytesCount += value.length * 3;
    }
  }
  bytesCount += 3 + object.followedTags.length * 3;
  {
    for (var i = 0; i < object.followedTags.length; i++) {
      final value = object.followedTags[i];
      bytesCount += value.length * 3;
    }
  }
  bytesCount += 3 + object.petnames.length * 3;
  {
    for (var i = 0; i < object.petnames.length; i++) {
      final value = object.petnames[i];
      bytesCount += value.length * 3;
    }
  }
  bytesCount += 3 + object.pubKey.length * 3;
  bytesCount += 3 + object.sources.length * 3;
  {
    for (var i = 0; i < object.sources.length; i++) {
      final value = object.sources[i];
      bytesCount += value.length * 3;
    }
  }
  return bytesCount;
}

void _dbContactListSerialize(
  DbContactList object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeStringList(offsets[0], object.contactRelays);
  writer.writeStringList(offsets[1], object.contacts);
  writer.writeLong(offsets[2], object.createdAt);
  writer.writeStringList(offsets[3], object.followedCommunities);
  writer.writeStringList(offsets[4], object.followedEvents);
  writer.writeStringList(offsets[5], object.followedTags);
  writer.writeLong(offsets[6], object.loadedTimestamp);
  writer.writeStringList(offsets[7], object.petnames);
  writer.writeString(offsets[8], object.pubKey);
  writer.writeStringList(offsets[9], object.sources);
}

DbContactList _dbContactListDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = DbContactList(
    contacts: reader.readStringList(offsets[1]) ?? [],
    pubKey: reader.readString(offsets[8]),
  );
  object.contactRelays = reader.readStringList(offsets[0]) ?? [];
  object.createdAt = reader.readLong(offsets[2]);
  object.dbId = id;
  object.followedCommunities = reader.readStringList(offsets[3]) ?? [];
  object.followedEvents = reader.readStringList(offsets[4]) ?? [];
  object.followedTags = reader.readStringList(offsets[5]) ?? [];
  object.loadedTimestamp = reader.readLongOrNull(offsets[6]);
  object.petnames = reader.readStringList(offsets[7]) ?? [];
  object.sources = reader.readStringList(offsets[9]) ?? [];
  return object;
}

P _dbContactListDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringList(offset) ?? []) as P;
    case 1:
      return (reader.readStringList(offset) ?? []) as P;
    case 2:
      return (reader.readLong(offset)) as P;
    case 3:
      return (reader.readStringList(offset) ?? []) as P;
    case 4:
      return (reader.readStringList(offset) ?? []) as P;
    case 5:
      return (reader.readStringList(offset) ?? []) as P;
    case 6:
      return (reader.readLongOrNull(offset)) as P;
    case 7:
      return (reader.readStringList(offset) ?? []) as P;
    case 8:
      return (reader.readString(offset)) as P;
    case 9:
      return (reader.readStringList(offset) ?? []) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _dbContactListGetId(DbContactList object) {
  return object.dbId;
}

List<IsarLinkBase<dynamic>> _dbContactListGetLinks(DbContactList object) {
  return [];
}

void _dbContactListAttach(
    IsarCollection<dynamic> col, Id id, DbContactList object) {
  object.dbId = id;
}

extension DbContactListQueryWhereSort
    on QueryBuilder<DbContactList, DbContactList, QWhere> {
  QueryBuilder<DbContactList, DbContactList, QAfterWhere> anyDbId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension DbContactListQueryWhere
    on QueryBuilder<DbContactList, DbContactList, QWhereClause> {
  QueryBuilder<DbContactList, DbContactList, QAfterWhereClause> dbIdEqualTo(
      Id dbId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: dbId,
        upper: dbId,
      ));
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterWhereClause> dbIdNotEqualTo(
      Id dbId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: dbId, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: dbId, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: dbId, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: dbId, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterWhereClause> dbIdGreaterThan(
      Id dbId,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: dbId, includeLower: include),
      );
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterWhereClause> dbIdLessThan(
      Id dbId,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: dbId, includeUpper: include),
      );
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterWhereClause> dbIdBetween(
    Id lowerDbId,
    Id upperDbId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerDbId,
        includeLower: includeLower,
        upper: upperDbId,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension DbContactListQueryFilter
    on QueryBuilder<DbContactList, DbContactList, QFilterCondition> {
  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      contactRelaysElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'contactRelays',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      contactRelaysElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'contactRelays',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      contactRelaysElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'contactRelays',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      contactRelaysElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'contactRelays',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      contactRelaysElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'contactRelays',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      contactRelaysElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'contactRelays',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      contactRelaysElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'contactRelays',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      contactRelaysElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'contactRelays',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      contactRelaysElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'contactRelays',
        value: '',
      ));
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      contactRelaysElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'contactRelays',
        value: '',
      ));
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      contactRelaysLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'contactRelays',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      contactRelaysIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'contactRelays',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      contactRelaysIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'contactRelays',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      contactRelaysLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'contactRelays',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      contactRelaysLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'contactRelays',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      contactRelaysLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'contactRelays',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      contactsElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'contacts',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      contactsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'contacts',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      contactsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'contacts',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      contactsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'contacts',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      contactsElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'contacts',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      contactsElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'contacts',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      contactsElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'contacts',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      contactsElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'contacts',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      contactsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'contacts',
        value: '',
      ));
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      contactsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'contacts',
        value: '',
      ));
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      contactsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'contacts',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      contactsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'contacts',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      contactsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'contacts',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      contactsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'contacts',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      contactsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'contacts',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      contactsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'contacts',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      createdAtEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      createdAtGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      createdAtLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      createdAtBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition> dbIdEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dbId',
        value: value,
      ));
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      dbIdGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'dbId',
        value: value,
      ));
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      dbIdLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'dbId',
        value: value,
      ));
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition> dbIdBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'dbId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      followedCommunitiesElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'followedCommunities',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      followedCommunitiesElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'followedCommunities',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      followedCommunitiesElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'followedCommunities',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      followedCommunitiesElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'followedCommunities',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      followedCommunitiesElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'followedCommunities',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      followedCommunitiesElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'followedCommunities',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      followedCommunitiesElementContains(String value,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'followedCommunities',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      followedCommunitiesElementMatches(String pattern,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'followedCommunities',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      followedCommunitiesElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'followedCommunities',
        value: '',
      ));
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      followedCommunitiesElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'followedCommunities',
        value: '',
      ));
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      followedCommunitiesLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'followedCommunities',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      followedCommunitiesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'followedCommunities',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      followedCommunitiesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'followedCommunities',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      followedCommunitiesLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'followedCommunities',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      followedCommunitiesLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'followedCommunities',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      followedCommunitiesLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'followedCommunities',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      followedEventsElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'followedEvents',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      followedEventsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'followedEvents',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      followedEventsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'followedEvents',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      followedEventsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'followedEvents',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      followedEventsElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'followedEvents',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      followedEventsElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'followedEvents',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      followedEventsElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'followedEvents',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      followedEventsElementMatches(String pattern,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'followedEvents',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      followedEventsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'followedEvents',
        value: '',
      ));
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      followedEventsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'followedEvents',
        value: '',
      ));
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      followedEventsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'followedEvents',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      followedEventsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'followedEvents',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      followedEventsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'followedEvents',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      followedEventsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'followedEvents',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      followedEventsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'followedEvents',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      followedEventsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'followedEvents',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      followedTagsElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'followedTags',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      followedTagsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'followedTags',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      followedTagsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'followedTags',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      followedTagsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'followedTags',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      followedTagsElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'followedTags',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      followedTagsElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'followedTags',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      followedTagsElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'followedTags',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      followedTagsElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'followedTags',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      followedTagsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'followedTags',
        value: '',
      ));
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      followedTagsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'followedTags',
        value: '',
      ));
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      followedTagsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'followedTags',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      followedTagsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'followedTags',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      followedTagsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'followedTags',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      followedTagsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'followedTags',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      followedTagsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'followedTags',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      followedTagsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'followedTags',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      loadedTimestampIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'loadedTimestamp',
      ));
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      loadedTimestampIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'loadedTimestamp',
      ));
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      loadedTimestampEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'loadedTimestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      loadedTimestampGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'loadedTimestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      loadedTimestampLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'loadedTimestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      loadedTimestampBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'loadedTimestamp',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      petnamesElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'petnames',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      petnamesElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'petnames',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      petnamesElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'petnames',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      petnamesElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'petnames',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      petnamesElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'petnames',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      petnamesElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'petnames',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      petnamesElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'petnames',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      petnamesElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'petnames',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      petnamesElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'petnames',
        value: '',
      ));
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      petnamesElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'petnames',
        value: '',
      ));
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      petnamesLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'petnames',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      petnamesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'petnames',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      petnamesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'petnames',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      petnamesLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'petnames',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      petnamesLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'petnames',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      petnamesLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'petnames',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      pubKeyEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'pubKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      pubKeyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'pubKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      pubKeyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'pubKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      pubKeyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'pubKey',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      pubKeyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'pubKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      pubKeyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'pubKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      pubKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'pubKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      pubKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'pubKey',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      pubKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'pubKey',
        value: '',
      ));
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      pubKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'pubKey',
        value: '',
      ));
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      sourcesElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sources',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      sourcesElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'sources',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      sourcesElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'sources',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      sourcesElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'sources',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      sourcesElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'sources',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      sourcesElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'sources',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      sourcesElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'sources',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      sourcesElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'sources',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      sourcesElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sources',
        value: '',
      ));
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      sourcesElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'sources',
        value: '',
      ));
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      sourcesLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'sources',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      sourcesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'sources',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      sourcesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'sources',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      sourcesLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'sources',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      sourcesLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'sources',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterFilterCondition>
      sourcesLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'sources',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }
}

extension DbContactListQueryObject
    on QueryBuilder<DbContactList, DbContactList, QFilterCondition> {}

extension DbContactListQueryLinks
    on QueryBuilder<DbContactList, DbContactList, QFilterCondition> {}

extension DbContactListQuerySortBy
    on QueryBuilder<DbContactList, DbContactList, QSortBy> {
  QueryBuilder<DbContactList, DbContactList, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterSortBy>
      sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterSortBy>
      sortByLoadedTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'loadedTimestamp', Sort.asc);
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterSortBy>
      sortByLoadedTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'loadedTimestamp', Sort.desc);
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterSortBy> sortByPubKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pubKey', Sort.asc);
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterSortBy> sortByPubKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pubKey', Sort.desc);
    });
  }
}

extension DbContactListQuerySortThenBy
    on QueryBuilder<DbContactList, DbContactList, QSortThenBy> {
  QueryBuilder<DbContactList, DbContactList, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterSortBy>
      thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterSortBy> thenByDbId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dbId', Sort.asc);
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterSortBy> thenByDbIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dbId', Sort.desc);
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterSortBy>
      thenByLoadedTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'loadedTimestamp', Sort.asc);
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterSortBy>
      thenByLoadedTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'loadedTimestamp', Sort.desc);
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterSortBy> thenByPubKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pubKey', Sort.asc);
    });
  }

  QueryBuilder<DbContactList, DbContactList, QAfterSortBy> thenByPubKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pubKey', Sort.desc);
    });
  }
}

extension DbContactListQueryWhereDistinct
    on QueryBuilder<DbContactList, DbContactList, QDistinct> {
  QueryBuilder<DbContactList, DbContactList, QDistinct>
      distinctByContactRelays() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'contactRelays');
    });
  }

  QueryBuilder<DbContactList, DbContactList, QDistinct> distinctByContacts() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'contacts');
    });
  }

  QueryBuilder<DbContactList, DbContactList, QDistinct> distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<DbContactList, DbContactList, QDistinct>
      distinctByFollowedCommunities() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'followedCommunities');
    });
  }

  QueryBuilder<DbContactList, DbContactList, QDistinct>
      distinctByFollowedEvents() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'followedEvents');
    });
  }

  QueryBuilder<DbContactList, DbContactList, QDistinct>
      distinctByFollowedTags() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'followedTags');
    });
  }

  QueryBuilder<DbContactList, DbContactList, QDistinct>
      distinctByLoadedTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'loadedTimestamp');
    });
  }

  QueryBuilder<DbContactList, DbContactList, QDistinct> distinctByPetnames() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'petnames');
    });
  }

  QueryBuilder<DbContactList, DbContactList, QDistinct> distinctByPubKey(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'pubKey', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DbContactList, DbContactList, QDistinct> distinctBySources() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sources');
    });
  }
}

extension DbContactListQueryProperty
    on QueryBuilder<DbContactList, DbContactList, QQueryProperty> {
  QueryBuilder<DbContactList, int, QQueryOperations> dbIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dbId');
    });
  }

  QueryBuilder<DbContactList, List<String>, QQueryOperations>
      contactRelaysProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'contactRelays');
    });
  }

  QueryBuilder<DbContactList, List<String>, QQueryOperations>
      contactsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'contacts');
    });
  }

  QueryBuilder<DbContactList, int, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<DbContactList, List<String>, QQueryOperations>
      followedCommunitiesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'followedCommunities');
    });
  }

  QueryBuilder<DbContactList, List<String>, QQueryOperations>
      followedEventsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'followedEvents');
    });
  }

  QueryBuilder<DbContactList, List<String>, QQueryOperations>
      followedTagsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'followedTags');
    });
  }

  QueryBuilder<DbContactList, int?, QQueryOperations>
      loadedTimestampProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'loadedTimestamp');
    });
  }

  QueryBuilder<DbContactList, List<String>, QQueryOperations>
      petnamesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'petnames');
    });
  }

  QueryBuilder<DbContactList, String, QQueryOperations> pubKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'pubKey');
    });
  }

  QueryBuilder<DbContactList, List<String>, QQueryOperations>
      sourcesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sources');
    });
  }
}
