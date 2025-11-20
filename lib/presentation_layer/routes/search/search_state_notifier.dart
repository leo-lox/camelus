import 'dart:async';

import 'package:riverpod/riverpod.dart';

import '../../../domain_layer/entities/nostr_note.dart';
import '../../../domain_layer/entities/user_metadata.dart';
import '../../../domain_layer/usecases/search.dart';
import '../../providers/search_provider.dart';

class SearchState {
  final bool isSearching;
  final String searchQuery;
  final bool isLoading;
  final List<UserMetadata> searchResultsUsers;
  final List<NostrNote> searchResultsNotes;
  final String? error;

  const SearchState({
    this.isSearching = false,
    this.searchQuery = '',
    this.isLoading = false,
    this.searchResultsUsers = const [],
    this.searchResultsNotes = const [],
    this.error,
  });

  SearchState copyWith({
    bool? isSearching,
    String? searchQuery,
    bool? isLoading,
    List<UserMetadata>? searchResultsUsers,
    List<NostrNote>? searchResultsNotes,
    String? error,
  }) {
    return SearchState(
      isSearching: isSearching ?? this.isSearching,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      searchResultsUsers: searchResultsUsers ?? this.searchResultsUsers,
      searchResultsNotes: searchResultsNotes ?? this.searchResultsNotes,
      error: error,
    );
  }
}

class SearchStateNotifier extends StateNotifier<SearchState> {
  SearchStateNotifier(this._searchService) : super(const SearchState());

  final Search _searchService;
  Timer? _debounceTimer;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void setSearching(bool isSearching) {
    if (state.isSearching != isSearching) {
      state = state.copyWith(isSearching: isSearching);
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query, error: null);

    // Cancel previous timer
    _debounceTimer?.cancel();

    if (query.isEmpty) {
      clearSearch(stillSearching: true);
      return;
    }

    if (query.length < 2) {
      clearSearch(stillSearching: true);
      return;
    }

    // Debounce search
    _debounceTimer = Timer(const Duration(milliseconds: 50), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    if (query != state.searchQuery) return; // query changed, ignore

    state = state.copyWith(isLoading: true, error: null);

    try {
      // perform searches in parallel
      final results = await Future.wait([
        _searchService.searchMetadata(query),
        _searchService.searchNotes(search: query, kinds: [1], limit: 10),
      ]);

      // only update if query hasn't changed
      if (query == state.searchQuery) {
        state = state.copyWith(
          isLoading: false,
          searchResultsUsers: results[0] as List<UserMetadata>,
          searchResultsNotes: results[1] as List<NostrNote>,
        );
      }
    } catch (e) {
      if (query == state.searchQuery) {
        state = state.copyWith(isLoading: false, error: e.toString());
      }
    }
  }

  void clearSearch({bool stillSearching = false}) {
    _debounceTimer?.cancel();
    state = SearchState(isSearching: stillSearching);
  }

  void setSearchResultsUsers(List<UserMetadata> users) {
    state = state.copyWith(searchResultsUsers: users);
  }
}

final searchStateProvider =
    StateNotifierProvider<SearchStateNotifier, SearchState>((ref) {
      final searchService = ref.read(searchProvider);
      return SearchStateNotifier(searchService);
    });
