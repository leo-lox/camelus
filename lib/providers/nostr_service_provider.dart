import 'package:camelus/providers/database_provider.dart';
import 'package:camelus/services/nostr/nostr_service.dart';
import 'package:riverpod/riverpod.dart';

final nostrServiceProvider = Provider<NostrService>((ref) {
  var db = ref.watch(databaseProvider.future);
  var nostrService = NostrService(database: db);

  return nostrService;
});
