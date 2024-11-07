import '../entities/nip_65.dart';
import '../repositories/inbox_outbox_repository.dart';

class InboxOutbox {
  final InboxOutboxRepository _inboxOutboxRepository;

  InboxOutbox({
    required InboxOutboxRepository repository,
  }) : _inboxOutboxRepository = repository;

  /// sets the Nip65 data by broadcasting to the network
  /// [returns] the new Nip65 object
  Future<Nip65> setNip65data(Nip65 newNip65) {
    return _inboxOutboxRepository.setNip65data(newNip65);
  }
}
