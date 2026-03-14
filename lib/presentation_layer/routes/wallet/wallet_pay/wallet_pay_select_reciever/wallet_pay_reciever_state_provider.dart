import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ndk/entities.dart' as ndk_entities;
import 'package:ndk/ndk.dart';
import 'package:riverpod/legacy.dart';

import '../../../../../domain_layer/entities/user_metadata.dart';
import '../../../../../domain_layer/usecases/get_user_metadata.dart';

import '../../../../providers/following_contact_state_provider.dart';
import '../../../../providers/metadata_provider.dart';
import '../../../../providers/ndk_provider.dart';

class WalletPayRecieverState {
  final List<ndk_entities.Wallet> wallets;
  final List<ndk_entities.WalletBalance> balances;
  final List<UserMetadata> allContacts;
  final List<UserMetadata> recentContacts;
  final String? selectedWalletId;
  final String searchQuery;
  final bool isLoading;

  WalletPayRecieverState({
    required this.wallets,
    required this.balances,
    required this.allContacts,
    required this.recentContacts,
    required this.selectedWalletId,
    required this.searchQuery,
    required this.isLoading,
  });

  WalletPayRecieverState copyWith({
    List<ndk_entities.Wallet>? wallets,
    List<ndk_entities.WalletBalance>? balances,
    List<UserMetadata>? allContacts,
    List<UserMetadata>? recentContacts,
    String? selectedWalletId,
    String? searchQuery,
    bool? isLoading,
  }) {
    return WalletPayRecieverState(
      wallets: wallets ?? this.wallets,
      balances: balances ?? this.balances,
      allContacts: allContacts ?? this.allContacts,
      recentContacts: recentContacts ?? this.recentContacts,
      selectedWalletId: selectedWalletId ?? this.selectedWalletId,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  List<UserMetadata> get filteredContacts {
    final q = searchQuery.trim().toLowerCase();
    if (q.isEmpty) return const [];

    return allContacts
        .where(
          (c) =>
              (c.name != null && c.name!.toLowerCase().contains(q)) ||
              (c.pubkey.toLowerCase().contains(q)),
        )
        .toList();
  }

  List<ndk_entities.Wallet> get filteredWallets {
    final q = searchQuery.trim().toLowerCase();
    if (q.isEmpty) return wallets;
    return wallets.where((w) => w.name.toLowerCase().contains(q)).toList();
  }
}

class WalletPayToNotifier extends StateNotifier<WalletPayRecieverState> {
  final Ndk _ndk;

  final GetUserMetadata _getUserMetadata;

  final List<String> _contactPubkeys;

  WalletPayToNotifier({
    String? initialWalletId,
    required Ndk ndk,
    required List<String> contactPubkeys,
    required GetUserMetadata getUserMetadata,
  }) : _ndk = ndk,
       _contactPubkeys = contactPubkeys,
       _getUserMetadata = getUserMetadata,
       super(
         WalletPayRecieverState(
           wallets: const [],
           balances: const [],
           allContacts: const [],
           recentContacts: const [],
           selectedWalletId: initialWalletId,
           searchQuery: '',
           isLoading: true,
         ),
       ) {
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    final balances = await _ndk.wallets.combinedBalances.first;

    final wallets = await _ndk.wallets.walletsStream.first;

    List<UserMetadata> contactMetadata = [];
    final List<Future> futures = [];
    for (final cp in _contactPubkeys) {
      futures.add(
        _getUserMetadata.getMetadataByPubkey(cp).last.then((metadata) {
          contactMetadata.add(metadata);
        }),
      );
    }
    //await Future.wait(futures);

    final contacts = contactMetadata;

    final recent = contactMetadata;

    String? selected = state.selectedWalletId;
    // If the provided walletId isn't in the list, fall back to first.
    if (selected == null || !wallets.any((w) => w.id == selected)) {
      selected = wallets.isNotEmpty ? wallets.first.id : null;
    }

    state = state.copyWith(
      wallets: wallets,
      balances: balances,
      allContacts: contacts,
      recentContacts: recent,
      selectedWalletId: selected,
      isLoading: false,
    );
  }

  void setSearchQuery(String q) {
    state = state.copyWith(searchQuery: q);
  }
}

final walletPayRecieverProvider =
    StateNotifierProvider.family<
      WalletPayToNotifier,
      WalletPayRecieverState,
      String?
    >((ref, initialWalletId) {
      final ndk = ref.watch(ndkProvider);

      final contacts = ref.watch(contactListSelfStateProvider);

      final getUserMetadata = ref.watch(metadataProvider);

      return WalletPayToNotifier(
        initialWalletId: initialWalletId,
        ndk: ndk,
        contactPubkeys: contacts.contactList.contacts,
        getUserMetadata: getUserMetadata,
      );
    });
