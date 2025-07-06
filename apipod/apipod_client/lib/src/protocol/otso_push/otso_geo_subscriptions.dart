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
    required this.pubkey,
    required this.geohash,
  });

  factory OtsoGeoSubscription({
    int? id,
    required String pubkey,
    required String geohash,
  }) = _OtsoGeoSubscriptionImpl;

  factory OtsoGeoSubscription.fromJson(Map<String, dynamic> jsonSerialization) {
    return OtsoGeoSubscription(
      id: jsonSerialization['id'] as int?,
      pubkey: jsonSerialization['pubkey'] as String,
      geohash: jsonSerialization['geohash'] as String,
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  String pubkey;

  String geohash;

  /// Returns a shallow copy of this [OtsoGeoSubscription]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  OtsoGeoSubscription copyWith({
    int? id,
    String? pubkey,
    String? geohash,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'pubkey': pubkey,
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
    required String pubkey,
    required String geohash,
  }) : super._(
          id: id,
          pubkey: pubkey,
          geohash: geohash,
        );

  /// Returns a shallow copy of this [OtsoGeoSubscription]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  OtsoGeoSubscription copyWith({
    Object? id = _Undefined,
    String? pubkey,
    String? geohash,
  }) {
    return OtsoGeoSubscription(
      id: id is int? ? id : this.id,
      pubkey: pubkey ?? this.pubkey,
      geohash: geohash ?? this.geohash,
    );
  }
}
