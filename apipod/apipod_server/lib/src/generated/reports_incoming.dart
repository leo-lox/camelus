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
import 'package:ndk/domain_layer/entities/nip_01_event.dart' as _i2;

abstract class ReportsIncoming
    implements _i1.TableRow, _i1.ProtocolSerialization {
  ReportsIncoming._({
    this.id,
    required this.createdAt,
    required this.report,
    required this.author,
    required this.type,
    required this.processed,
  });

  factory ReportsIncoming({
    int? id,
    required DateTime createdAt,
    required _i2.Nip01Event report,
    required String author,
    required String type,
    required bool processed,
  }) = _ReportsIncomingImpl;

  factory ReportsIncoming.fromJson(Map<String, dynamic> jsonSerialization) {
    return ReportsIncoming(
      id: jsonSerialization['id'] as int?,
      createdAt:
          _i1.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
      report: _i2.Nip01Event.fromJson(jsonSerialization['report']),
      author: jsonSerialization['author'] as String,
      type: jsonSerialization['type'] as String,
      processed: jsonSerialization['processed'] as bool,
    );
  }

  static final t = ReportsIncomingTable();

  static const db = ReportsIncomingRepository._();

  @override
  int? id;

  DateTime createdAt;

  _i2.Nip01Event report;

  String author;

  String type;

  bool processed;

  @override
  _i1.Table get table => t;

  /// Returns a shallow copy of this [ReportsIncoming]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ReportsIncoming copyWith({
    int? id,
    DateTime? createdAt,
    _i2.Nip01Event? report,
    String? author,
    String? type,
    bool? processed,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'createdAt': createdAt.toJson(),
      'report': report.toJson(),
      'author': author,
      'type': type,
      'processed': processed,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      if (id != null) 'id': id,
      'createdAt': createdAt.toJson(),
      'report':
// ignore: unnecessary_type_check
          report is _i1.ProtocolSerialization
              ? (report as _i1.ProtocolSerialization).toJsonForProtocol()
              : report.toJson(),
      'author': author,
      'type': type,
      'processed': processed,
    };
  }

  static ReportsIncomingInclude include() {
    return ReportsIncomingInclude._();
  }

  static ReportsIncomingIncludeList includeList({
    _i1.WhereExpressionBuilder<ReportsIncomingTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ReportsIncomingTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ReportsIncomingTable>? orderByList,
    ReportsIncomingInclude? include,
  }) {
    return ReportsIncomingIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ReportsIncoming.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(ReportsIncoming.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ReportsIncomingImpl extends ReportsIncoming {
  _ReportsIncomingImpl({
    int? id,
    required DateTime createdAt,
    required _i2.Nip01Event report,
    required String author,
    required String type,
    required bool processed,
  }) : super._(
          id: id,
          createdAt: createdAt,
          report: report,
          author: author,
          type: type,
          processed: processed,
        );

  /// Returns a shallow copy of this [ReportsIncoming]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ReportsIncoming copyWith({
    Object? id = _Undefined,
    DateTime? createdAt,
    _i2.Nip01Event? report,
    String? author,
    String? type,
    bool? processed,
  }) {
    return ReportsIncoming(
      id: id is int? ? id : this.id,
      createdAt: createdAt ?? this.createdAt,
      report: report ?? this.report.copyWith(),
      author: author ?? this.author,
      type: type ?? this.type,
      processed: processed ?? this.processed,
    );
  }
}

class ReportsIncomingTable extends _i1.Table {
  ReportsIncomingTable({super.tableRelation})
      : super(tableName: 'reports_incoming') {
    createdAt = _i1.ColumnDateTime(
      'createdAt',
      this,
    );
    report = _i1.ColumnSerializable(
      'report',
      this,
    );
    author = _i1.ColumnString(
      'author',
      this,
    );
    type = _i1.ColumnString(
      'type',
      this,
    );
    processed = _i1.ColumnBool(
      'processed',
      this,
    );
  }

