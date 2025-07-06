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

abstract class OtsoPushSubscription
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  OtsoPushSubscription._({
    this.id,
    required this.pubKey,
    required this.relay,
    required this.token,
  });

  factory OtsoPushSubscription({
    int? id,
    required String pubKey,
    required String relay,
    required String token,
  }) = _OtsoPushSubscriptionImpl;

  factory OtsoPushSubscription.fromJson(
      Map<String, dynamic> jsonSerialization) {
    return OtsoPushSubscription(
      id: jsonSerialization['id'] as int?,
      pubKey: jsonSerialization['pubKey'] as String,
      relay: jsonSerialization['relay'] as String,
      token: jsonSerialization['token'] as String,
    );
  }

  static final t = OtsoPushSubscriptionTable();

  static const db = OtsoPushSubscriptionRepository._();

  @override
  int? id;

  String pubKey;

  String relay;

  String token;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [OtsoPushSubscription]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  OtsoPushSubscription copyWith({
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

  static OtsoPushSubscriptionInclude include() {
    return OtsoPushSubscriptionInclude._();
  }

  static OtsoPushSubscriptionIncludeList includeList({
    _i1.WhereExpressionBuilder<OtsoPushSubscriptionTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<OtsoPushSubscriptionTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<OtsoPushSubscriptionTable>? orderByList,
    OtsoPushSubscriptionInclude? include,
  }) {
    return OtsoPushSubscriptionIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(OtsoPushSubscription.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(OtsoPushSubscription.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _OtsoPushSubscriptionImpl extends OtsoPushSubscription {
  _OtsoPushSubscriptionImpl({
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

  /// Returns a shallow copy of this [OtsoPushSubscription]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  OtsoPushSubscription copyWith({
    Object? id = _Undefined,
    String? pubKey,
    String? relay,
    String? token,
  }) {
    return OtsoPushSubscription(
      id: id is int? ? id : this.id,
      pubKey: pubKey ?? this.pubKey,
      relay: relay ?? this.relay,
      token: token ?? this.token,
    );
  }
}

class OtsoPushSubscriptionTable extends _i1.Table<int?> {
  OtsoPushSubscriptionTable({super.tableRelation})
      : super(tableName: 'otso_push_subscriptions') {
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

class OtsoPushSubscriptionInclude extends _i1.IncludeObject {
  OtsoPushSubscriptionInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => OtsoPushSubscription.t;
}

class OtsoPushSubscriptionIncludeList extends _i1.IncludeList {
  OtsoPushSubscriptionIncludeList._({
    _i1.WhereExpressionBuilder<OtsoPushSubscriptionTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(OtsoPushSubscription.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => OtsoPushSubscription.t;
}

class OtsoPushSubscriptionRepository {
  const OtsoPushSubscriptionRepository._();

  /// Returns a list of [OtsoPushSubscription]s matching the given query parameters.
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
  Future<List<OtsoPushSubscription>> find(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<OtsoPushSubscriptionTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<OtsoPushSubscriptionTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<OtsoPushSubscriptionTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.find<OtsoPushSubscription>(
      where: where?.call(OtsoPushSubscription.t),
      orderBy: orderBy?.call(OtsoPushSubscription.t),
      orderByList: orderByList?.call(OtsoPushSubscription.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Returns the first matching [OtsoPushSubscription] matching the given query parameters.
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
  Future<OtsoPushSubscription?> findFirstRow(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<OtsoPushSubscriptionTable>? where,
    int? offset,
    _i1.OrderByBuilder<OtsoPushSubscriptionTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<OtsoPushSubscriptionTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.findFirstRow<OtsoPushSubscription>(
      where: where?.call(OtsoPushSubscription.t),
      orderBy: orderBy?.call(OtsoPushSubscription.t),
      orderByList: orderByList?.call(OtsoPushSubscription.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Finds a single [OtsoPushSubscription] by its [id] or null if no such row exists.
  Future<OtsoPushSubscription?> findById(
    _i1.Session session,
    int id, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.findById<OtsoPushSubscription>(
      id,
      transaction: transaction,
    );
  }

  /// Inserts all [OtsoPushSubscription]s in the list and returns the inserted rows.
  ///
  /// The returned [OtsoPushSubscription]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  Future<List<OtsoPushSubscription>> insert(
    _i1.Session session,
    List<OtsoPushSubscription> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insert<OtsoPushSubscription>(
      rows,
      transaction: transaction,
    );
  }

  /// Inserts a single [OtsoPushSubscription] and returns the inserted row.
  ///
  /// The returned [OtsoPushSubscription] will have its `id` field set.
  Future<OtsoPushSubscription> insertRow(
    _i1.Session session,
    OtsoPushSubscription row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<OtsoPushSubscription>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [OtsoPushSubscription]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<OtsoPushSubscription>> update(
    _i1.Session session,
    List<OtsoPushSubscription> rows, {
    _i1.ColumnSelections<OtsoPushSubscriptionTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<OtsoPushSubscription>(
      rows,
      columns: columns?.call(OtsoPushSubscription.t),
      transaction: transaction,
    );
  }

  /// Updates a single [OtsoPushSubscription]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<OtsoPushSubscription> updateRow(
    _i1.Session session,
    OtsoPushSubscription row, {
    _i1.ColumnSelections<OtsoPushSubscriptionTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<OtsoPushSubscription>(
      row,
      columns: columns?.call(OtsoPushSubscription.t),
      transaction: transaction,
    );
  }

  /// Deletes all [OtsoPushSubscription]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<OtsoPushSubscription>> delete(
    _i1.Session session,
    List<OtsoPushSubscription> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<OtsoPushSubscription>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [OtsoPushSubscription].
  Future<OtsoPushSubscription> deleteRow(
    _i1.Session session,
    OtsoPushSubscription row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<OtsoPushSubscription>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<OtsoPushSubscription>> deleteWhere(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<OtsoPushSubscriptionTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<OtsoPushSubscription>(
      where: where(OtsoPushSubscription.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<OtsoPushSubscriptionTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<OtsoPushSubscription>(
      where: where?.call(OtsoPushSubscription.t),
      limit: limit,
      transaction: transaction,
    );
  }
}
