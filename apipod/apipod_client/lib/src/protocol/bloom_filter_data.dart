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

abstract class BloomFilterData implements _i1.SerializableModel {
  BloomFilterData._({
    required this.size,
    required this.numHashFunctions,
    required this.bitArray,
    required this.createdAt,
  });

  factory BloomFilterData({
    required int size,
    required int numHashFunctions,
    required String bitArray,
    required DateTime createdAt,
  }) = _BloomFilterDataImpl;

  factory BloomFilterData.fromJson(Map<String, dynamic> jsonSerialization) {
    return BloomFilterData(
      size: jsonSerialization['size'] as int,
      numHashFunctions: jsonSerialization['numHashFunctions'] as int,
      bitArray: jsonSerialization['bitArray'] as String,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  int size;

  int numHashFunctions;

  String bitArray;

  DateTime createdAt;

  /// Returns a shallow copy of this [BloomFilterData]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  BloomFilterData copyWith({
    int? size,
    int? numHashFunctions,
    String? bitArray,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'BloomFilterData',
      'size': size,
      'numHashFunctions': numHashFunctions,
      'bitArray': bitArray,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _BloomFilterDataImpl extends BloomFilterData {
  _BloomFilterDataImpl({
    required int size,
    required int numHashFunctions,
    required String bitArray,
    required DateTime createdAt,
  }) : super._(
         size: size,
         numHashFunctions: numHashFunctions,
         bitArray: bitArray,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [BloomFilterData]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  BloomFilterData copyWith({
    int? size,
    int? numHashFunctions,
    String? bitArray,
    DateTime? createdAt,
  }) {
    return BloomFilterData(
      size: size ?? this.size,
      numHashFunctions: numHashFunctions ?? this.numHashFunctions,
      bitArray: bitArray ?? this.bitArray,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
