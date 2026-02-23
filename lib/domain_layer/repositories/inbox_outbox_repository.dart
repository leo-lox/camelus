import '../entities/nip_65.dart';

abstract class InboxOutboxRepository {
  Future<Nip65> setNip65data(Nip65 newNip65);
  Future<Nip65?> getNip65data(String npub, {bool forceRefresh = false});

  /// Returns DM relay list (kind 10050) for the currently logged in account.
  Future<List<String>> getDmRelays({bool forceRefresh = false});

  /// Replaces DM relay list (kind 10050) for the currently logged in account.
  Future<List<String>> setDmRelays(List<String> relays);

  /// populates the cache with nip65 data from the network
  Future<void> updateCache(List<String> pubkeys, {bool forceRefresh = false});
}
