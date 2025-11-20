import 'package:camelus/presentation_layer/providers/following_contact_state_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ndk_provider.dart';

class ModerationState {
  final Set<String> trustedPubkeys;

  ModerationState({required this.trustedPubkeys});

  ModerationState copyWith({Set<String>? trustedPubkeys}) {
    return ModerationState(
      trustedPubkeys: trustedPubkeys ?? this.trustedPubkeys,
    );
  }
}

final moderationStateProvider =
    StateNotifierProvider<ModerationNotifier, ModerationState>((ref) {
      final myUserPubkey = ref.read(ndkProvider).accounts.getPublicKey();

      // If no pubkey (read-only mode), return empty moderation state
      if (myUserPubkey == null) {
        return ModerationNotifier(ref: ref, myUserPubkey: null);
      }

      return ModerationNotifier(ref: ref, myUserPubkey: myUserPubkey);
    });

class ModerationNotifier extends StateNotifier<ModerationState> {
  final Ref ref;
  final String? myUserPubkey;

  ModerationNotifier({required this.ref, required this.myUserPubkey})
    : super(ModerationState(trustedPubkeys: {})) {
    // Skip setup if no pubkey (read-only mode)
    if (myUserPubkey == null) return;

    // Listen to contact changes
    ref.listen(contactListStateProvider(myUserPubkey!), (previous, next) {
      _updateTrustedPubkeys(next);
    });

    // Load initial state
    final contacts = ref.read(contactListStateProvider(myUserPubkey!));
    _updateTrustedPubkeys(contacts);
  }

  void _updateTrustedPubkeys(ContactListState contactsState) {
    final myContacts = contactsState.contactList.contacts.toSet();
    state = state.copyWith(trustedPubkeys: myContacts);
  }

  /// tests a pubkey against the trusted pubkeys
  bool isPubkeyTrusted(String pubkey) {
    return state.trustedPubkeys.contains(pubkey);
  }
}