  late final _i1.ColumnDateTime createdAt;

  late final _i1.ColumnSerializable report;

  late final _i1.ColumnString author;

  late final _i1.ColumnString type;

  late final _i1.ColumnBool processed;

  @override
  List<_i1.Column> get columns => [
        id,
        createdAt,
        report,
        author,
        type,
        processed,
      ];
}

class ReportsIncomingInclude extends _i1.IncludeObject {
  ReportsIncomingInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table get table => ReportsIncoming.t;
}

class ReportsIncomingIncludeList extends _i1.IncludeList {
  ReportsIncomingIncludeList._({
    _i1.WhereExpressionBuilder<ReportsIncomingTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(ReportsIncoming.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table get table => ReportsIncoming.t;
}

class ReportsIncomingRepository {
  const ReportsIncomingRepository._();

  /// Returns a list of [ReportsIncoming]s matching the given query parameters.
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
  Future<List<ReportsIncoming>> find(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<ReportsIncomingTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ReportsIncomingTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ReportsIncomingTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.find<ReportsIncoming>(
      where: where?.call(ReportsIncoming.t),
      orderBy: orderBy?.call(ReportsIncoming.t),
      orderByList: orderByList?.call(ReportsIncoming.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Returns the first matching [ReportsIncoming] matching the given query parameters.
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
  Future<ReportsIncoming?> findFirstRow(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<ReportsIncomingTable>? where,
    int? offset,
    _i1.OrderByBuilder<ReportsIncomingTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ReportsIncomingTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.findFirstRow<ReportsIncoming>(
      where: where?.call(ReportsIncoming.t),
      orderBy: orderBy?.call(ReportsIncoming.t),
      orderByList: orderByList?.call(ReportsIncoming.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Finds a single [ReportsIncoming] by its [id] or null if no such row exists.
  Future<ReportsIncoming?> findById(
    _i1.Session session,
    int id, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.findById<ReportsIncoming>(
      id,
      transaction: transaction,
    );
  }

  /// Inserts all [ReportsIncoming]s in the list and returns the inserted rows.
  ///
  /// The returned [ReportsIncoming]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  Future<List<ReportsIncoming>> insert(
    _i1.Session session,
    List<ReportsIncoming> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insert<ReportsIncoming>(
      rows,
      transaction: transaction,
    );
  }

  /// Inserts a single [ReportsIncoming] and returns the inserted row.
  ///
  /// The returned [ReportsIncoming] will have its `id` field set.
  Future<ReportsIncoming> insertRow(
    _i1.Session session,
    ReportsIncoming row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<ReportsIncoming>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [ReportsIncoming]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<ReportsIncoming>> update(
    _i1.Session session,
    List<ReportsIncoming> rows, {
    _i1.ColumnSelections<ReportsIncomingTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<ReportsIncoming>(
      rows,
      columns: columns?.call(ReportsIncoming.t),
      transaction: transaction,
    );
  }

  /// Updates a single [ReportsIncoming]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<ReportsIncoming> updateRow(
    _i1.Session session,
    ReportsIncoming row, {
    _i1.ColumnSelections<ReportsIncomingTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<ReportsIncoming>(
      row,
      columns: columns?.call(ReportsIncoming.t),
      transaction: transaction,
    );
  }

  /// Deletes all [ReportsIncoming]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<ReportsIncoming>> delete(
    _i1.Session session,
    List<ReportsIncoming> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<ReportsIncoming>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [ReportsIncoming].
  Future<ReportsIncoming> deleteRow(
    _i1.Session session,
    ReportsIncoming row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<ReportsIncoming>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<ReportsIncoming>> deleteWhere(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<ReportsIncomingTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<ReportsIncoming>(
      where: where(ReportsIncoming.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<ReportsIncomingTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<ReportsIncoming>(
      where: where?.call(ReportsIncoming.t),
      limit: limit,
      transaction: transaction,
    );
  }
}
