import 'package:camelus/providers/database_provider.dart';
import 'package:camelus/providers/isar_database_provider.dart';
import 'package:camelus/providers/key_pair_provider.dart';
import 'package:camelus/services/nostr/relays/relay_coordinator.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final relayServiceProvider = Provider<RelayCoordinator>((ref) {
  var db = ref.watch(databaseProvider.future);
  var isarDb = ref.watch(isarDatabaseProvider.future);
  var keypair = ref.watch(keyPairProvider.future);

  var relayService = RelayCoordinator(
    dbFuture: db,
    isarDbFuture: isarDb,
    keyPairFuture: keypair,
  );

  return relayService;
});
