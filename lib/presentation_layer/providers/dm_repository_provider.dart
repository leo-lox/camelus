import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data_layer/db/object_box_camelus/db_camelus.dart';
import '../../data_layer/repositories/direct_message_repository_impl.dart';
import '../../domain_layer/repositories/direct_message_repository.dart';
import 'db_app_provider.dart';
import 'ndk_provider.dart';
import 'signer_provider.dart';

/// Provider for the DirectMessageRepository.
///
/// This provides the repository for DM operations using NDK and ObjectBox.
final dmRepositoryProvider = Provider<DirectMessageRepository?>((ref) {
  final ndk = ref.watch(ndkProvider);
  final dbApp = ref.watch(dbAppProvider);
  // Watch signer to rebuild when user logs in/out
  final signer = ref.watch(signerProvider);
  if (signer == null) {
    return null; // User not logged in
  }

  // Cast to get access to store
  final dbImpl = dbApp as DbAppImpl;

  final repository = DirectMessageRepositoryImpl(
    ndk: ndk,
    getStore: () => dbImpl.store,
    myPubkey: signer.getPublicKey(),
  );

  // Clean up on dispose
  ref.onDispose(() {
    repository.dispose();
  });

  return repository;
});
