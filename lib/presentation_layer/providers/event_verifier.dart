import 'package:ndk/ndk.dart';
import 'package:ndk/entities.dart' as ndk_entities;
import 'package:riverpod/riverpod.dart';

final eventVerifierProvider = Provider<EventVerifier>((ref) {
  final EventVerifier eventVerifier = Bip340EventVerifier();
  final EventVerifier mockEventVerifier = MockEventVerifier();
  final RustEventVerifier rustEventVerifier = RustEventVerifier();

  return rustEventVerifier;
});

class MockEventVerifier implements EventVerifier {
  bool _result = true;

  /// If [result] is false, [verify] will always return false. Default is true.
  MockEventVerifier({bool result = true}) {
    _result = result;
  }

  @override
  Future<bool> verify(ndk_entities.Nip01Event event) async {
    return _result;
  }
}
