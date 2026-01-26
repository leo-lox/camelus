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
import '../nostr_band/nostr_band_hastag_info.dart' as _i2;
import 'package:apipod_server/src/generated/protocol.dart' as _i3;

abstract class NostrBandHashtags
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  NostrBandHashtags._({required this.hashtags});

  factory NostrBandHashtags({
    required List<_i2.NostrBandHashtagInfo> hashtags,
  }) = _NostrBandHashtagsImpl;

  factory NostrBandHashtags.fromJson(Map<String, dynamic> jsonSerialization) {
    return NostrBandHashtags(
      hashtags: _i3.Protocol().deserialize<List<_i2.NostrBandHashtagInfo>>(
        jsonSerialization['hashtags'],
      ),
    );
  }

  List<_i2.NostrBandHashtagInfo> hashtags;

  /// Returns a shallow copy of this [NostrBandHashtags]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  NostrBandHashtags copyWith({List<_i2.NostrBandHashtagInfo>? hashtags});
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'NostrBandHashtags',
      'hashtags': hashtags.toJson(valueToJson: (v) => v.toJson()),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'NostrBandHashtags',
      'hashtags': hashtags.toJson(valueToJson: (v) => v.toJsonForProtocol()),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _NostrBandHashtagsImpl extends NostrBandHashtags {
  _NostrBandHashtagsImpl({required List<_i2.NostrBandHashtagInfo> hashtags})
    : super._(hashtags: hashtags);

  /// Returns a shallow copy of this [NostrBandHashtags]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  NostrBandHashtags copyWith({List<_i2.NostrBandHashtagInfo>? hashtags}) {
    return NostrBandHashtags(
      hashtags: hashtags ?? this.hashtags.map((e0) => e0.copyWith()).toList(),
    );
  }
}
