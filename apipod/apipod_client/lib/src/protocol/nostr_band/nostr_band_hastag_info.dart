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

abstract class NostrBandHashtagInfo implements _i1.SerializableModel {
  NostrBandHashtagInfo._({
    required this.hashtag,
    required this.posts,
  });

  factory NostrBandHashtagInfo({
    required String hashtag,
    required int posts,
  }) = _NostrBandHashtagInfoImpl;

  factory NostrBandHashtagInfo.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return NostrBandHashtagInfo(
      hashtag: jsonSerialization['hashtag'] as String,
      posts: jsonSerialization['posts'] as int,
    );
  }

  String hashtag;

  int posts;

  /// Returns a shallow copy of this [NostrBandHashtagInfo]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  NostrBandHashtagInfo copyWith({
    String? hashtag,
    int? posts,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'NostrBandHashtagInfo',
      'hashtag': hashtag,
      'posts': posts,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _NostrBandHashtagInfoImpl extends NostrBandHashtagInfo {
  _NostrBandHashtagInfoImpl({
    required String hashtag,
    required int posts,
  }) : super._(
         hashtag: hashtag,
         posts: posts,
       );

  /// Returns a shallow copy of this [NostrBandHashtagInfo]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  NostrBandHashtagInfo copyWith({
    String? hashtag,
    int? posts,
  }) {
    return NostrBandHashtagInfo(
      hashtag: hashtag ?? this.hashtag,
      posts: posts ?? this.posts,
    );
  }
}
