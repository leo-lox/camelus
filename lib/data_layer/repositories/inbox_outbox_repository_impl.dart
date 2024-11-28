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

    await dartNdkSource.dartNdk.userRelayLists.setInitialUserRelayList(
      nip65model.toNdkUserRelayList(),
      //customRelays: newNip65.relays.keys,
    );

    return newNip65;
  }

  @override
  Future<Nip65?> getNip65data(String npub, {bool forceRefresh = false}) async {
    final ndkData =
        await dartNdkSource.dartNdk.userRelayLists.getSingleUserRelayList(
      npub,
      forceRefresh: forceRefresh,
    );
    if (ndkData == null) return null;

    final data = Nip65Model.fromNdkUserRelayList(ndkData);
    return data;
  }
}
