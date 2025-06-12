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

abstract class ShortLinkInviteData
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  ShortLinkInviteData._({
    this.id,
    required this.shortLink,
    required this.createdAt,
    required this.invitedByNpub,
    required this.listName,
    required this.listNpub,
    int? usageCount,
    this.lastUsed,
  }) : usageCount = usageCount ?? 0;

  factory ShortLinkInviteData({
    int? id,
    required String shortLink,
    required DateTime createdAt,
    required String invitedByNpub,
    required String listName,
    required String listNpub,
    int? usageCount,
    DateTime? lastUsed,
  }) = _ShortLinkInviteDataImpl;

  factory ShortLinkInviteData.fromJson(Map<String, dynamic> jsonSerialization) {
    return ShortLinkInviteData(
      id: jsonSerialization['id'] as int?,
      shortLink: jsonSerialization['shortLink'] as String,
      createdAt:
          _i1.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
      invitedByNpub: jsonSerialization['invitedByNpub'] as String,
      listName: jsonSerialization['listName'] as String,
      listNpub: jsonSerialization['listNpub'] as String,
      usageCount: jsonSerialization['usageCount'] as int,
      lastUsed: jsonSerialization['lastUsed'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['lastUsed']),
    );
  }

  static final t = ShortLinkInviteDataTable();

  static const db = ShortLinkInviteDataRepository._();

  @override
  int? id;

  String shortLink;

  DateTime createdAt;

  String invitedByNpub;

  String listName;

  String listNpub;

  int usageCount;

  DateTime? lastUsed;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [ShortLinkInviteData]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ShortLinkInviteData copyWith({
    int? id,
    String? shortLink,
    DateTime? createdAt,
    String? invitedByNpub,
    String? listName,
    String? listNpub,
    int? usageCount,
    DateTime? lastUsed,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'shortLink': shortLink,
      'createdAt': createdAt.toJson(),
      'invitedByNpub': invitedByNpub,
      'listName': listName,
      'listNpub': listNpub,
      'usageCount': usageCount,
      if (lastUsed != null) 'lastUsed': lastUsed?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      if (id != null) 'id': id,
      'shortLink': shortLink,
      'createdAt': createdAt.toJson(),
      'invitedByNpub': invitedByNpub,
      'listName': listName,
      'listNpub': listNpub,
      'usageCount': usageCount,
      if (lastUsed != null) 'lastUsed': lastUsed?.toJson(),
    };
  }

  static ShortLinkInviteDataInclude include() {
    return ShortLinkInviteDataInclude._();
  }

  static ShortLinkInviteDataIncludeList includeList({
    _i1.WhereExpressionBuilder<ShortLinkInviteDataTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ShortLinkInviteDataTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ShortLinkInviteDataTable>? orderByList,
    ShortLinkInviteDataInclude? include,
  }) {
    return ShortLinkInviteDataIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ShortLinkInviteData.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(ShortLinkInviteData.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ShortLinkInviteDataImpl extends ShortLinkInviteData {
  _ShortLinkInviteDataImpl({
    int? id,
    required String shortLink,
    required DateTime createdAt,
    required String invitedByNpub,
    required String listName,
    required String listNpub,
    int? usageCount,
    DateTime? lastUsed,
  }) : super._(
          id: id,
          shortLink: shortLink,
          createdAt: createdAt,
          invitedByNpub: invitedByNpub,
          listName: listName,
          listNpub: listNpub,
          usageCount: usageCount,
          lastUsed: lastUsed,
        );

  /// Returns a shallow copy of this [ShortLinkInviteData]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ShortLinkInviteData copyWith({
    Object? id = _Undefined,
    String? shortLink,
    DateTime? createdAt,
    String? invitedByNpub,
    String? listName,
    String? listNpub,
    int? usageCount,
    Object? lastUsed = _Undefined,
  }) {
    return ShortLinkInviteData(
      id: id is int? ? id : this.id,
      shortLink: shortLink ?? this.shortLink,
      createdAt: createdAt ?? this.createdAt,
      invitedByNpub: invitedByNpub ?? this.invitedByNpub,
      listName: listName ?? this.listName,
      listNpub: listNpub ?? this.listNpub,
      usageCount: usageCount ?? this.usageCount,
      lastUsed: lastUsed is DateTime? ? lastUsed : this.lastUsed,
    );
  }
}

class ShortLinkInviteDataTable extends _i1.Table<int?> {
  ShortLinkInviteDataTable({super.tableRelation})
      : super(tableName: 'short_link_invite_data') {
    shortLink = _i1.ColumnString(
      'shortLink',
      this,
    );
    createdAt = _i1.ColumnDateTime(
      'createdAt',
      this,
    );
    invitedByNpub = _i1.ColumnString(
      'invitedByNpub',
      this,
    );
    listName = _i1.ColumnString(
      'listName',
      this,
    );
    listNpub = _i1.ColumnString(
      'listNpub',
      this,
    );
    usageCount = _i1.ColumnInt(
      'usageCount',
      this,
      hasDefault: true,
    );
    lastUsed = _i1.ColumnDateTime(
      'lastUsed',
      this,
    );
  }

