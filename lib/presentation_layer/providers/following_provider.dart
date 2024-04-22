import 'package:camelus/presentation_layer/providers/database_provider.dart';
import 'package:camelus/presentation_layer/providers/key_pair_provider.dart';
import 'package:camelus/presentation_layer/providers/relay_provider.dart';
import 'package:camelus/services/nostr/metadata/following_pubkeys.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

var followingProvider = Provider<FollowingPubkeys>((ref) {
  final keyPair = ref.watch(keyPairProvider.future);
  final db = ref.watch(databaseProvider.future);
  final relays = ref.watch(relayServiceProvider);

  final followingPubkeys =
      FollowingPubkeys(keyPair: keyPair, db: db, relays: relays);

  return followingPubkeys;
});
