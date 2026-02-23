import '../entities/nip_65.dart';
import '../repositories/inbox_outbox_repository.dart';

class InboxOutbox {
  final InboxOutboxRepository _inboxOutboxRepository;

  InboxOutbox({required InboxOutboxRepository repository})
    : _inboxOutboxRepository = repository;

  /// sets the Nip65 data by broadcasting to the network
  /// [returns] the new Nip65 object
  Future<Nip65> setNip65data(Nip65 newNip65) {
    return _inboxOutboxRepository.setNip65data(newNip65);
  }

  Future<Nip65?> getNip65data(String npub, {bool forceRefresh = false}) {
    return _inboxOutboxRepository.getNip65data(
      npub,
      forceRefresh: forceRefresh,
    );
  }

  Future<List<String>> getDmRelays({bool forceRefresh = false}) {
    return _inboxOutboxRepository.getDmRelays(forceRefresh: forceRefresh);
  }

  Future<List<String>> setDmRelays(List<String> relays) {
    return _inboxOutboxRepository.setDmRelays(relays);
  }

  Future<void> updateCache(List<String> pubkeys, {bool forceRefresh = false}) {
    return _inboxOutboxRepository.updateCache(
      pubkeys,
      forceRefresh: forceRefresh,
    );
  }
}
