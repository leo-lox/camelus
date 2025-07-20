import 'package:ndk/ndk.dart';

final verifier = Bip340EventVerifier();

// Verify an event's signature
Future<bool> verifyEvent(Nip01Event event) {
  print(event.toJson().toString());
  return verifier.verify(event);
}
