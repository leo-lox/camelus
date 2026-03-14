import '../../domain_layer/entities/nip_65.dart';
import '../../domain_layer/repositories/inbox_outbox_repository.dart';
import '../../config/nostr_kinds.dart';
import '../data_sources/dart_ndk_source.dart';
import '../models/nip_65_model.dart';

class InboxOutboxRepositoryImpl implements InboxOutboxRepository {
  final DartNdkSource dartNdkSource;

  InboxOutboxRepositoryImpl({required this.dartNdkSource});
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
    final ndkData = await dartNdkSource.dartNdk.userRelayLists
        .getSingleUserRelayList(npub, forceRefresh: forceRefresh);
    if (ndkData == null) return null;

    final data = Nip65Model.fromNdkUserRelayList(ndkData);
    return data;
  }

  @override
  Future<List<String>> getDmRelays({
    required String pubkey,
    bool forceRefresh = false,
  }) async {
    final list = await dartNdkSource.dartNdk.lists.getPublicList(
      kind: kDmRelayListKind,
      forceRefresh: forceRefresh,
      publicKey: pubkey,
    );

    return list?.allRelays.toList() ?? const [];
  }

  @override
  Future<List<String>> getDmRelaysSelf({bool forceRefresh = false}) async {
    final list = await dartNdkSource.dartNdk.lists.getSingleNip51List(
      kDmRelayListKind,
      forceRefresh: forceRefresh,
    );

    return list?.allRelays.toList() ?? const [];
  }

  @override
  Future<List<String>> setDmRelays(List<String> relays) async {
    final normalized = <String>[];
    final seen = <String>{};

    for (final relay in relays) {
      final value = relay.trim();
      if (value.isEmpty || seen.contains(value)) {
        continue;
      }
      seen.add(value);
      normalized.add(value);
    }

    final current = await getDmRelaysSelf(forceRefresh: true);
    final currentSet = current.toSet();
    final targetSet = normalized.toSet();

    final toRemove = current.where((relay) => !targetSet.contains(relay));
    final toAdd = normalized.where((relay) => !currentSet.contains(relay));

    for (final relay in toRemove) {
      await dartNdkSource.dartNdk.lists.removeElementFromList(
        kind: kDmRelayListKind,
        tag: 'relay',
        value: relay,
      );
    }

    for (final relay in toAdd) {
      await dartNdkSource.dartNdk.lists.addElementToList(
        kind: kDmRelayListKind,
        tag: 'relay',
        value: relay,
      );
    }

    if (toRemove.isEmpty && toAdd.isEmpty) {
      return normalized;
    }

    return getDmRelaysSelf(forceRefresh: true);
  }

  @override
  Future<void> updateCache(
    List<String> pubkeys, {
    bool forceRefresh = false,
  }) async {
    await dartNdkSource.dartNdk.userRelayLists
        .loadMissingRelayListsFromNip65OrNip02(
          pubkeys,
          forceRefresh: forceRefresh,
        );
  }
}
