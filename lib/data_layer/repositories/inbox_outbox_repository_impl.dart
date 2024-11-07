import '../../domain_layer/entities/nip_65.dart';
import '../../domain_layer/repositories/inbox_outbox_repository.dart';
import '../data_sources/dart_ndk_source.dart';
import '../models/nip_65_model.dart';

class InboxOutboxRepositoryImpl implements InboxOutboxRepository {
  final DartNdkSource dartNdkSource;

  InboxOutboxRepositoryImpl({
    required this.dartNdkSource,
  });
  @override
  Future<Nip65> setNip65data(Nip65 newNip65) async {
    final Nip65Model nip65model = Nip65Model(
      createdAt: newNip65.createdAt,
      pubKey: newNip65.pubKey,
      relays: newNip65.relays,
    );

    await dartNdkSource.dartNdk.inboxOutbox.setInboxOutbox(
      nip65model.toNdk(),
      customRelays: newNip65.relays.keys,
    );

    return newNip65;
  }
}
