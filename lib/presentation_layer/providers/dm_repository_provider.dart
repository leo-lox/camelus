import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data_layer/db/object_box_camelus/db_camelus.dart';
import '../../data_layer/repositories/direct_message_repository_impl.dart';
import '../../domain_layer/repositories/direct_message_repository.dart';
import 'db_app_provider.dart';
import 'ndk_provider.dart';

/// Provider for the DirectMessageRepository.
///
/// This provides the repository for DM operations using NDK and ObjectBox.
final dmRepositoryProvider = Provider<DirectMessageRepository?>((ref) {
  final ndk = ref.watch(ndkProvider);
  final dbApp = ref.watch(dbAppProvider);

  // Get the current user's pubkey
  final myPubkey = ndk.accounts.getPublicKey();
  if (myPubkey == null) {
    return null; // User not logged in
  }

  // Cast to get access to store
  final dbImpl = dbApp as DbAppImpl;

  final repository = DirectMessageRepositoryImpl(
    ndk: ndk,
    getStore: () => dbImpl.store,
    myPubkey: myPubkey,
  );

  // Clean up on dispose
  ref.onDispose(() {
    repository.dispose();
  });

  return repository;
});
