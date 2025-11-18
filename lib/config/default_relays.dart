import 'package:ndk/entities.dart' as ndk_entities;

List<String> camelusBootstrapRelays = [
  "wss://nos.lol",
  "wss://relay.damus.io",
  "wss://relay.nostr.band",
  "wss://relay.snort.social",
  "wss://relay.nostr.band",
  "wss://relay.mostr.pub",
  "wss://relay.camelus.app",
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

/// Default read-only pubkey for anonymous users (before login)
/// This is a well-known public account used to populate the feed for new users
/// Users can follow popular accounts through this read-only view
const String defaultReadOnlyPubkey =
    "3bf0c63fcb93463407af97a5e5ee64fa883d107ef9e558472c4eb9aaaefa459d"; // fiatjaf's pubkey
