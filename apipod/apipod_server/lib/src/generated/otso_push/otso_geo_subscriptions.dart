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

abstract class OtsoGeoSubscription
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  OtsoGeoSubscription._({
    this.id,
    required this.pubKey,
    required this.geohash,
  });

  factory OtsoGeoSubscription({
    int? id,
    required String pubKey,
    required String geohash,
  }) = _OtsoGeoSubscriptionImpl;

  factory OtsoGeoSubscription.fromJson(Map<String, dynamic> jsonSerialization) {
    return OtsoGeoSubscription(
      id: jsonSerialization['id'] as int?,
      pubKey: jsonSerialization['pubKey'] as String,
      geohash: jsonSerialization['geohash'] as String,
    );
  }

  static final t = OtsoGeoSubscriptionTable();

  static const db = OtsoGeoSubscriptionRepository._();

  @override
  int? id;

  String pubKey;

  String geohash;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [OtsoGeoSubscription]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  OtsoGeoSubscription copyWith({
    int? id,
    String? pubKey,
    String? geohash,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'pubKey': pubKey,
      'geohash': geohash,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      if (id != null) 'id': id,
      'pubKey': pubKey,
      'geohash': geohash,
    };
  }

  static OtsoGeoSubscriptionInclude include() {
    return OtsoGeoSubscriptionInclude._();
  }

  static OtsoGeoSubscriptionIncludeList includeList({
    _i1.WhereExpressionBuilder<OtsoGeoSubscriptionTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<OtsoGeoSubscriptionTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<OtsoGeoSubscriptionTable>? orderByList,
    OtsoGeoSubscriptionInclude? include,
  }) {
    return OtsoGeoSubscriptionIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(OtsoGeoSubscription.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(OtsoGeoSubscription.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _OtsoGeoSubscriptionImpl extends OtsoGeoSubscription {
  _OtsoGeoSubscriptionImpl({
    int? id,
    required String pubKey,
    required String geohash,
  }) : super._(
          id: id,
          pubKey: pubKey,
          geohash: geohash,
        );

  /// Returns a shallow copy of this [OtsoGeoSubscription]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  OtsoGeoSubscription copyWith({
    Object? id = _Undefined,
    String? pubKey,
    String? geohash,
  }) {
    return OtsoGeoSubscription(
      id: id is int? ? id : this.id,
      pubKey: pubKey ?? this.pubKey,
      geohash: geohash ?? this.geohash,
    );
  }
}

class OtsoGeoSubscriptionTable extends _i1.Table<int?> {
  OtsoGeoSubscriptionTable({super.tableRelation})
      : super(tableName: 'otso_geo_subscriptions') {
    pubKey = _i1.ColumnString(
      'pubKey',
      this,
    );
    geohash = _i1.ColumnString(
      'geohash',
      this,
    );
  }

  late final _i1.ColumnString pubKey;

  late final _i1.ColumnString geohash;

  @override
  List<_i1.Column> get columns => [
        id,
        pubKey,
        geohash,
      ];
}

class OtsoGeoSubscriptionInclude extends _i1.IncludeObject {
  OtsoGeoSubscriptionInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => OtsoGeoSubscription.t;
}

class OtsoGeoSubscriptionIncludeList extends _i1.IncludeList {
  OtsoGeoSubscriptionIncludeList._({
    _i1.WhereExpressionBuilder<OtsoGeoSubscriptionTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(OtsoGeoSubscription.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => OtsoGeoSubscription.t;
}

class OtsoGeoSubscriptionRepository {
  const OtsoGeoSubscriptionRepository._();

  /// Returns a list of [OtsoGeoSubscription]s matching the given query parameters.
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
  Future<List<OtsoGeoSubscription>> find(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<OtsoGeoSubscriptionTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<OtsoGeoSubscriptionTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<OtsoGeoSubscriptionTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.find<OtsoGeoSubscription>(
      where: where?.call(OtsoGeoSubscription.t),
      orderBy: orderBy?.call(OtsoGeoSubscription.t),
      orderByList: orderByList?.call(OtsoGeoSubscription.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Returns the first matching [OtsoGeoSubscription] matching the given query parameters.
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
  Future<OtsoGeoSubscription?> findFirstRow(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<OtsoGeoSubscriptionTable>? where,
    int? offset,
    _i1.OrderByBuilder<OtsoGeoSubscriptionTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<OtsoGeoSubscriptionTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.findFirstRow<OtsoGeoSubscription>(
      where: where?.call(OtsoGeoSubscription.t),
      orderBy: orderBy?.call(OtsoGeoSubscription.t),
      orderByList: orderByList?.call(OtsoGeoSubscription.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Finds a single [OtsoGeoSubscription] by its [id] or null if no such row exists.
  Future<OtsoGeoSubscription?> findById(
    _i1.Session session,
    int id, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.findById<OtsoGeoSubscription>(
      id,
      transaction: transaction,
    );
  }

  /// Inserts all [OtsoGeoSubscription]s in the list and returns the inserted rows.
  ///
  /// The returned [OtsoGeoSubscription]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  Future<List<OtsoGeoSubscription>> insert(
    _i1.Session session,
    List<OtsoGeoSubscription> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insert<OtsoGeoSubscription>(
      rows,
      transaction: transaction,
    );
  }

  /// Inserts a single [OtsoGeoSubscription] and returns the inserted row.
  ///
  /// The returned [OtsoGeoSubscription] will have its `id` field set.
  Future<OtsoGeoSubscription> insertRow(
    _i1.Session session,
    OtsoGeoSubscription row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<OtsoGeoSubscription>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [OtsoGeoSubscription]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<OtsoGeoSubscription>> update(
    _i1.Session session,
    List<OtsoGeoSubscription> rows, {
    _i1.ColumnSelections<OtsoGeoSubscriptionTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<OtsoGeoSubscription>(
      rows,
      columns: columns?.call(OtsoGeoSubscription.t),
      transaction: transaction,
    );
  }

  /// Updates a single [OtsoGeoSubscription]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<OtsoGeoSubscription> updateRow(
    _i1.Session session,
    OtsoGeoSubscription row, {
    _i1.ColumnSelections<OtsoGeoSubscriptionTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<OtsoGeoSubscription>(
      row,
      columns: columns?.call(OtsoGeoSubscription.t),
      transaction: transaction,
    );
  }

  /// Deletes all [OtsoGeoSubscription]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<OtsoGeoSubscription>> delete(
    _i1.Session session,
    List<OtsoGeoSubscription> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<OtsoGeoSubscription>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [OtsoGeoSubscription].
  Future<OtsoGeoSubscription> deleteRow(
    _i1.Session session,
    OtsoGeoSubscription row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<OtsoGeoSubscription>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<OtsoGeoSubscription>> deleteWhere(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<OtsoGeoSubscriptionTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<OtsoGeoSubscription>(
      where: where(OtsoGeoSubscription.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<OtsoGeoSubscriptionTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<OtsoGeoSubscription>(
      where: where?.call(OtsoGeoSubscription.t),
      limit: limit,
      transaction: transaction,
    );
  }
}
