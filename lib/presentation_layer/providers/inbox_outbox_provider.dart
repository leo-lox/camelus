import 'package:riverpod/riverpod.dart';

import '../../data_layer/data_sources/dart_ndk_source.dart';
import '../../data_layer/repositories/inbox_outbox_repository_impl.dart';
import '../../domain_layer/repositories/inbox_outbox_repository.dart';
import '../../domain_layer/usecases/inbox_outbox.dart';
import 'ndk_provider.dart';

final inboxOutboxProvider = Provider<InboxOutbox>((ref) {
  final ndk = ref.watch(ndkProvider);

  final DartNdkSource dartNdkSource = DartNdkSource(ndk);

  final InboxOutboxRepository inboxOutboxRepository = InboxOutboxRepositoryImpl(
    dartNdkSource: dartNdkSource,
  );

  final InboxOutbox inboxOutbox = InboxOutbox(
    repository: inboxOutboxRepository,
  );

  return inboxOutbox;
});
