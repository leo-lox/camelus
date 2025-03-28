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

abstract class PushSubscription
    implements _i1.TableRow, _i1.ProtocolSerialization {
  PushSubscription._({
    this.id,
    required this.pubKey,
    required this.relay,
    required this.token,
  });

  factory PushSubscription({
    int? id,
    required String pubKey,
    required String relay,
    required String token,
  }) = _PushSubscriptionImpl;

  factory PushSubscription.fromJson(Map<String, dynamic> jsonSerialization) {
    return PushSubscription(
      id: jsonSerialization['id'] as int?,
      pubKey: jsonSerialization['pubKey'] as String,
      relay: jsonSerialization['relay'] as String,
      token: jsonSerialization['token'] as String,
    );
  }

  static final t = PushSubscriptionTable();

  static const db = PushSubscriptionRepository._();

  @override
  int? id;

  String pubKey;

  String relay;

  String token;

  @override
  _i1.Table get table => t;

  /// Returns a shallow copy of this [PushSubscription]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  PushSubscription copyWith({
    int? id,
    String? pubKey,
    String? relay,
    String? token,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'pubKey': pubKey,
      'relay': relay,
      'token': token,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      if (id != null) 'id': id,
      'pubKey': pubKey,
      'relay': relay,
      'token': token,
    };
  }

  static PushSubscriptionInclude include() {
    return PushSubscriptionInclude._();
  }

  static PushSubscriptionIncludeList includeList({
    _i1.WhereExpressionBuilder<PushSubscriptionTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<PushSubscriptionTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<PushSubscriptionTable>? orderByList,
    PushSubscriptionInclude? include,
  }) {
    return PushSubscriptionIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(PushSubscription.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(PushSubscription.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _PushSubscriptionImpl extends PushSubscription {
  _PushSubscriptionImpl({
    int? id,
    required String pubKey,
    required String relay,
    required String token,
  }) : super._(
          id: id,
          pubKey: pubKey,
          relay: relay,
          token: token,
        );

  /// Returns a shallow copy of this [PushSubscription]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  PushSubscription copyWith({
    Object? id = _Undefined,
    String? pubKey,
    String? relay,
    String? token,
  }) {
    return PushSubscription(
      id: id is int? ? id : this.id,
      pubKey: pubKey ?? this.pubKey,
      relay: relay ?? this.relay,
      token: token ?? this.token,
    );
  }
}

class PushSubscriptionTable extends _i1.Table {
  PushSubscriptionTable({super.tableRelation})
      : super(tableName: 'push_subscriptions') {
    pubKey = _i1.ColumnString(
      'pubKey',
      this,
    );
    relay = _i1.ColumnString(
      'relay',
      this,
    );
    token = _i1.ColumnString(
      'token',
      this,
    );
  }

  late final _i1.ColumnString pubKey;

  late final _i1.ColumnString relay;

  late final _i1.ColumnString token;

  @override
  List<_i1.Column> get columns => [
        id,
        pubKey,
        relay,
        token,
      ];
}

class PushSubscriptionInclude extends _i1.IncludeObject {
  PushSubscriptionInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table get table => PushSubscription.t;
}

class PushSubscriptionIncludeList extends _i1.IncludeList {
  PushSubscriptionIncludeList._({
    _i1.WhereExpressionBuilder<PushSubscriptionTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(PushSubscription.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table get table => PushSubscription.t;
}

class PushSubscriptionRepository {
  const PushSubscriptionRepository._();

  /// Returns a list of [PushSubscription]s matching the given query parameters.
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
  Future<List<PushSubscription>> find(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<PushSubscriptionTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<PushSubscriptionTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<PushSubscriptionTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.find<PushSubscription>(
      where: where?.call(PushSubscription.t),
      orderBy: orderBy?.call(PushSubscription.t),
      orderByList: orderByList?.call(PushSubscription.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Returns the first matching [PushSubscription] matching the given query parameters.
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
  Future<PushSubscription?> findFirstRow(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<PushSubscriptionTable>? where,
    int? offset,
    _i1.OrderByBuilder<PushSubscriptionTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<PushSubscriptionTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.findFirstRow<PushSubscription>(
      where: where?.call(PushSubscription.t),
      orderBy: orderBy?.call(PushSubscription.t),
      orderByList: orderByList?.call(PushSubscription.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Finds a single [PushSubscription] by its [id] or null if no such row exists.
  Future<PushSubscription?> findById(
    _i1.Session session,
    int id, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.findById<PushSubscription>(
      id,
      transaction: transaction,
    );
  }

  /// Inserts all [PushSubscription]s in the list and returns the inserted rows.
  ///
  /// The returned [PushSubscription]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  Future<List<PushSubscription>> insert(
    _i1.Session session,
    List<PushSubscription> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insert<PushSubscription>(
      rows,
      transaction: transaction,
    );
  }

  /// Inserts a single [PushSubscription] and returns the inserted row.
  ///
  /// The returned [PushSubscription] will have its `id` field set.
  Future<PushSubscription> insertRow(
    _i1.Session session,
    PushSubscription row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<PushSubscription>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [PushSubscription]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<PushSubscription>> update(
    _i1.Session session,
    List<PushSubscription> rows, {
    _i1.ColumnSelections<PushSubscriptionTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<PushSubscription>(
      rows,
      columns: columns?.call(PushSubscription.t),
      transaction: transaction,
    );
  }

  /// Updates a single [PushSubscription]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<PushSubscription> updateRow(
    _i1.Session session,
    PushSubscription row, {
    _i1.ColumnSelections<PushSubscriptionTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<PushSubscription>(
      row,
      columns: columns?.call(PushSubscription.t),
      transaction: transaction,
    );
  }

  /// Deletes all [PushSubscription]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<PushSubscription>> delete(
    _i1.Session session,
    List<PushSubscription> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<PushSubscription>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [PushSubscription].
  Future<PushSubscription> deleteRow(
    _i1.Session session,
    PushSubscription row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<PushSubscription>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<PushSubscription>> deleteWhere(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<PushSubscriptionTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<PushSubscription>(
      where: where(PushSubscription.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<PushSubscriptionTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<PushSubscription>(
      where: where?.call(PushSubscription.t),
      limit: limit,
      transaction: transaction,
    );
  }
}
