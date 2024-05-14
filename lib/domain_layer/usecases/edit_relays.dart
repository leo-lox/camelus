import 'package:camelus/domain_layer/entities/relay.dart';
import 'package:camelus/domain_layer/repositories/edit_relays_repository.dart';

class EditRelays {
  final EditRelaysRepository _relayRepository;
  final String? selfPubkey;

  EditRelays(this._relayRepository, this.selfPubkey);

  set selfPubkey(String? value) {
    selfPubkey = value;
  }

  _checkSelfPubkey() {
    if (selfPubkey == null) {
      throw Exception("selfPubkey is null");
    }
  }

  Future<List<Relay>> getRelays(String pubkey) async {
    return _relayRepository.getRelays(pubkey);
  }

  Future<List<Relay>> getRelaysSelf() async {
    _checkSelfPubkey();
    return getRelays(selfPubkey!);
  }

  Future<bool> saveRelays(String pubkey, List<Relay> relays) async {
    return _relayRepository.saveRelays(pubkey, relays);
  }

  Future<List<Relay>> getRelayHintsInbox(String pubkey) async {
    return _relayRepository.getRelayHintsInbox(pubkey);
  }

  Future<List<Relay>> getRelayHintsOutbox(String pubkey) async {
    return _relayRepository.getRelayHintsOutbox(pubkey);
  }

  /// get the inobx relay hints for the current user
  Future<List<Relay>> getRelayHintsInboxSelf() async {
    _checkSelfPubkey();
    return _relayRepository.getRelayHintsInbox(selfPubkey!);
  }

  /// get the outbox relay hints for the current user
  Future<List<Relay>> getRelayHintsOutboxSelf() async {
    _checkSelfPubkey();
    return _relayRepository.getRelayHintsOutbox(selfPubkey!);
  }
}
