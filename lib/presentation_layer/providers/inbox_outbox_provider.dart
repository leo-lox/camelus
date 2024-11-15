import 'package:riverpod/riverpod.dart';

import '../../data_layer/data_sources/dart_ndk_source.dart';
import '../../data_layer/repositories/inbox_outbox_repository_impl.dart';
import '../../domain_layer/repositories/inbox_outbox_repository.dart';
import '../../domain_layer/usecases/inbox_outbox.dart';
import 'ndk_provider.dart';

// Provider for managing the "InboxOutbox" use case.
// This provider creates and returns an instance of InboxOutbox, 
// which handles operations related to inbox and outbox functionality.
final inboxOutboxProvider = Provider<InboxOutbox>((ref) {
  final ndk = ref.watch(ndkProvider);

  final DartNdkSource dartNdkSource = DartNdkSource(ndk);

  final InboxOutboxRepository inboxOutboxRepository = InboxOutboxRepositoryImpl(
    dartNdkSource: dartNdkSource,
  );

  final InboxOutbox inboxOutbox = InboxOutbox(
    repository: inboxOutboxRepository,
  );

  // Returns the InboxOutbox instance
  return inboxOutbox;
});
