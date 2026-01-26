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
import 'package:serverpod_client/serverpod_client.dart' as _i1;

abstract class OtsoExternalSync implements _i1.SerializableModel {
  OtsoExternalSync._({
    this.id,
    required this.itemId,
    required this.source,
    required this.syncedAt,
  });

  factory OtsoExternalSync({
    int? id,
    required int itemId,
    required String source,
    required DateTime syncedAt,
  }) = _OtsoExternalSyncImpl;

  factory OtsoExternalSync.fromJson(Map<String, dynamic> jsonSerialization) {
    return OtsoExternalSync(
      id: jsonSerialization['id'] as int?,
      itemId: jsonSerialization['itemId'] as int,
      source: jsonSerialization['source'] as String,
      syncedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['syncedAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int itemId;

  String source;

  DateTime syncedAt;

  /// Returns a shallow copy of this [OtsoExternalSync]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  OtsoExternalSync copyWith({
    int? id,
    int? itemId,
    String? source,
    DateTime? syncedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'OtsoExternalSync',
      if (id != null) 'id': id,
      'itemId': itemId,
      'source': source,
      'syncedAt': syncedAt.toJson(),
    };
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
    required String source,
    required DateTime syncedAt,
  }) : super._(
         id: id,
         itemId: itemId,
         source: source,
         syncedAt: syncedAt,
       );

  /// Returns a shallow copy of this [OtsoExternalSync]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  OtsoExternalSync copyWith({
    Object? id = _Undefined,
    int? itemId,
    String? source,
    DateTime? syncedAt,
  }) {
    return OtsoExternalSync(
      id: id is int? ? id : this.id,
      itemId: itemId ?? this.itemId,
      source: source ?? this.source,
      syncedAt: syncedAt ?? this.syncedAt,
    );
  }
}
