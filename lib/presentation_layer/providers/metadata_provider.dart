import 'package:camelus/presentation_layer/providers/database_provider.dart';
import 'package:camelus/presentation_layer/providers/relay_provider.dart';
import 'package:camelus/services/nostr/metadata/user_metadata.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final metadataProvider = Provider<UserMetadata>((ref) {
  var relays = ref.watch(relayServiceProvider);
  var db = ref.watch(databaseProvider.future);

  var metadata = UserMetadata(
    relays: relays,
    dbFuture: db,
  );

  return metadata;
});
