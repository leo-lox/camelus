import 'package:camelus/providers/database_provider.dart';
import 'package:camelus/providers/key_pair_provider.dart';
import 'package:camelus/services/nostr/nostr_service.dart';
import 'package:riverpod/riverpod.dart';

final nostrServiceProvider = Provider<NostrService>((ref) {
  var db = ref.watch(databaseProvider.future);
  var keyPairWrapper = ref.watch(keyPairProvider.future);
  var nostrService = NostrService(database: db, keyPairWrapper: keyPairWrapper);

  return nostrService;
});
