import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ndk/ndk.dart' as ndk;
import 'package:riverpod/misc.dart';

import '../../../data_layer/data_sources/dart_ndk_source.dart';
import '../../../data_layer/repositories/nostr_list_repository_impl.dart';
import '../../../domain_layer/entities/nostr_list.dart';
import '../../../domain_layer/repositories/nostr_list_repository.dart';
import '../../../domain_layer/usecases/get_nostr_lists.dart';
import '../embed_note_cache_provider.dart';
import '../generic_feed_provider.dart';
import '../parsed_note_cache_provider.dart';

class BlocklistState {
  final bool isLoading;
  final Set<String> blockedPubkeys;
  final Set<String> blockedWords;
  final DateTime? syncedListCreatedAt;

  BlocklistState({
    required this.isLoading,
    required this.blockedPubkeys,
    required this.blockedWords,
    required this.syncedListCreatedAt,
  });

  BlocklistState copyWith({
    bool? isLoading,
    Set<String>? blockedPubkeys,
    Set<String>? blockedWords,
    DateTime? syncedListCreatedAt,
    bool clearSyncedListCreatedAt = false,
  }) {
    return BlocklistState(
      isLoading: isLoading ?? this.isLoading,
      blockedPubkeys: blockedPubkeys ?? this.blockedPubkeys,
      blockedWords: blockedWords ?? this.blockedWords,
      syncedListCreatedAt: clearSyncedListCreatedAt
          ? null
          : (syncedListCreatedAt ?? this.syncedListCreatedAt),
    );
  }
}

final blocklistNotifierProvider =
    NotifierProvider<BlocklistNotifier, BlocklistState>(BlocklistNotifier.new);

class BlocklistNotifier extends Notifier<BlocklistState> {
  GetNostrLists? _nostrLists;
  bool _pendingSync = false;

  static final List<ProviderOrFamily> _providersToInvalidateOnBlocklistChange =
      <ProviderOrFamily>[
        embedCacheProvider,
        embeddedNoteProvider,
        embeddedParsedPostProvider,
        parsedNoteCacheStoreProvider,
        parsedNoteCacheProvider,
        genericFeedStateProvider,
      ];

  @override
  BlocklistState build() {
    return BlocklistState(
      isLoading: false,
      blockedPubkeys: <String>{},
      blockedWords: <String>{},
      syncedListCreatedAt: null,
    );
  }

  void initializeWithNdk(ndk.Ndk ndkInstance, {bool syncNow = true}) {
    if (_nostrLists == null) {
      final dartNdkSource = DartNdkSource(ndkInstance);
      final NostrListRepository listsRepo = NostrListRepositoryImpl(
        dartNdkSource: dartNdkSource,
      );
      _nostrLists = GetNostrLists(nostrListRepository: listsRepo);
    }

    if (syncNow || _pendingSync) {
      _pendingSync = false;
      Future.microtask(_syncFromNostr);
    }
  }

  Future<void> sync() {
    if (_nostrLists == null) {
      _pendingSync = true;
      return Future.value();
    }
    return _syncFromNostr();
  }

