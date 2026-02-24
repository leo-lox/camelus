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

abstract class TrendsSnapshot implements _i1.SerializableModel {
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

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  DateTime createdAt;

  String interval;

  String payloadJson;

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
