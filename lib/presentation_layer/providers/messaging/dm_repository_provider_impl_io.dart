import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data_layer/db/object_box_camelus/db_camelus.dart';
import '../../../data_layer/repositories/direct_message_repository_impl.dart';
import '../../../domain_layer/repositories/direct_message_repository.dart';
import '../inbox_outbox_provider.dart';
import '../db_app_provider.dart';
import '../ndk_provider.dart';
import '../signer_provider.dart';

DirectMessageRepository? createDmRepository(Ref ref) {
  final ndk = ref.watch(ndkProvider);
  final dbApp = ref.watch(dbAppProvider);
  final signer = ref.watch(signerProvider);
  final inboxOutbox = ref.watch(inboxOutboxProvider);
  if (signer == null) {
    return null;
  }

  final dbImpl = dbApp as DbAppImpl;

  final repository = DirectMessageRepositoryImpl(
    ndk: ndk,
    getStore: () => dbImpl.store,
    myPubkey: signer.getPublicKey(),
    inboxOutbox: inboxOutbox,
  );

  ref.onDispose(() {
    repository.dispose();
  });

  return repository;
}
