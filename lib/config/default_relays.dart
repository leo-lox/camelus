import 'package:ndk/entities.dart' as ndk_entities;

List<String> CAMELUS_BOOTSTRAP_RELAYS = [
  "wss://strfry.iris.to",
  "wss://relay.damus.io",
  "wss://relay.nostr.band",
  "wss://relay.snort.social",
  "wss://relay.nostr.band",
  "wss://relay.mostr.pub",
  "wss://relay.camelus.app",
];

final Map<String, ndk_entities.ReadWriteMarker>
    DEFAULT_ACCOUNT_CREATION_RELAYS = {
  // read
  "wss://relay.nostr.band": ndk_entities.ReadWriteMarker.readOnly,
  "wss://nos.lol": ndk_entities.ReadWriteMarker.readOnly,
  "wss://nostr.wine": ndk_entities.ReadWriteMarker.readOnly,
  "wss://relay.mostr.pub": ndk_entities.ReadWriteMarker.readOnly,
  "wss://countries.fiatjaf.com": ndk_entities.ReadWriteMarker.readOnly,
  // read write
  "wss://relay.damus.io": ndk_entities.ReadWriteMarker.readWrite,
  "wss://strfry.iris.to": ndk_entities.ReadWriteMarker.readWrite,
  "wss://relay.snort.social": ndk_entities.ReadWriteMarker.readWrite,
};