  late final _i1.ColumnString shortLink;

  late final _i1.ColumnDateTime createdAt;

  late final _i1.ColumnString invitedByNpub;

  late final _i1.ColumnString listName;

  late final _i1.ColumnString listNpub;

  late final _i1.ColumnInt usageCount;

  late final _i1.ColumnDateTime lastUsed;

  @override
  List<_i1.Column> get columns => [
        id,
        shortLink,
        createdAt,
        invitedByNpub,
        listName,
        listNpub,
        usageCount,
        lastUsed,
      ];
}

class ShortLinkInviteDataInclude extends _i1.IncludeObject {
  ShortLinkInviteDataInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => ShortLinkInviteData.t;
}

class ShortLinkInviteDataIncludeList extends _i1.IncludeList {
  ShortLinkInviteDataIncludeList._({
    _i1.WhereExpressionBuilder<ShortLinkInviteDataTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(ShortLinkInviteData.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => ShortLinkInviteData.t;
}

class ShortLinkInviteDataRepository {
  const ShortLinkInviteDataRepository._();

  /// Returns a list of [ShortLinkInviteData]s matching the given query parameters.
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
  Future<List<ShortLinkInviteData>> find(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<ShortLinkInviteDataTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ShortLinkInviteDataTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ShortLinkInviteDataTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.find<ShortLinkInviteData>(
      where: where?.call(ShortLinkInviteData.t),
      orderBy: orderBy?.call(ShortLinkInviteData.t),
      orderByList: orderByList?.call(ShortLinkInviteData.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Returns the first matching [ShortLinkInviteData] matching the given query parameters.
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
  Future<ShortLinkInviteData?> findFirstRow(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<ShortLinkInviteDataTable>? where,
    int? offset,
    _i1.OrderByBuilder<ShortLinkInviteDataTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ShortLinkInviteDataTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.findFirstRow<ShortLinkInviteData>(
      where: where?.call(ShortLinkInviteData.t),
      orderBy: orderBy?.call(ShortLinkInviteData.t),
      orderByList: orderByList?.call(ShortLinkInviteData.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Finds a single [ShortLinkInviteData] by its [id] or null if no such row exists.
  Future<ShortLinkInviteData?> findById(
    _i1.Session session,
    int id, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.findById<ShortLinkInviteData>(
      id,
      transaction: transaction,
    );
  }

  /// Inserts all [ShortLinkInviteData]s in the list and returns the inserted rows.
  ///
  /// The returned [ShortLinkInviteData]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  Future<List<ShortLinkInviteData>> insert(
    _i1.Session session,
    List<ShortLinkInviteData> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insert<ShortLinkInviteData>(
      rows,
      transaction: transaction,
    );
  }

  /// Inserts a single [ShortLinkInviteData] and returns the inserted row.
  ///
  /// The returned [ShortLinkInviteData] will have its `id` field set.
  Future<ShortLinkInviteData> insertRow(
    _i1.Session session,
    ShortLinkInviteData row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<ShortLinkInviteData>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [ShortLinkInviteData]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<ShortLinkInviteData>> update(
    _i1.Session session,
    List<ShortLinkInviteData> rows, {
    _i1.ColumnSelections<ShortLinkInviteDataTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<ShortLinkInviteData>(
      rows,
      columns: columns?.call(ShortLinkInviteData.t),
      transaction: transaction,
    );
  }

  /// Updates a single [ShortLinkInviteData]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<ShortLinkInviteData> updateRow(
    _i1.Session session,
    ShortLinkInviteData row, {
    _i1.ColumnSelections<ShortLinkInviteDataTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<ShortLinkInviteData>(
      row,
      columns: columns?.call(ShortLinkInviteData.t),
      transaction: transaction,
    );
  }

  /// Deletes all [ShortLinkInviteData]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<ShortLinkInviteData>> delete(
    _i1.Session session,
    List<ShortLinkInviteData> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<ShortLinkInviteData>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [ShortLinkInviteData].
  Future<ShortLinkInviteData> deleteRow(
    _i1.Session session,
    ShortLinkInviteData row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<ShortLinkInviteData>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<ShortLinkInviteData>> deleteWhere(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<ShortLinkInviteDataTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<ShortLinkInviteData>(
      where: where(ShortLinkInviteData.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<ShortLinkInviteDataTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<ShortLinkInviteData>(
      where: where?.call(ShortLinkInviteData.t),
      limit: limit,
      transaction: transaction,
    );
  }
}
