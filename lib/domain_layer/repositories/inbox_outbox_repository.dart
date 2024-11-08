import '../entities/nip_65.dart';

abstract class InboxOutboxRepository {
  Future<Nip65> setNip65data(Nip65 newNip65);
  Future<Nip65?> getNip65data(String npub, {bool forceRefresh = false});
}
