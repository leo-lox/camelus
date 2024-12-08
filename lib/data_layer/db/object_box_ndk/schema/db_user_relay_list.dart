import 'dart:convert';

import 'package:ndk/entities.dart';
import 'package:objectbox/objectbox.dart';
import 'package:ndk/entities.dart' as ndk_entities;

@Entity()
class DbUserRelayList {
  @Id()
  int dbId = 0;

  @Property()
  String pubKey;

  @Property()
  int createdAt;

  @Property()
  int refreshedTimestamp;

  @Property()
  String relaysJson;

  DbUserRelayList({
    required this.pubKey,
    required this.relaysJson,
    required this.createdAt,
    required this.refreshedTimestamp,
  });

  // Convert from UserRelayList to DbUserRelayList
  static DbUserRelayList fromNdk(ndk_entities.UserRelayList userRelayList) {
    return DbUserRelayList(
      pubKey: userRelayList.pubKey,
      relaysJson: _encodeRelays(userRelayList.relays),
      createdAt: userRelayList.createdAt,
      refreshedTimestamp: userRelayList.refreshedTimestamp,
    );
  }

  // Convert to NDK model
  ndk_entities.UserRelayList toNdk() {
    return UserRelayList(
      pubKey: pubKey,
      relays: _decodeRelays(relaysJson),
      createdAt: createdAt,
      refreshedTimestamp: refreshedTimestamp,
    );
  }

  // Helper method to encode relays map to JSON string
  static String _encodeRelays(Map<String, ReadWriteMarker> relays) {
    return json
        .encode(relays.map((key, value) => MapEntry(key, value.toString())));
  }

  // Helper method to decode JSON string to relays map
  static Map<String, ReadWriteMarker> _decodeRelays(String relaysJson) {
    Map<String, dynamic> decodedMap = json.decode(relaysJson);
    return decodedMap.map((key, value) => MapEntry(
        key, ReadWriteMarker.values.firstWhere((e) => e.toString() == value)));
  }
}
