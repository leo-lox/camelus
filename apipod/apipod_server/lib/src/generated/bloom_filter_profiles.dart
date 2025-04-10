/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod/serverpod.dart' as _i1;

abstract class BloomFilterProfile
    implements _i1.TableRow<int>, _i1.ProtocolSerialization {
  BloomFilterProfile._({
    this.id,
    required this.size,
    required this.numHashFunctions,
    required this.bitArray,
    required this.createdAt,
    this.name,
    this.description,
  });

  factory BloomFilterProfile({
    int? id,
    required int size,
    required int numHashFunctions,
    required String bitArray,
    required DateTime createdAt,
    String? name,
    String? description,
  }) = _BloomFilterProfileImpl;

  factory BloomFilterProfile.fromJson(Map<String, dynamic> jsonSerialization) {
    return BloomFilterProfile(
      id: jsonSerialization['id'] as int?,
      size: jsonSerialization['size'] as int,
      numHashFunctions: jsonSerialization['numHashFunctions'] as int,
      bitArray: jsonSerialization['bitArray'] as String,
      createdAt:
          _i1.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
      name: jsonSerialization['name'] as String?,
      description: jsonSerialization['description'] as String?,
    );
  }

  static final t = BloomFilterProfileTable();

  static const db = BloomFilterProfileRepository._();

  @override
  int? id;

  int size;

  int numHashFunctions;

  String bitArray;

  DateTime createdAt;

  String? name;

  String? description;

  @override
  _i1.Table<int> get table => t;

  /// Returns a shallow copy of this [BloomFilterProfile]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  BloomFilterProfile copyWith({
    int? id,
    int? size,
    int? numHashFunctions,
    String? bitArray,
    DateTime? createdAt,
    String? name,
    String? description,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'size': size,
      'numHashFunctions': numHashFunctions,
      'bitArray': bitArray,
      'createdAt': createdAt.toJson(),
      if (name != null) 'name': name,
      if (description != null) 'description': description,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      if (id != null) 'id': id,
      'size': size,
      'numHashFunctions': numHashFunctions,
      'bitArray': bitArray,
      'createdAt': createdAt.toJson(),
      if (name != null) 'name': name,
      if (description != null) 'description': description,
    };
  }

  static BloomFilterProfileInclude include() {
    return BloomFilterProfileInclude._();
  }

  static BloomFilterProfileIncludeList includeList({
    _i1.WhereExpressionBuilder<BloomFilterProfileTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<BloomFilterProfileTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<BloomFilterProfileTable>? orderByList,
    BloomFilterProfileInclude? include,
  }) {
    return BloomFilterProfileIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(BloomFilterProfile.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(BloomFilterProfile.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _BloomFilterProfileImpl extends BloomFilterProfile {
  _BloomFilterProfileImpl({
    int? id,
    required int size,
    required int numHashFunctions,
    required String bitArray,
    required DateTime createdAt,
    String? name,
    String? description,
  }) : super._(
          id: id,
          size: size,
          numHashFunctions: numHashFunctions,
          bitArray: bitArray,
          createdAt: createdAt,
          name: name,
          description: description,
        );

  /// Returns a shallow copy of this [BloomFilterProfile]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  BloomFilterProfile copyWith({
    Object? id = _Undefined,
    int? size,
    int? numHashFunctions,
    String? bitArray,
    DateTime? createdAt,
    Object? name = _Undefined,
    Object? description = _Undefined,
  }) {
    return BloomFilterProfile(
      id: id is int? ? id : this.id,
      size: size ?? this.size,
      numHashFunctions: numHashFunctions ?? this.numHashFunctions,
      bitArray: bitArray ?? this.bitArray,
      createdAt: createdAt ?? this.createdAt,
      name: name is String? ? name : this.name,
      description: description is String? ? description : this.description,
    );
  }
}

class BloomFilterProfileTable extends _i1.Table<int> {
  BloomFilterProfileTable({super.tableRelation})
      : super(tableName: 'bloom_filter_profiles') {
    size = _i1.ColumnInt(
      'size',
      this,
    );
    numHashFunctions = _i1.ColumnInt(
      'numHashFunctions',
      this,
    );
    bitArray = _i1.ColumnString(
      'bitArray',
      this,
    );
    createdAt = _i1.ColumnDateTime(
      'createdAt',
      this,
    );
    name = _i1.ColumnString(
      'name',
      this,
    );
    description = _i1.ColumnString(
      'description',
      this,
    );
  }

  late final _i1.ColumnInt size;

  late final _i1.ColumnInt numHashFunctions;

  late final _i1.ColumnString bitArray;

  late final _i1.ColumnDateTime createdAt;

  late final _i1.ColumnString name;

  late final _i1.ColumnString description;

  @override
  List<_i1.Column> get columns => [
        id,
        size,
        numHashFunctions,
        bitArray,
        createdAt,
        name,
        description,
      ];
}

class BloomFilterProfileInclude extends _i1.IncludeObject {
  BloomFilterProfileInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int> get table => BloomFilterProfile.t;
}

class BloomFilterProfileIncludeList extends _i1.IncludeList {
  BloomFilterProfileIncludeList._({
    _i1.WhereExpressionBuilder<BloomFilterProfileTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(BloomFilterProfile.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int> get table => BloomFilterProfile.t;
}

class BloomFilterProfileRepository {
  const BloomFilterProfileRepository._();

  /// Returns a list of [BloomFilterProfile]s matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order of the items use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// The maximum number of items can be set by [limit]. If no limit is set,
  /// all items matching the query will be returned.
  ///
  /// [offset] defines how many items to skip, after which [limit] (or all)
  /// items are read from the database.
  ///
  /// ```dart
  /// var persons = await Persons.db.find(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.firstName,
  ///   limit: 100,
  /// );
  /// ```
  Future<List<BloomFilterProfile>> find(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<BloomFilterProfileTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<BloomFilterProfileTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<BloomFilterProfileTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.find<BloomFilterProfile>(
      where: where?.call(BloomFilterProfile.t),
      orderBy: orderBy?.call(BloomFilterProfile.t),
      orderByList: orderByList?.call(BloomFilterProfile.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Returns the first matching [BloomFilterProfile] matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// [offset] defines how many items to skip, after which the next one will be picked.
  ///
  /// ```dart
  /// var youngestPerson = await Persons.db.findFirstRow(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.age,
  /// );
  /// ```
  Future<BloomFilterProfile?> findFirstRow(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<BloomFilterProfileTable>? where,
    int? offset,
    _i1.OrderByBuilder<BloomFilterProfileTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<BloomFilterProfileTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.findFirstRow<BloomFilterProfile>(
      where: where?.call(BloomFilterProfile.t),
      orderBy: orderBy?.call(BloomFilterProfile.t),
      orderByList: orderByList?.call(BloomFilterProfile.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Finds a single [BloomFilterProfile] by its [id] or null if no such row exists.
  Future<BloomFilterProfile?> findById(
    _i1.Session session,
    int id, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.findById<BloomFilterProfile>(
      id,
      transaction: transaction,
    );
  }

  /// Inserts all [BloomFilterProfile]s in the list and returns the inserted rows.
  ///
  /// The returned [BloomFilterProfile]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  Future<List<BloomFilterProfile>> insert(
    _i1.Session session,
    List<BloomFilterProfile> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insert<BloomFilterProfile>(
      rows,
      transaction: transaction,
    );
  }

  /// Inserts a single [BloomFilterProfile] and returns the inserted row.
  ///
  /// The returned [BloomFilterProfile] will have its `id` field set.
  Future<BloomFilterProfile> insertRow(
    _i1.Session session,
    BloomFilterProfile row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<BloomFilterProfile>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [BloomFilterProfile]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<BloomFilterProfile>> update(
    _i1.Session session,
    List<BloomFilterProfile> rows, {
    _i1.ColumnSelections<BloomFilterProfileTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<BloomFilterProfile>(
      rows,
      columns: columns?.call(BloomFilterProfile.t),
      transaction: transaction,
    );
  }

  /// Updates a single [BloomFilterProfile]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<BloomFilterProfile> updateRow(
    _i1.Session session,
    BloomFilterProfile row, {
    _i1.ColumnSelections<BloomFilterProfileTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<BloomFilterProfile>(
      row,
      columns: columns?.call(BloomFilterProfile.t),
      transaction: transaction,
    );
  }

  /// Deletes all [BloomFilterProfile]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<BloomFilterProfile>> delete(
    _i1.Session session,
    List<BloomFilterProfile> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<BloomFilterProfile>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [BloomFilterProfile].
  Future<BloomFilterProfile> deleteRow(
    _i1.Session session,
    BloomFilterProfile row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<BloomFilterProfile>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<BloomFilterProfile>> deleteWhere(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<BloomFilterProfileTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<BloomFilterProfile>(
      where: where(BloomFilterProfile.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<BloomFilterProfileTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<BloomFilterProfile>(
      where: where?.call(BloomFilterProfile.t),
      limit: limit,
      transaction: transaction,
    );
  }
}
