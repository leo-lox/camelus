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

abstract class TrendsTopItem implements _i1.SerializableModel {
  TrendsTopItem._({
    required this.tag,
    required this.count,
  });

  factory TrendsTopItem({
    required String tag,
    required int count,
  }) = _TrendsTopItemImpl;

  factory TrendsTopItem.fromJson(Map<String, dynamic> jsonSerialization) {
    return TrendsTopItem(
      tag: jsonSerialization['tag'] as String,
      count: jsonSerialization['count'] as int,
    );
  }

  String tag;

  int count;

  /// Returns a shallow copy of this [TrendsTopItem]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  TrendsTopItem copyWith({
    String? tag,
    int? count,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'TrendsTopItem',
      'tag': tag,
      'count': count,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _TrendsTopItemImpl extends TrendsTopItem {
  _TrendsTopItemImpl({
    required String tag,
    required int count,
  }) : super._(
         tag: tag,
         count: count,
       );

  /// Returns a shallow copy of this [TrendsTopItem]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  TrendsTopItem copyWith({
    String? tag,
    int? count,
  }) {
    return TrendsTopItem(
      tag: tag ?? this.tag,
      count: count ?? this.count,
    );
  }
}
