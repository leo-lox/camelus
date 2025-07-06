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

abstract class OtsoGeoSubscription implements _i1.SerializableModel {
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

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  String pubKey;

  String geohash;

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
