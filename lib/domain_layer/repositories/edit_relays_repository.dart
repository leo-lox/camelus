import '../entities/relay.dart';

abstract class EditRelaysRepository {
  Future<List<Relay>> getRelays(String pubkey);
  Future<bool> saveRelays(String pubkey, List<Relay> relays);
  Future<List<Relay>> getRelayHintsInbox(String pubkey);
  Future<List<Relay>> getRelayHintsOutbox(String pubkey);
}
