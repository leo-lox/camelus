/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod/serverpod.dart' as _i1;

abstract class TrendsSnapshot
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  TrendsSnapshot._({
    this.id,
    required this.createdAt,
    required this.interval,
    required this.payloadJson,
  });

  factory TrendsSnapshot({
    int? id,
    required DateTime createdAt,
    required String interval,
    required String payloadJson,
  }) = _TrendsSnapshotImpl;

  factory TrendsSnapshot.fromJson(Map<String, dynamic> jsonSerialization) {
    return TrendsSnapshot(
      id: jsonSerialization['id'] as int?,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      interval: jsonSerialization['interval'] as String,
      payloadJson: jsonSerialization['payloadJson'] as String,
    );
  }

  static final t = TrendsSnapshotTable();

  static const db = TrendsSnapshotRepository._();

  @override
  int? id;

  DateTime createdAt;

  String interval;

  String payloadJson;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [TrendsSnapshot]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  TrendsSnapshot copyWith({
    int? id,
    DateTime? createdAt,
    String? interval,
    String? payloadJson,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'TrendsSnapshot',
      if (id != null) 'id': id,
      'createdAt': createdAt.toJson(),
      'interval': interval,
      'payloadJson': payloadJson,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'TrendsSnapshot',
      if (id != null) 'id': id,
      'createdAt': createdAt.toJson(),
      'interval': interval,
      'payloadJson': payloadJson,
    };
  }

  static TrendsSnapshotInclude include() {
    return TrendsSnapshotInclude._();
  }

  static TrendsSnapshotIncludeList includeList({
    _i1.WhereExpressionBuilder<TrendsSnapshotTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<TrendsSnapshotTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<TrendsSnapshotTable>? orderByList,
    TrendsSnapshotInclude? include,
  }) {
    return TrendsSnapshotIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(TrendsSnapshot.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(TrendsSnapshot.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _TrendsSnapshotImpl extends TrendsSnapshot {
  _TrendsSnapshotImpl({
    int? id,
    required DateTime createdAt,
    required String interval,
    required String payloadJson,
  }) : super._(
         id: id,
         createdAt: createdAt,
         interval: interval,
         payloadJson: payloadJson,
       );

  /// Returns a shallow copy of this [TrendsSnapshot]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  TrendsSnapshot copyWith({
    Object? id = _Undefined,
    DateTime? createdAt,
    String? interval,
    String? payloadJson,
  }) {
    return TrendsSnapshot(
      id: id is int? ? id : this.id,
      createdAt: createdAt ?? this.createdAt,
      interval: interval ?? this.interval,
      payloadJson: payloadJson ?? this.payloadJson,
    );
  }
}

class TrendsSnapshotUpdateTable extends _i1.UpdateTable<TrendsSnapshotTable> {
  TrendsSnapshotUpdateTable(super.table);

  _i1.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _i1.ColumnValue(
        table.createdAt,
        value,
      );

  _i1.ColumnValue<String, String> interval(String value) => _i1.ColumnValue(
    table.interval,
    value,
  );

  _i1.ColumnValue<String, String> payloadJson(String value) => _i1.ColumnValue(
    table.payloadJson,
    value,
  );
}

class TrendsSnapshotTable extends _i1.Table<int?> {
  TrendsSnapshotTable({super.tableRelation})
    : super(tableName: 'trends_snapshot') {
    updateTable = TrendsSnapshotUpdateTable(this);
    createdAt = _i1.ColumnDateTime(
      'createdAt',
      this,
    );
    interval = _i1.ColumnString(
      'interval',
      this,
    );
    payloadJson = _i1.ColumnString(
      'payloadJson',
      this,
    );
  }

  late final TrendsSnapshotUpdateTable updateTable;

  late final _i1.ColumnDateTime createdAt;

  late final _i1.ColumnString interval;

  late final _i1.ColumnString payloadJson;

  @override
  List<_i1.Column> get columns => [
    id,
    createdAt,
    interval,
    payloadJson,
  ];
}

class TrendsSnapshotInclude extends _i1.IncludeObject {
  TrendsSnapshotInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => TrendsSnapshot.t;
}

class TrendsSnapshotIncludeList extends _i1.IncludeList {
  TrendsSnapshotIncludeList._({
    _i1.WhereExpressionBuilder<TrendsSnapshotTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(TrendsSnapshot.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => TrendsSnapshot.t;
}

class TrendsSnapshotRepository {
  const TrendsSnapshotRepository._();

  /// Returns a list of [TrendsSnapshot]s matching the given query parameters.
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
  Future<List<TrendsSnapshot>> find(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<TrendsSnapshotTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<TrendsSnapshotTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<TrendsSnapshotTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.find<TrendsSnapshot>(
      where: where?.call(TrendsSnapshot.t),
      orderBy: orderBy?.call(TrendsSnapshot.t),
      orderByList: orderByList?.call(TrendsSnapshot.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Returns the first matching [TrendsSnapshot] matching the given query parameters.
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
  Future<TrendsSnapshot?> findFirstRow(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<TrendsSnapshotTable>? where,
    int? offset,
    _i1.OrderByBuilder<TrendsSnapshotTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<TrendsSnapshotTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.findFirstRow<TrendsSnapshot>(
      where: where?.call(TrendsSnapshot.t),
      orderBy: orderBy?.call(TrendsSnapshot.t),
      orderByList: orderByList?.call(TrendsSnapshot.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Finds a single [TrendsSnapshot] by its [id] or null if no such row exists.
  Future<TrendsSnapshot?> findById(
    _i1.Session session,
    int id, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.findById<TrendsSnapshot>(
      id,
      transaction: transaction,
    );
  }

  /// Inserts all [TrendsSnapshot]s in the list and returns the inserted rows.
  ///
  /// The returned [TrendsSnapshot]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  Future<List<TrendsSnapshot>> insert(
    _i1.Session session,
    List<TrendsSnapshot> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insert<TrendsSnapshot>(
      rows,
      transaction: transaction,
    );
  }

  /// Inserts a single [TrendsSnapshot] and returns the inserted row.
  ///
  /// The returned [TrendsSnapshot] will have its `id` field set.
  Future<TrendsSnapshot> insertRow(
    _i1.Session session,
    TrendsSnapshot row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<TrendsSnapshot>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [TrendsSnapshot]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<TrendsSnapshot>> update(
    _i1.Session session,
    List<TrendsSnapshot> rows, {
    _i1.ColumnSelections<TrendsSnapshotTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<TrendsSnapshot>(
      rows,
      columns: columns?.call(TrendsSnapshot.t),
      transaction: transaction,
    );
  }

  /// Updates a single [TrendsSnapshot]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<TrendsSnapshot> updateRow(
    _i1.Session session,
    TrendsSnapshot row, {
    _i1.ColumnSelections<TrendsSnapshotTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<TrendsSnapshot>(
      row,
      columns: columns?.call(TrendsSnapshot.t),
      transaction: transaction,
    );
  }

  /// Updates a single [TrendsSnapshot] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<TrendsSnapshot?> updateById(
    _i1.Session session,
    int id, {
    required _i1.ColumnValueListBuilder<TrendsSnapshotUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<TrendsSnapshot>(
      id,
      columnValues: columnValues(TrendsSnapshot.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [TrendsSnapshot]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<TrendsSnapshot>> updateWhere(
    _i1.Session session, {
    required _i1.ColumnValueListBuilder<TrendsSnapshotUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<TrendsSnapshotTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<TrendsSnapshotTable>? orderBy,
    _i1.OrderByListBuilder<TrendsSnapshotTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<TrendsSnapshot>(
      columnValues: columnValues(TrendsSnapshot.t.updateTable),
      where: where(TrendsSnapshot.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(TrendsSnapshot.t),
      orderByList: orderByList?.call(TrendsSnapshot.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [TrendsSnapshot]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<TrendsSnapshot>> delete(
    _i1.Session session,
    List<TrendsSnapshot> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<TrendsSnapshot>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [TrendsSnapshot].
  Future<TrendsSnapshot> deleteRow(
    _i1.Session session,
    TrendsSnapshot row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<TrendsSnapshot>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<TrendsSnapshot>> deleteWhere(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<TrendsSnapshotTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<TrendsSnapshot>(
      where: where(TrendsSnapshot.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<TrendsSnapshotTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<TrendsSnapshot>(
      where: where?.call(TrendsSnapshot.t),
      limit: limit,
      transaction: transaction,
    );
  }
}
