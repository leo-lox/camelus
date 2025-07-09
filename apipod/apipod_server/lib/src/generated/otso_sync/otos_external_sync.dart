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

abstract class OtsoExternalSync
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  OtsoExternalSync._({
    this.id,
    required this.itemId,
    required this.syncedAt,
  });

  factory OtsoExternalSync({
    int? id,
    required int itemId,
    required DateTime syncedAt,
  }) = _OtsoExternalSyncImpl;

  factory OtsoExternalSync.fromJson(Map<String, dynamic> jsonSerialization) {
    return OtsoExternalSync(
      id: jsonSerialization['id'] as int?,
      itemId: jsonSerialization['itemId'] as int,
      syncedAt:
          _i1.DateTimeJsonExtension.fromJson(jsonSerialization['syncedAt']),
    );
  }

  static final t = OtsoExternalSyncTable();

  static const db = OtsoExternalSyncRepository._();

  @override
  int? id;

  int itemId;

  DateTime syncedAt;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [OtsoExternalSync]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  OtsoExternalSync copyWith({
    int? id,
    int? itemId,
    DateTime? syncedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'itemId': itemId,
      'syncedAt': syncedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      if (id != null) 'id': id,
      'itemId': itemId,
      'syncedAt': syncedAt.toJson(),
    };
  }

  static OtsoExternalSyncInclude include() {
    return OtsoExternalSyncInclude._();
  }

  static OtsoExternalSyncIncludeList includeList({
    _i1.WhereExpressionBuilder<OtsoExternalSyncTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<OtsoExternalSyncTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<OtsoExternalSyncTable>? orderByList,
    OtsoExternalSyncInclude? include,
  }) {
    return OtsoExternalSyncIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(OtsoExternalSync.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(OtsoExternalSync.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _OtsoExternalSyncImpl extends OtsoExternalSync {
  _OtsoExternalSyncImpl({
    int? id,
    required int itemId,
    required DateTime syncedAt,
  }) : super._(
          id: id,
          itemId: itemId,
          syncedAt: syncedAt,
        );

  /// Returns a shallow copy of this [OtsoExternalSync]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  OtsoExternalSync copyWith({
    Object? id = _Undefined,
    int? itemId,
    DateTime? syncedAt,
  }) {
    return OtsoExternalSync(
      id: id is int? ? id : this.id,
      itemId: itemId ?? this.itemId,
      syncedAt: syncedAt ?? this.syncedAt,
    );
  }
}

class OtsoExternalSyncTable extends _i1.Table<int?> {
  OtsoExternalSyncTable({super.tableRelation})
      : super(tableName: 'otso_external_sync') {
    itemId = _i1.ColumnInt(
      'itemId',
      this,
    );
    syncedAt = _i1.ColumnDateTime(
      'syncedAt',
      this,
    );
  }

  late final _i1.ColumnInt itemId;

  late final _i1.ColumnDateTime syncedAt;

  @override
  List<_i1.Column> get columns => [
        id,
        itemId,
        syncedAt,
      ];
}

class OtsoExternalSyncInclude extends _i1.IncludeObject {
  OtsoExternalSyncInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => OtsoExternalSync.t;
}

class OtsoExternalSyncIncludeList extends _i1.IncludeList {
  OtsoExternalSyncIncludeList._({
    _i1.WhereExpressionBuilder<OtsoExternalSyncTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(OtsoExternalSync.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => OtsoExternalSync.t;
}

class OtsoExternalSyncRepository {
  const OtsoExternalSyncRepository._();

  /// Returns a list of [OtsoExternalSync]s matching the given query parameters.
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
  Future<List<OtsoExternalSync>> find(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<OtsoExternalSyncTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<OtsoExternalSyncTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<OtsoExternalSyncTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.find<OtsoExternalSync>(
      where: where?.call(OtsoExternalSync.t),
      orderBy: orderBy?.call(OtsoExternalSync.t),
      orderByList: orderByList?.call(OtsoExternalSync.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Returns the first matching [OtsoExternalSync] matching the given query parameters.
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
  Future<OtsoExternalSync?> findFirstRow(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<OtsoExternalSyncTable>? where,
    int? offset,
    _i1.OrderByBuilder<OtsoExternalSyncTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<OtsoExternalSyncTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.findFirstRow<OtsoExternalSync>(
      where: where?.call(OtsoExternalSync.t),
      orderBy: orderBy?.call(OtsoExternalSync.t),
      orderByList: orderByList?.call(OtsoExternalSync.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Finds a single [OtsoExternalSync] by its [id] or null if no such row exists.
  Future<OtsoExternalSync?> findById(
    _i1.Session session,
    int id, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.findById<OtsoExternalSync>(
      id,
      transaction: transaction,
    );
  }

  /// Inserts all [OtsoExternalSync]s in the list and returns the inserted rows.
  ///
  /// The returned [OtsoExternalSync]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  Future<List<OtsoExternalSync>> insert(
    _i1.Session session,
    List<OtsoExternalSync> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insert<OtsoExternalSync>(
      rows,
      transaction: transaction,
    );
  }

  /// Inserts a single [OtsoExternalSync] and returns the inserted row.
  ///
  /// The returned [OtsoExternalSync] will have its `id` field set.
  Future<OtsoExternalSync> insertRow(
    _i1.Session session,
    OtsoExternalSync row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<OtsoExternalSync>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [OtsoExternalSync]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<OtsoExternalSync>> update(
    _i1.Session session,
    List<OtsoExternalSync> rows, {
    _i1.ColumnSelections<OtsoExternalSyncTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<OtsoExternalSync>(
      rows,
      columns: columns?.call(OtsoExternalSync.t),
      transaction: transaction,
    );
  }

  /// Updates a single [OtsoExternalSync]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<OtsoExternalSync> updateRow(
    _i1.Session session,
    OtsoExternalSync row, {
    _i1.ColumnSelections<OtsoExternalSyncTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<OtsoExternalSync>(
      row,
      columns: columns?.call(OtsoExternalSync.t),
      transaction: transaction,
    );
  }

  /// Deletes all [OtsoExternalSync]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<OtsoExternalSync>> delete(
    _i1.Session session,
    List<OtsoExternalSync> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<OtsoExternalSync>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [OtsoExternalSync].
  Future<OtsoExternalSync> deleteRow(
    _i1.Session session,
    OtsoExternalSync row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<OtsoExternalSync>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<OtsoExternalSync>> deleteWhere(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<OtsoExternalSyncTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<OtsoExternalSync>(
      where: where(OtsoExternalSync.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<OtsoExternalSyncTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<OtsoExternalSync>(
      where: where?.call(OtsoExternalSync.t),
      limit: limit,
      transaction: transaction,
    );
  }
}