  Future<void> _syncFromNostr() async {
    final nostrLists = _nostrLists;
    if (nostrLists == null) {
      return;
    }

    state = state.copyWith(isLoading: true);

    try {
      final list = await nostrLists.getSingleList(kind: NostrList.mute);
      if (list == null) {
        _setState(
          isLoading: false,
          blockedPubkeys: <String>{},
          blockedWords: <String>{},
          syncedListCreatedAt: null,
        );
        return;
      }
      _applyList(list: list, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> blockPubkey(String pubkey) async {
    final nostrLists = _nostrLists;
    if (nostrLists == null) {
      return;
    }

    final value = pubkey.trim();
    if (value.isEmpty || state.blockedPubkeys.contains(value)) {
      return;
    }

    state = state.copyWith(isLoading: true);
    try {
      final list = await nostrLists.addElementToList(
        tag: NostrList.pubkeyTagKey,
        value: value,
        kind: NostrList.mute,
      );
      _applyList(list: list, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> unblockPubkey(String pubkey) async {
    final nostrLists = _nostrLists;
    if (nostrLists == null) {
      return;
    }

    final value = pubkey.trim();
    if (value.isEmpty) {
      return;
    }

    state = state.copyWith(isLoading: true);
    try {
      final list = await nostrLists.removeElementFromList(
        tag: NostrList.pubkeyTagKey,
        value: value,
        kind: NostrList.mute,
      );

      if (list == null) {
        await _syncFromNostr();
        return;
      }

      _applyList(list: list, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> blockWord(String word) async {
    final nostrLists = _nostrLists;
    if (nostrLists == null) {
      return;
    }

    final value = _normalizeWord(word);
    if (value.isEmpty || state.blockedWords.contains(value)) {
      return;
    }

    state = state.copyWith(isLoading: true);
    try {
      final list = await nostrLists.addElementToList(
        tag: NostrList.word,
        value: value,
        kind: NostrList.mute,
      );
      _applyList(list: list, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> unblockWord(String word) async {
    final nostrLists = _nostrLists;
    if (nostrLists == null) {
      return;
    }

    final value = _normalizeWord(word);
    if (value.isEmpty) {
      return;
    }

    state = state.copyWith(isLoading: true);
    try {
      final list = await nostrLists.removeElementFromList(
        tag: NostrList.word,
        value: value,
        kind: NostrList.mute,
      );

      if (list == null) {
        await _syncFromNostr();
        return;
      }

      _applyList(list: list, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  bool isPubkeyBlocked(String pubkey) {
    return state.blockedPubkeys.contains(pubkey.trim());
  }

  bool containsBlockedWord(String text) {
    final value = text.toLowerCase();
    for (final blockedWord in state.blockedWords) {
      if (blockedWord.isNotEmpty && value.contains(blockedWord)) {
        return true;
      }
    }
    return false;
  }

  void invalidateProviders(List<ProviderOrFamily> providers) {
    for (final provider in providers) {
      ref.invalidate(provider);
    }
  }

  void _applyList({required NostrList list, required bool isLoading}) {
    final blockedPubkeys = list.pubKeys
        .map((element) => element.value.trim())
        .where((value) => value.isNotEmpty)
        .toSet();

    final blockedWords = list.words
        .map((element) => _normalizeWord(element.value))
        .where((value) => value.isNotEmpty)
        .toSet();

    _setState(
      isLoading: isLoading,
      blockedPubkeys: blockedPubkeys,
      blockedWords: blockedWords,
      syncedListCreatedAt: DateTime.fromMillisecondsSinceEpoch(
        list.createdAt * 1000,
      ),
    );
  }

  void _setState({
    required bool isLoading,
    required Set<String> blockedPubkeys,
    required Set<String> blockedWords,
    required DateTime? syncedListCreatedAt,
  }) {
    final hasBlocklistChanged =
        state.blockedPubkeys.length != blockedPubkeys.length ||
        state.blockedWords.length != blockedWords.length ||
        !state.blockedPubkeys.containsAll(blockedPubkeys) ||
        !state.blockedWords.containsAll(blockedWords);

    state = state.copyWith(
      isLoading: isLoading,
      blockedPubkeys: blockedPubkeys,
      blockedWords: blockedWords,
      syncedListCreatedAt: syncedListCreatedAt,
      clearSyncedListCreatedAt: syncedListCreatedAt == null,
    );

    if (hasBlocklistChanged) {
      invalidateProviders(_providersToInvalidateOnBlocklistChange);
    }
  }

  String _normalizeWord(String word) {
    return word.trim().toLowerCase();
  }
}

final blocklistFilterReferenceProvider = Provider<BlocklistEventFilter>((ref) {
  final filter = BlocklistEventFilter(
    blockedPubkeys: <String>{},
    blockedWords: <String>{},
  );

  ref.listen(blocklistNotifierProvider, (previous, next) {
    filter.update(
      blockedPubkeys: next.blockedPubkeys,
      blockedWords: next.blockedWords,
    );
  });

  return filter;
});

class BlocklistEventFilter implements ndk.EventFilter {
  Set<String> _blockedPubkeys;
  Set<String> _blockedWords;

  BlocklistEventFilter({
    required Set<String> blockedPubkeys,
    required Set<String> blockedWords,
  }) : _blockedPubkeys = blockedPubkeys,
       _blockedWords = blockedWords;

  void update({
    required Set<String> blockedPubkeys,
    required Set<String> blockedWords,
  }) {
    _blockedPubkeys = blockedPubkeys;
    _blockedWords = blockedWords;
  }

  @override
  bool filter(ndk.Nip01Event event) {
    if (_blockedPubkeys.contains(event.pubKey)) {
      return false;
    }

    if (_blockedWords.isEmpty) {
      return true;
    }

    final content = event.content.toLowerCase();
    for (final blockedWord in _blockedWords) {
      if (blockedWord.isNotEmpty && content.contains(blockedWord)) {
        return false;
      }
    }

    return true;
  }
}
