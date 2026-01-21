import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter_riverpod/legacy.dart';
import 'package:http/http.dart' as http;
import 'package:camelus/helpers/nprofile_helper.dart';
import 'package:camelus/data_layer/data_sources/http_request_data_source.dart';


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
  SearchStateNotifier(this._searchService, this._httpRequestDataSource)
    : super(const SearchState());

  final Search _searchService;
  final HttpRequestDataSource _httpRequestDataSource;
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

    state = state.copyWith(
      isLoading: true,
      error: null,
      searchResultsUsers: [],
      searchResultsNotes: [],
    );

    final t1 = _searchService
        .searchMetadata(query)
        .then((users) {
          if (query == state.searchQuery) _addUsers(users);
        })
        .catchError((e) {
          log('Error searching metadata: $e');
          return null;
        });

    final t2 = _searchService
        .searchNotes(search: query, kinds: [1], limit: 10)
        .then((notes) {
          if (query == state.searchQuery) {
            state = state.copyWith(searchResultsNotes: notes);
          }
        })
        .catchError((e) {
          log('Error searching notes: $e');
          return null;
        });

    final t3 = _searchNpubWorld(query)
        .then((users) {
          if (query == state.searchQuery) _addUsers(users);
        })
        .catchError((e) {
          log('Error searching npub world: $e');
          return null;
        });

    await Future.wait([t1, t2, t3]);

    if (query == state.searchQuery) {
      state = state.copyWith(isLoading: false);
    }
  }

  void _addUsers(List<UserMetadata> newUsers) {
    final currentUsers = state.searchResultsUsers;
    final Map<String, UserMetadata> uniqueUsers = {};

    for (final user in currentUsers) {
      uniqueUsers[user.pubkey] = user;
    }

    for (final user in newUsers) {
      if (uniqueUsers.containsKey(user.pubkey)) {
        final existing = uniqueUsers[user.pubkey]!;
        // Prefer user with eventId (from relay) over empty eventId (from npub.world)
        if (existing.eventId.isEmpty && user.eventId.isNotEmpty) {
          uniqueUsers[user.pubkey] = user;
        }
      } else {
        uniqueUsers[user.pubkey] = user;
      }
    }

    state = state.copyWith(searchResultsUsers: uniqueUsers.values.toList());
  }

  Future<List<UserMetadata>> _searchNpubWorld(String query) async {
    try {
      final response = await _httpRequestDataSource.postRequest(
        'https://npub.world/?/search',
        headers: {
          'Origin': 'https://npub.world',
          'Referer': 'https://npub.world/',
        },
        body: {'q': query, 'limit': '10'},
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['type'] == 'success' && jsonResponse['data'] != null) {
          final String dataString = jsonResponse['data'];
          final List<dynamic> data = jsonDecode(dataString);

          if (data.isEmpty) return [];

          final List<dynamic> indices = data[0];
          final List<UserMetadata> users = [];

          for (final index in indices) {
            if (index is int && index < data.length) {
              final schemaMap = data[index];
              if (schemaMap is Map) {
                final npubIndex = schemaMap['npub'];
                final nameIndex = schemaMap['name'];
                final pictureIndex = schemaMap['picture'];
                final nip05Index = schemaMap['nip05'];

                String? npub;
                String? name;
                String? picture;
                String? nip05;

                if (npubIndex is int &&
                    npubIndex >= 0 &&
                    npubIndex < data.length) {
                  npub = data[npubIndex];
                }
                if (nameIndex is int &&
                    nameIndex >= 0 &&
                    nameIndex < data.length) {
                  name = data[nameIndex];
                }
                if (pictureIndex is int &&
                    pictureIndex >= 0 &&
                    pictureIndex < data.length) {
                  picture = data[pictureIndex];
                }
                if (nip05Index is int &&
                    nip05Index >= 0 &&
                    nip05Index < data.length) {
                  nip05 = data[nip05Index];
                }

                if (npub != null) {
                  try {
                    final pubkey = NprofileHelper().nprofileOrNpubToMap(
                      npub,
                    )['pubkey'];
                    users.add(
                      UserMetadata(
                        eventId: '',
                        pubkey: pubkey,
                        lastFetch:
                            DateTime.now().millisecondsSinceEpoch ~/ 1000,
                        name: "$name",
                        picture: picture,
                        nip05: nip05,
                        about: "provided by npub.world",
                      ),
                    );
                  } catch (e) {
                    // Ignore invalid npubs
                  }
                }
              }
            }
          }
          return users;
        }
      }
    } catch (e) {
      log('Error searching npub.world: $e');
    }
    return [];
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
      final client = http.Client();
      final httpRequestDataSource = HttpRequestDataSource(client);
      return SearchStateNotifier(searchService, httpRequestDataSource);
    });
