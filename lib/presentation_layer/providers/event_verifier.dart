import 'package:ndk/ndk.dart';
import 'package:ndk_rust_verifier/ndk_rust_verifier.dart';
import 'package:ndk/entities.dart' as ndk_entities;
import 'package:riverpod/riverpod.dart';

// Provider for the EventVerifier, which provides an instance of a specific event verifier.
// Currently set to use the RustEventVerifier.
final eventVerifierProvider = Provider<EventVerifier>((ref) {
  // Creating instances of different EventVerifiers (Bip340, Mock, Rust).
  final EventVerifier eventVerifier = Bip340EventVerifier();
  final EventVerifier mockEventVerifier = MockEventVerifier();
  final RustEventVerifier rustEventVerifier = RustEventVerifier();

  return rustEventVerifier;
});

/// This mock verifier returns a fixed result, controlled by the constructor.
class MockEventVerifier implements EventVerifier {
  bool _result = true;

  /// The result parameter controls whether verify always returns true or false.
  MockEventVerifier({bool result = true}) {
    _result = result;
  }

  /// Verifies the event, returning a fixed result.
  @override
  Future<bool> verify(ndk_entities.Nip01Event event) async {
    return _result; // Return the mock result
  }
}
