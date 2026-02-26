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
import 'package:serverpod/serverpod.dart' as _i1;
import '../trends/trends_top_item.dart' as _i2;
import 'package:apipod_server/src/generated/protocol.dart' as _i3;

abstract class TrendsResponse
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  TrendsResponse._({
    required this.success,
    this.error,
    this.interval,
    this.windowHours,
    this.bucketMinutes,
    this.generatedAt,
    required this.top,
    required this.people,
    this.limit,
  });

  factory TrendsResponse({
    required bool success,
    String? error,
    String? interval,
    int? windowHours,
    int? bucketMinutes,
    DateTime? generatedAt,
    required List<_i2.TrendsTopItem> top,
    required List<_i2.TrendsTopItem> people,
    int? limit,
  }) = _TrendsResponseImpl;

  factory TrendsResponse.fromJson(Map<String, dynamic> jsonSerialization) {
    return TrendsResponse(
      success: jsonSerialization['success'] as bool,
      error: jsonSerialization['error'] as String?,
      interval: jsonSerialization['interval'] as String?,
      windowHours: jsonSerialization['windowHours'] as int?,
      bucketMinutes: jsonSerialization['bucketMinutes'] as int?,
      generatedAt: jsonSerialization['generatedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['generatedAt'],
            ),
      top: _i3.Protocol().deserialize<List<_i2.TrendsTopItem>>(
        jsonSerialization['top'],
      ),
      people: _i3.Protocol().deserialize<List<_i2.TrendsTopItem>>(
        jsonSerialization['people'],
      ),
      limit: jsonSerialization['limit'] as int?,
    );
  }

  bool success;

  String? error;

  String? interval;

  int? windowHours;

  int? bucketMinutes;

  DateTime? generatedAt;

  List<_i2.TrendsTopItem> top;

  List<_i2.TrendsTopItem> people;

  int? limit;

  /// Returns a shallow copy of this [TrendsResponse]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  TrendsResponse copyWith({
    bool? success,
    String? error,
    String? interval,
    int? windowHours,
    int? bucketMinutes,
    DateTime? generatedAt,
    List<_i2.TrendsTopItem>? top,
    List<_i2.TrendsTopItem>? people,
    int? limit,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'TrendsResponse',
      'success': success,
      if (error != null) 'error': error,
      if (interval != null) 'interval': interval,
      if (windowHours != null) 'windowHours': windowHours,
      if (bucketMinutes != null) 'bucketMinutes': bucketMinutes,
      if (generatedAt != null) 'generatedAt': generatedAt?.toJson(),
      'top': top.toJson(valueToJson: (v) => v.toJson()),
      'people': people.toJson(valueToJson: (v) => v.toJson()),
      if (limit != null) 'limit': limit,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'TrendsResponse',
      'success': success,
      if (error != null) 'error': error,
      if (interval != null) 'interval': interval,
      if (windowHours != null) 'windowHours': windowHours,
      if (bucketMinutes != null) 'bucketMinutes': bucketMinutes,
      if (generatedAt != null) 'generatedAt': generatedAt?.toJson(),
      'top': top.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      'people': people.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      if (limit != null) 'limit': limit,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _TrendsResponseImpl extends TrendsResponse {
  _TrendsResponseImpl({
    required bool success,
    String? error,
    String? interval,
    int? windowHours,
    int? bucketMinutes,
    DateTime? generatedAt,
    required List<_i2.TrendsTopItem> top,
    required List<_i2.TrendsTopItem> people,
    int? limit,
  }) : super._(
         success: success,
         error: error,
         interval: interval,
         windowHours: windowHours,
         bucketMinutes: bucketMinutes,
         generatedAt: generatedAt,
         top: top,
         people: people,
         limit: limit,
       );

  /// Returns a shallow copy of this [TrendsResponse]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  TrendsResponse copyWith({
    bool? success,
    Object? error = _Undefined,
    Object? interval = _Undefined,
    Object? windowHours = _Undefined,
    Object? bucketMinutes = _Undefined,
    Object? generatedAt = _Undefined,
    List<_i2.TrendsTopItem>? top,
    List<_i2.TrendsTopItem>? people,
    Object? limit = _Undefined,
  }) {
    return TrendsResponse(
      success: success ?? this.success,
      error: error is String? ? error : this.error,
      interval: interval is String? ? interval : this.interval,
      windowHours: windowHours is int? ? windowHours : this.windowHours,
      bucketMinutes: bucketMinutes is int? ? bucketMinutes : this.bucketMinutes,
      generatedAt: generatedAt is DateTime? ? generatedAt : this.generatedAt,
      top: top ?? this.top.map((e0) => e0.copyWith()).toList(),
      people: people ?? this.people.map((e0) => e0.copyWith()).toList(),
      limit: limit is int? ? limit : this.limit,
    );
  }
}
