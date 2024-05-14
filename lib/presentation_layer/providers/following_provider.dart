import 'package:camelus/domain_layer/usecases/follow.dart';
import 'package:camelus/presentation_layer/providers/key_pair_provider.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final followingProvider = Provider<Follow>((ref) {
  final follow = Follow();

  final myKeyPair = ref.watch(keyPairProvider.future);

  myKeyPair.then((value) => {
        follow.selfPubkey = value.keyPair!.publicKey,
      });

  return follow;
});
