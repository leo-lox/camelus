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

abstract class Nip05Data implements _i1.TableRow, _i1.ProtocolSerialization {
  Nip05Data._({
    this.id,
    required this.name,
    required this.domain,
    required this.pubkey,
    required this.relays,
    required this.createdAt,
  });

  factory Nip05Data({
    int? id,
    required String name,
    required String domain,
    required String pubkey,
    required List<String> relays,
    required DateTime createdAt,
  }) = _Nip05DataImpl;

  factory Nip05Data.fromJson(Map<String, dynamic> jsonSerialization) {
    return Nip05Data(
      id: jsonSerialization['id'] as int?,
      name: jsonSerialization['name'] as String,
      domain: jsonSerialization['domain'] as String,
      pubkey: jsonSerialization['pubkey'] as String,
      relays: (jsonSerialization['relays'] as List)
          .map((e) => e as String)
          .toList(),
      createdAt:
          _i1.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
    );
  }

  static final t = Nip05DataTable();

  static const db = Nip05DataRepository._();

  @override
  int? id;

  String name;

  String domain;

  String pubkey;

  List<String> relays;

  DateTime createdAt;

  @override
  _i1.Table get table => t;

  /// Returns a shallow copy of this [Nip05Data]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Nip05Data copyWith({
    int? id,
    String? name,
    String? domain,
    String? pubkey,
    List<String>? relays,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'domain': domain,
      'pubkey': pubkey,
      'relays': relays.toJson(),
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'domain': domain,
      'pubkey': pubkey,
      'relays': relays.toJson(),
      'createdAt': createdAt.toJson(),
    };
  }

  static Nip05DataInclude include() {
    return Nip05DataInclude._();
  }

  static Nip05DataIncludeList includeList({
    _i1.WhereExpressionBuilder<Nip05DataTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<Nip05DataTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<Nip05DataTable>? orderByList,
    Nip05DataInclude? include,
  }) {
    return Nip05DataIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Nip05Data.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(Nip05Data.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _Nip05DataImpl extends Nip05Data {
  _Nip05DataImpl({
    int? id,
    required String name,
    required String domain,
    required String pubkey,
    required List<String> relays,
    required DateTime createdAt,
  }) : super._(
          id: id,
          name: name,
          domain: domain,
          pubkey: pubkey,
          relays: relays,
          createdAt: createdAt,
        );

  /// Returns a shallow copy of this [Nip05Data]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Nip05Data copyWith({
    Object? id = _Undefined,
    String? name,
    String? domain,
    String? pubkey,
    List<String>? relays,
    DateTime? createdAt,
  }) {
    return Nip05Data(
      id: id is int? ? id : this.id,
      name: name ?? this.name,
      domain: domain ?? this.domain,
      pubkey: pubkey ?? this.pubkey,
      relays: relays ?? this.relays.map((e0) => e0).toList(),
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class Nip05DataTable extends _i1.Table {
  Nip05DataTable({super.tableRelation}) : super(tableName: 'nip_05_data') {
    name = _i1.ColumnString(
      'name',
      this,
    );
    domain = _i1.ColumnString(
      'domain',
      this,
    );
    pubkey = _i1.ColumnString(
      'pubkey',
      this,
    );
    relays = _i1.ColumnSerializable(
      'relays',
      this,
    );
    createdAt = _i1.ColumnDateTime(
      'createdAt',
      this,
    );
  }

  late final _i1.ColumnString name;

  late final _i1.ColumnString domain;

  late final _i1.ColumnString pubkey;

  late final _i1.ColumnSerializable relays;

  late final _i1.ColumnDateTime createdAt;

  @override
  List<_i1.Column> get columns => [
        id,
        name,
        domain,
        pubkey,
        relays,
        createdAt,
      ];
}

class Nip05DataInclude extends _i1.IncludeObject {
  Nip05DataInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table get table => Nip05Data.t;
}

class Nip05DataIncludeList extends _i1.IncludeList {
  Nip05DataIncludeList._({
    _i1.WhereExpressionBuilder<Nip05DataTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(Nip05Data.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table get table => Nip05Data.t;
}

class Nip05DataRepository {
  const Nip05DataRepository._();

  /// Returns a list of [Nip05Data]s matching the given query parameters.
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
  Future<List<Nip05Data>> find(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<Nip05DataTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<Nip05DataTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<Nip05DataTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.find<Nip05Data>(
      where: where?.call(Nip05Data.t),
      orderBy: orderBy?.call(Nip05Data.t),
      orderByList: orderByList?.call(Nip05Data.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Returns the first matching [Nip05Data] matching the given query parameters.
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
  Future<Nip05Data?> findFirstRow(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<Nip05DataTable>? where,
    int? offset,
    _i1.OrderByBuilder<Nip05DataTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<Nip05DataTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.findFirstRow<Nip05Data>(
      where: where?.call(Nip05Data.t),
      orderBy: orderBy?.call(Nip05Data.t),
      orderByList: orderByList?.call(Nip05Data.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Finds a single [Nip05Data] by its [id] or null if no such row exists.
  Future<Nip05Data?> findById(
    _i1.Session session,
    int id, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.findById<Nip05Data>(
      id,
      transaction: transaction,
    );
  }

  /// Inserts all [Nip05Data]s in the list and returns the inserted rows.
  ///
  /// The returned [Nip05Data]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  Future<List<Nip05Data>> insert(
    _i1.Session session,
    List<Nip05Data> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insert<Nip05Data>(
      rows,
      transaction: transaction,
    );
  }

  /// Inserts a single [Nip05Data] and returns the inserted row.
  ///
  /// The returned [Nip05Data] will have its `id` field set.
  Future<Nip05Data> insertRow(
    _i1.Session session,
    Nip05Data row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<Nip05Data>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [Nip05Data]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<Nip05Data>> update(
    _i1.Session session,
    List<Nip05Data> rows, {
    _i1.ColumnSelections<Nip05DataTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<Nip05Data>(
      rows,
      columns: columns?.call(Nip05Data.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Nip05Data]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<Nip05Data> updateRow(
    _i1.Session session,
    Nip05Data row, {
    _i1.ColumnSelections<Nip05DataTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<Nip05Data>(
      row,
      columns: columns?.call(Nip05Data.t),
      transaction: transaction,
    );
  }

  /// Deletes all [Nip05Data]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<Nip05Data>> delete(
    _i1.Session session,
    List<Nip05Data> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<Nip05Data>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [Nip05Data].
  Future<Nip05Data> deleteRow(
    _i1.Session session,
    Nip05Data row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<Nip05Data>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<Nip05Data>> deleteWhere(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<Nip05DataTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<Nip05Data>(
      where: where(Nip05Data.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<Nip05DataTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<Nip05Data>(
      where: where?.call(Nip05Data.t),
      limit: limit,
      transaction: transaction,
    );
  }
}
