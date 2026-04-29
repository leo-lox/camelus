import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain_layer/entities/nostr_list.dart';
import 'ndk_provider.dart';
import 'nostr_list_provider.dart';

/// Streams the logged-in user's own NIP-51 sets of a given [kind].
/// Emits an empty list when the user is not logged in.
final userListsProvider = StreamProvider.autoDispose
    .family<List<NostrSet>, int>((ref, kind) {
      final ndk = ref.watch(ndkProvider);
      final pubkey = ndk.accounts.getPublicKey();
      if (pubkey == null) return Stream.value([]);

      final listsUseCase = ref.watch(nostrListProvider);
      return listsUseCase
          .getPublicSets(pubKey: pubkey, kind: kind)
          .map((lists) => lists ?? []);
    });
