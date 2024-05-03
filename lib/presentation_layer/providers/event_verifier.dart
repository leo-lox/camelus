import 'package:dart_ndk/nips/nip01/bip340_event_verifier.dart';
import 'package:dart_ndk/nips/nip01/event_verifier.dart';
import 'package:riverpod/riverpod.dart';

final eventVerifierProvider = Provider<EventVerifier>((ref) {
  final EventVerifier eventVerifier = Bip340EventVerifier();

  return eventVerifier;
});
