import 'package:ndk/entities.dart' as ndk_entities;

List<String> camelusBootstrapRelays = [
  "ws://localhost:10547",
  "wss://relay.damus.io",
];

final Map<String, ndk_entities.ReadWriteMarker> defaultAccountCreationRelays = {
  // read
  "wss://relay.nostr.band": ndk_entities.ReadWriteMarker.readOnly,
  "wss://nostr.wine": ndk_entities.ReadWriteMarker.readOnly,
  "wss://relay.mostr.pub": ndk_entities.ReadWriteMarker.readOnly,
  "wss://pyramid.fiatjaf.com": ndk_entities.ReadWriteMarker.readOnly,
  // read write
  "wss://relay.damus.io": ndk_entities.ReadWriteMarker.readWrite,
  "wss://nos.lol": ndk_entities.ReadWriteMarker.readWrite,
  "wss://relay.snort.social": ndk_entities.ReadWriteMarker.readWrite,
};
