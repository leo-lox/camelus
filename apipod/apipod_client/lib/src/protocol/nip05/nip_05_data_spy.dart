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

abstract class Nip05Data implements _i1.SerializableModel {
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

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  String name;

  String domain;

  String pubkey;

  List<String> relays;

  DateTime createdAt;

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
