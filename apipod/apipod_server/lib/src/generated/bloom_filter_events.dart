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

abstract class BloomFilterEvent
    implements _i1.TableRow, _i1.ProtocolSerialization {
  BloomFilterEvent._({
    this.id,
    required this.size,
    required this.numHashFunctions,
    required this.bitArray,
    required this.createdAt,
    this.name,
    this.description,
  });

  factory BloomFilterEvent({
    int? id,
    required int size,
    required int numHashFunctions,
    required String bitArray,
    required DateTime createdAt,
    String? name,
    String? description,
  }) = _BloomFilterEventImpl;

  factory BloomFilterEvent.fromJson(Map<String, dynamic> jsonSerialization) {
    return BloomFilterEvent(
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

  static final t = BloomFilterEventTable();

  static const db = BloomFilterEventRepository._();

  @override
  int? id;

  int size;

  int numHashFunctions;

  String bitArray;

  DateTime createdAt;

  String? name;

  String? description;

  @override
  _i1.Table get table => t;

  /// Returns a shallow copy of this [BloomFilterEvent]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  BloomFilterEvent copyWith({
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

  static BloomFilterEventInclude include() {
    return BloomFilterEventInclude._();
  }

  static BloomFilterEventIncludeList includeList({
    _i1.WhereExpressionBuilder<BloomFilterEventTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<BloomFilterEventTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<BloomFilterEventTable>? orderByList,
    BloomFilterEventInclude? include,
  }) {
    return BloomFilterEventIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(BloomFilterEvent.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(BloomFilterEvent.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _BloomFilterEventImpl extends BloomFilterEvent {
  _BloomFilterEventImpl({
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

  /// Returns a shallow copy of this [BloomFilterEvent]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  BloomFilterEvent copyWith({
    Object? id = _Undefined,
    int? size,
    int? numHashFunctions,
    String? bitArray,
    DateTime? createdAt,
    Object? name = _Undefined,
    Object? description = _Undefined,
  }) {
    return BloomFilterEvent(
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

class BloomFilterEventTable extends _i1.Table {
  BloomFilterEventTable({super.tableRelation})
      : super(tableName: 'bloom_filter_events') {
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

class BloomFilterEventInclude extends _i1.IncludeObject {
  BloomFilterEventInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table get table => BloomFilterEvent.t;
}

class BloomFilterEventIncludeList extends _i1.IncludeList {
  BloomFilterEventIncludeList._({
    _i1.WhereExpressionBuilder<BloomFilterEventTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(BloomFilterEvent.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table get table => BloomFilterEvent.t;
}

class BloomFilterEventRepository {
  const BloomFilterEventRepository._();

  /// Returns a list of [BloomFilterEvent]s matching the given query parameters.
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
  Future<List<BloomFilterEvent>> find(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<BloomFilterEventTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<BloomFilterEventTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<BloomFilterEventTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.find<BloomFilterEvent>(
      where: where?.call(BloomFilterEvent.t),
      orderBy: orderBy?.call(BloomFilterEvent.t),
      orderByList: orderByList?.call(BloomFilterEvent.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Returns the first matching [BloomFilterEvent] matching the given query parameters.
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
  Future<BloomFilterEvent?> findFirstRow(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<BloomFilterEventTable>? where,
    int? offset,
    _i1.OrderByBuilder<BloomFilterEventTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<BloomFilterEventTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.findFirstRow<BloomFilterEvent>(
      where: where?.call(BloomFilterEvent.t),
      orderBy: orderBy?.call(BloomFilterEvent.t),
      orderByList: orderByList?.call(BloomFilterEvent.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Finds a single [BloomFilterEvent] by its [id] or null if no such row exists.
  Future<BloomFilterEvent?> findById(
    _i1.Session session,
    int id, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.findById<BloomFilterEvent>(
      id,
      transaction: transaction,
    );
  }

  /// Inserts all [BloomFilterEvent]s in the list and returns the inserted rows.
  ///
  /// The returned [BloomFilterEvent]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  Future<List<BloomFilterEvent>> insert(
    _i1.Session session,
    List<BloomFilterEvent> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insert<BloomFilterEvent>(
      rows,
      transaction: transaction,
    );
  }

  /// Inserts a single [BloomFilterEvent] and returns the inserted row.
  ///
  /// The returned [BloomFilterEvent] will have its `id` field set.
  Future<BloomFilterEvent> insertRow(
    _i1.Session session,
    BloomFilterEvent row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<BloomFilterEvent>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [BloomFilterEvent]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<BloomFilterEvent>> update(
    _i1.Session session,
    List<BloomFilterEvent> rows, {
    _i1.ColumnSelections<BloomFilterEventTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<BloomFilterEvent>(
      rows,
      columns: columns?.call(BloomFilterEvent.t),
      transaction: transaction,
    );
  }

  /// Updates a single [BloomFilterEvent]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<BloomFilterEvent> updateRow(
    _i1.Session session,
    BloomFilterEvent row, {
    _i1.ColumnSelections<BloomFilterEventTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<BloomFilterEvent>(
      row,
      columns: columns?.call(BloomFilterEvent.t),
      transaction: transaction,
    );
  }

  /// Deletes all [BloomFilterEvent]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<BloomFilterEvent>> delete(
    _i1.Session session,
    List<BloomFilterEvent> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<BloomFilterEvent>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [BloomFilterEvent].
  Future<BloomFilterEvent> deleteRow(
    _i1.Session session,
    BloomFilterEvent row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<BloomFilterEvent>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<BloomFilterEvent>> deleteWhere(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<BloomFilterEventTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<BloomFilterEvent>(
      where: where(BloomFilterEvent.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<BloomFilterEventTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<BloomFilterEvent>(
      where: where?.call(BloomFilterEvent.t),
      limit: limit,
      transaction: transaction,
    );
  }
}
