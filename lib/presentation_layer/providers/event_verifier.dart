import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:ndk/ndk.dart';
import 'package:ndk_rust_verifier/ndk_rust_verifier.dart';
import 'package:ndk_flutter/ndk_flutter.dart' show WebEventVerifier;
import 'package:ndk/entities.dart' as ndk_entities;
import 'package:riverpod/riverpod.dart';

// Provider for the EventVerifier, which provides an instance of a specific event verifier.
// Uses WebEventVerifier on web, RustEventVerifier on native platforms.
final eventVerifierProvider = Provider<EventVerifier>((ref) {
  if (kIsWeb) return WebEventVerifier();
  return RustEventVerifier();
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
