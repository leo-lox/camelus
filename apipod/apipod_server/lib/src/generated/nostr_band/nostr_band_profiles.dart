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
import 'package:ndk/data_layer/models/nip_01_event_model.dart' as _i2;
import 'package:apipod_server/src/generated/protocol.dart' as _i3;

abstract class NostrBandProfiles
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  NostrBandProfiles._({
    required this.pubkey,
    required this.newFollowersCount,
    required this.relays,
    required this.profile,
  });

  factory NostrBandProfiles({
    required String pubkey,
    required int newFollowersCount,
    required List<String> relays,
    required _i2.Nip01EventModel profile,
  }) = _NostrBandProfilesImpl;

  factory NostrBandProfiles.fromJson(Map<String, dynamic> jsonSerialization) {
    return NostrBandProfiles(
      pubkey: jsonSerialization['pubkey'] as String,
      newFollowersCount: jsonSerialization['newFollowersCount'] as int,
      relays: _i3.Protocol().deserialize<List<String>>(
        jsonSerialization['relays'],
      ),
      profile: _i2.Nip01EventModel.fromJson(jsonSerialization['profile']),
    );
  }

  String pubkey;

  int newFollowersCount;

  List<String> relays;

  _i2.Nip01EventModel profile;

  /// Returns a shallow copy of this [NostrBandProfiles]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  NostrBandProfiles copyWith({
    String? pubkey,
    int? newFollowersCount,
    List<String>? relays,
    _i2.Nip01EventModel? profile,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'NostrBandProfiles',
      'pubkey': pubkey,
      'newFollowersCount': newFollowersCount,
      'relays': relays.toJson(),
      'profile': profile.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'NostrBandProfiles',
      'pubkey': pubkey,
      'newFollowersCount': newFollowersCount,
      'relays': relays.toJson(),
      'profile':
          // ignore: unnecessary_type_check
          profile is _i1.ProtocolSerialization
          ? (profile as _i1.ProtocolSerialization).toJsonForProtocol()
          : profile.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _NostrBandProfilesImpl extends NostrBandProfiles {
  _NostrBandProfilesImpl({
    required String pubkey,
    required int newFollowersCount,
    required List<String> relays,
    required _i2.Nip01EventModel profile,
  }) : super._(
         pubkey: pubkey,
         newFollowersCount: newFollowersCount,
         relays: relays,
         profile: profile,
       );

  /// Returns a shallow copy of this [NostrBandProfiles]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  NostrBandProfiles copyWith({
    String? pubkey,
    int? newFollowersCount,
    List<String>? relays,
    _i2.Nip01EventModel? profile,
  }) {
    return NostrBandProfiles(
      pubkey: pubkey ?? this.pubkey,
      newFollowersCount: newFollowersCount ?? this.newFollowersCount,
      relays: relays ?? this.relays.map((e0) => e0).toList(),
      profile: profile ?? this.profile.copyWith(),
    );
  }
}
