import 'package:camelus/presentation_layer/providers/key_pair_provider.dart';
import 'package:ndk/ndk.dart';

import 'package:riverpod/riverpod.dart';

final eventSignerProvider = StateProvider<EventSigner?>((ref) {
  final keypair = ref.watch(keyPairProvider);

  if (keypair.keyPair == null) {
    return null;
  }

  final EventSigner signer = Bip340EventSigner(
    privateKey: keypair.keyPair!.privateKey,
    publicKey: keypair.keyPair!.publicKey,
  );

  return signer;
});
