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

abstract class BloomFilterProfile implements _i1.SerializableModel {
  BloomFilterProfile._({
    this.id,
    required this.size,
    required this.numHashFunctions,
    required this.bitArray,
    required this.createdAt,
    this.name,
    this.description,
  });

  factory BloomFilterProfile({
    int? id,
    required int size,
    required int numHashFunctions,
    required String bitArray,
    required DateTime createdAt,
    String? name,
    String? description,
  }) = _BloomFilterProfileImpl;

  factory BloomFilterProfile.fromJson(Map<String, dynamic> jsonSerialization) {
    return BloomFilterProfile(
      id: jsonSerialization['id'] as int?,
      size: jsonSerialization['size'] as int,
      numHashFunctions: jsonSerialization['numHashFunctions'] as int,
      bitArray: jsonSerialization['bitArray'] as String,
      createdAt:
          _i1.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
      name: jsonSerialization['name'] as String?,
      description: jsonSerialization['description'] as String?,
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int size;

  int numHashFunctions;

  String bitArray;

  DateTime createdAt;

  String? name;

  String? description;

  /// Returns a shallow copy of this [BloomFilterProfile]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  BloomFilterProfile copyWith({
    int? id,
    int? size,
    int? numHashFunctions,
    String? bitArray,
    DateTime? createdAt,
    String? name,
    String? description,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'size': size,
      'numHashFunctions': numHashFunctions,
      'bitArray': bitArray,
      'createdAt': createdAt.toJson(),
      if (name != null) 'name': name,
      if (description != null) 'description': description,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _BloomFilterProfileImpl extends BloomFilterProfile {
  _BloomFilterProfileImpl({
    int? id,
    required int size,
    required int numHashFunctions,
    required String bitArray,
    required DateTime createdAt,
    String? name,
    String? description,
  }) : super._(
          id: id,
          size: size,
          numHashFunctions: numHashFunctions,
          bitArray: bitArray,
          createdAt: createdAt,
          name: name,
          description: description,
        );

  /// Returns a shallow copy of this [BloomFilterProfile]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  BloomFilterProfile copyWith({
    Object? id = _Undefined,
    int? size,
    int? numHashFunctions,
    String? bitArray,
    DateTime? createdAt,
    Object? name = _Undefined,
    Object? description = _Undefined,
  }) {
    return BloomFilterProfile(
      id: id is int? ? id : this.id,
      size: size ?? this.size,
      numHashFunctions: numHashFunctions ?? this.numHashFunctions,
      bitArray: bitArray ?? this.bitArray,
      createdAt: createdAt ?? this.createdAt,
      name: name is String? ? name : this.name,
      description: description is String? ? description : this.description,
    );
  }
}
