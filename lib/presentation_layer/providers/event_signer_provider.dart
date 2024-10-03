import 'package:camelus/presentation_layer/providers/key_pair_provider.dart';
import 'package:ndk/ndk.dart';

import 'package:riverpod/riverpod.dart';

final eventSignerProvider = StateProvider<EventSigner>((ref) {
  final keypair = ref.watch(keyPairProvider);
  final EventSigner signer = Bip340EventSigner(
    keypair.keyPair!.publicKey,
    keypair.keyPair!.privateKey,
  );

  return signer;
});
