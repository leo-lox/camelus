import 'package:camelus/db/database.dart';
import 'package:camelus/providers/database_provider.dart';
import 'package:camelus/providers/key_pair_provider.dart';
import 'package:camelus/services/nostr/metadata/following_pubkeys.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final followingProvider = FutureProvider<FollowingPubkeys>((ref) async {
  final futureKeyPair = ref.watch(keyPairProvider.future);
  final futureDb = ref.watch(databaseProvider.future);

  final futures = await Future.wait([futureKeyPair, futureDb]);

  final KeyPairWrapper keyPair = futures[0] as KeyPairWrapper;
  final AppDatabase db = futures[1] as AppDatabase;

  final followingPubkeys =
      FollowingPubkeys(pubkey: keyPair.keyPair!.publicKey, db: db);

  return followingPubkeys;
});
