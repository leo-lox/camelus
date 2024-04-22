import 'package:camelus/presentation_layer/providers/key_pair_provider.dart';
import 'package:camelus/services/nostr/metadata/block_mute_service.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'database_provider.dart';

final blockMuteProvider = FutureProvider<BlockMuteService>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  final keypair = await ref.watch(keyPairProvider.future);

  final blockMuteService = BlockMuteService(db: db, keyService: keypair);

  return blockMuteService;
});
