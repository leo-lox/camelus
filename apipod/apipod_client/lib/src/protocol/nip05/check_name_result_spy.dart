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
import 'package:apipod_client/src/protocol/protocol.dart' as _i2;

abstract class NameCheckResult implements _i1.SerializableModel {
  NameCheckResult._({
    required this.isAvailable,
    this.reason,
    required this.suggestions,
  });

  factory NameCheckResult({
    required bool isAvailable,
    String? reason,
    required List<String> suggestions,
  }) = _NameCheckResultImpl;

  factory NameCheckResult.fromJson(Map<String, dynamic> jsonSerialization) {
    return NameCheckResult(
      isAvailable: jsonSerialization['isAvailable'] as bool,
      reason: jsonSerialization['reason'] as String?,
      suggestions: _i2.Protocol().deserialize<List<String>>(
        jsonSerialization['suggestions'],
      ),
    );
  }

  bool isAvailable;

  String? reason;

  List<String> suggestions;

  /// Returns a shallow copy of this [NameCheckResult]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  NameCheckResult copyWith({
    bool? isAvailable,
    String? reason,
    List<String>? suggestions,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'NameCheckResult',
      'isAvailable': isAvailable,
      if (reason != null) 'reason': reason,
      'suggestions': suggestions.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _NameCheckResultImpl extends NameCheckResult {
  _NameCheckResultImpl({
    required bool isAvailable,
    String? reason,
    required List<String> suggestions,
  }) : super._(
         isAvailable: isAvailable,
         reason: reason,
         suggestions: suggestions,
       );

  /// Returns a shallow copy of this [NameCheckResult]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  NameCheckResult copyWith({
    bool? isAvailable,
    Object? reason = _Undefined,
    List<String>? suggestions,
  }) {
    return NameCheckResult(
      isAvailable: isAvailable ?? this.isAvailable,
      reason: reason is String? ? reason : this.reason,
      suggestions: suggestions ?? this.suggestions.map((e0) => e0).toList(),
    );
  }
}
