import '../../domain_layer/entities/nostr_band_people.dart';
import 'nostr_note_model.dart';

class NostrBandPeopleModel extends NostrBandPeople {
  NostrBandPeopleModel({required super.profiles});

  factory NostrBandPeopleModel.fromJson(Map<String, dynamic> json) {
    List<dynamic> profilesJson = json['profiles'] ?? [];
    List<ProfilesModel> profiles = profilesJson
        .map((profile) => ProfilesModel.fromJson(profile))
        .toList();

    return NostrBandPeopleModel(profiles: profiles);
  }

  Map<String, dynamic> toJson() {
    return {
      'profiles': profiles
          .map((profile) => (profile as ProfilesModel).toJson())
          .toList(),
    };
  }
}

class ProfilesModel extends Profiles {
  ProfilesModel({
    required super.pubkey,
    required super.newFollowersCount,
    required super.relays,
    required super.profile,
  });

  factory ProfilesModel.fromJson(Map<String, dynamic> json) {
    return ProfilesModel(
      pubkey: json['pubkey'] ?? '',
      newFollowersCount: json['new_followers_count'] ?? 0,
      relays: [], //List<String>.from(json['relays'] ?? []),
      profile: NostrNoteModel.fromJson(json['profile']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pubkey': pubkey,
      'new_followers_count': newFollowersCount,
      'relays': relays,
      'profile': (profile as NostrNoteModel).toJson(),
    };
  }
}
