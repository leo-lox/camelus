import 'package:camelus/providers/database_provider.dart';
import 'package:camelus/services/nostr/metadata/nip_05.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final nip05provider = FutureProvider<Nip05>((ref) async {
  var db = await ref.watch(databaseProvider.future);

  var nip05 = Nip05(db: db);

  return nip05;
});
