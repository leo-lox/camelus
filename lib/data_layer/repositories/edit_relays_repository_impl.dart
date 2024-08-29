import 'package:ndk/ndk.dart' as ndk;

import '../../domain_layer/entities/relay.dart';
import '../../domain_layer/repositories/edit_relays_repository.dart';
import '../data_sources/dart_ndk_source.dart';

class EditRelaysRepositoryImpl implements EditRelaysRepository {
  final DartNdkSource dartNdkSource;
  final ndk.EventVerifier eventVerifier;

  EditRelaysRepositoryImpl({
    required this.dartNdkSource,
    required this.eventVerifier,
  });

  @override
  Future<List<Relay>> getRelays(String pubkey) {
    throw UnimplementedError();
  }

  @override
  Future<List<Relay>> getRelayHintsInbox(String pubkey) {
    // TODO: implement getRelayHintsInbox
    throw UnimplementedError();
  }

  @override
  Future<List<Relay>> getRelayHintsOutbox(String pubkey) {
    // TODO: implement getRelayHintsOutbox
    throw UnimplementedError();
  }

  @override
  Future<bool> saveRelays(String pubkey, List<Relay> relays) {
    // TODO: implement saveRelays
    throw UnimplementedError();
  }
}
