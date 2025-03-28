/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod_client/serverpod_client.dart' as _i1;

abstract class PushSubscription implements _i1.SerializableModel {
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

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  String pubKey;

  String relay;

  String token;

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
