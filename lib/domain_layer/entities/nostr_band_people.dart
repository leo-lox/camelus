import 'package:camelus/data_layer/models/nostr_note.dart';

class NostrBandPeople {
  final List<Profiles> profiles;

  NostrBandPeople({required this.profiles});
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
}
