import 'package:camelus/data_layer/models/nostr_note.dart';

import '../../domain_layer/entities/nostr_band_people.dart';

class NostrBandPeopleModel extends NostrBandPeople {
  NostrBandPeopleModel({required super.profiles});

  factory NostrBandPeopleModel.fromJson(Map<String, dynamic> json) {
    List<dynamic> profilesJson = json['profiles'] ?? [];
    List<ProfilesModel> profiles = [];
    //cast using for loop
    for (Map<String, dynamic> profile in profilesJson) {
      profiles.add(ProfilesModel.fromJson(profile));
    }

    return NostrBandPeopleModel(
      profiles: profiles,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['profiles'] = profiles
        .map((v) => {
              ProfilesModel(
                newFollowersCount: v.newFollowersCount,
                profile: v.profile,
                pubkey: v.pubkey,
                relays: v.relays,
              ).toJson()
            })
        .toList();

    return data;
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
    List<dynamic> relaysJson = json['relays'] ?? [];
    List<String> relays = [];
    //cast using for loop
    for (String relay in relaysJson) {
      relays.add(relay);
    }

    return ProfilesModel(
      pubkey: json['pubkey'],
      newFollowersCount: json['new_followers_count'],
      relays: relays,
      profile: NostrNote.fromJson(json['profile']),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['pubkey'] = pubkey;
    data['new_followers_count'] = newFollowersCount;
    data['relays'] = relays;
    data['profile'] = profile.toJson();
    return data;
  }
}
