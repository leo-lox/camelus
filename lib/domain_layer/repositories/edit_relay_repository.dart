import '../entities/relay.dart';

abstract class EditRelayRepository {
  Future<List<Relay>> getRelays(String pubkey);
  Future<bool> saveRelays(String pubkey, List<Relay> relays);
}
