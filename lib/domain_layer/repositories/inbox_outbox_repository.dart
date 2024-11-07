import '../entities/nip_65.dart';

abstract class InboxOutboxRepository {
  Future<Nip65> setNip65data(Nip65 newNip65);
}
