import 'package:camelus/models/nostr_note.dart';

class ApiNostrBand {
  final List<Profiles> profiles;

  ApiNostrBand({required this.profiles});

  factory ApiNostrBand.fromJson(Map<String, dynamic> json) {
    List<dynamic> profilesJson = json['profiles'] ?? [];
    List<Profiles> profiles = [];
    //cast using for loop
    for (Map<String, dynamic> profile in profilesJson) {
      profiles.add(Profiles.fromJson(profile));
    }

    return ApiNostrBand(
      profiles: profiles,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['profiles'] = profiles.map((v) => v.toJson()).toList();
    return data;
  }
}

class Profiles {
  String pubkey;
  int newFollowersCount;
  List<String> relays;
  NostrNote profile;

  Profiles(
      {required this.pubkey,
      required this.newFollowersCount,
      required this.relays,
      required this.profile});

  factory Profiles.fromJson(Map<String, dynamic> json) {
    List<dynamic> relaysJson = json['relays'] ?? [];
    List<String> relays = [];
    //cast using for loop
    for (String relay in relaysJson) {
      relays.add(relay);
    }

    return Profiles(
      pubkey: json['pubkey'],
      newFollowersCount: json['new_followers_count'],
      relays: relays,
      profile: NostrNote.fromJson(json['profile']),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['pubkey'] = pubkey;
    data['new_followers_count'] = this.newFollowersCount;
    data['relays'] = relays;
    data['profile'] = profile.toJson();
    return data;
  }
}
