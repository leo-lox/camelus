import 'package:dart_ndk/data_layer/repositories/verifiers/bip340_event_verifier.dart';
import 'package:dart_ndk/domain_layer/repositories/event_verifier_repository.dart';
import 'package:dart_ndk/domain_layer/entities/nip_01_event.dart'
    as dart_ndk_nip01;
import 'package:riverpod/riverpod.dart';

final eventVerifierProvider = Provider<EventVerifierRepository>((ref) {
  final EventVerifierRepository eventVerifier =
      Bip340EventVerifierRepositoryImpl();
  final EventVerifierRepository mockEventVerifier = MockEventVerifier();

  return mockEventVerifier;
});

class MockEventVerifier implements EventVerifierRepository {
  bool _result = true;

  /// If [result] is false, [verify] will always return false. Default is true.
  MockEventVerifier({bool result = true}) {
    _result = result;
  }

  @override
  Future<bool> verify(dart_ndk_nip01.Nip01Event event) async {
    return _result;
  }
}
