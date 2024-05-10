import 'package:camelus/domain_layer/entities/relay.dart';
import 'package:camelus/domain_layer/repositories/edit_relay_repository.dart';

class EditRelays {
  final EditRelayRepository _relayRepository;

  EditRelays(this._relayRepository);

  Future<List<Relay>> getRelays(String pubkey) async {
    return _relayRepository.getRelays(pubkey);
  }

  Future<bool> saveRelays(String pubkey, List<Relay> relays) async {
    return _relayRepository.saveRelays(pubkey, relays);
  }
}
