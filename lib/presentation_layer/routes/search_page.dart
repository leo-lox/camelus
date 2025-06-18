import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/palette.dart';
import '../../domain_layer/entities/contact_list.dart';
import '../../domain_layer/entities/nostr_band_hashtags.dart';
import '../../domain_layer/entities/nostr_band_people.dart';
import '../../domain_layer/entities/nostr_note.dart';
import '../../domain_layer/entities/user_metadata.dart';
import '../../domain_layer/usecases/search.dart';
import '../atoms/hashtag_card.dart';
import '../components/note_card/nostr_parser.dart';
import '../components/note_card/note_card_container.dart';
import '../components/person_card.dart';
import '../components/search_bar.dart';
import '../components/starter_packs/trending_starter_packs/trending_starter_packs.dart';
import '../providers/app_bar_provider/app_bottom_bar_provider.dart';
import '../providers/following_contact_state_provider.dart';
import '../providers/ndk_provider.dart';
import '../providers/nostr_band_provider.dart';
import '../providers/search_provider.dart';
import 'nostr/profile/profile_page_2.dart';

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
        state = state.copyWith(
          isLoading: false,
          error: e.toString(),
        );
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

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  StreamSubscription? _navigationSubscription;

  @override
  bool get wantKeepAlive => false; // keep state alive when switching tabs

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initSequence());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _navigationSubscription?.cancel();
    super.dispose();
  }

  void _initSequence() {
    if (!mounted) return;

    _setupFocusNodeListener();
    _listenToNavigationBar();
  }

  void _listenToNavigationBar() {
    final navigationBar = ref.read(appBottomNavigationBarEventsProvider);
    _navigationSubscription = navigationBar.onSearchTabSelected.listen((_) {
      if (mounted) _focusSearchBar();
    });
  }

  void _setupFocusNodeListener() {
    _searchFocusNode.addListener(() {
      if (mounted) {
        ref
            .read(searchStateProvider.notifier)
            .setSearching(_searchFocusNode.hasFocus);
      }
    });
  }

  void _focusSearchBar() {
    if (mounted) {
      FocusScope.of(context).requestFocus(_searchFocusNode);
    }
  }

  void _onSearchChanged(String value) {
    ref.read(searchStateProvider.notifier).setSearchQuery(value);
  }

  void _onSubmit(String value) {
    if (mounted) {
      Navigator.pushNamed(context, '/nostr/search', arguments: value);
    }
  }

  Future<void> _changeFollowing(bool followChange, String pubkey) async {
    try {
      final selfPubkey = ref.read(ndkProvider).accounts.getPublicKey();
      if (selfPubkey == null) return;

      final myContactListNotifier =
          ref.read(contactListStateProvider(selfPubkey).notifier);

      if (followChange) {
        await myContactListNotifier.followUser(pubkey);
      } else {
        await myContactListNotifier.unfollowUser(pubkey);
      }
    } catch (e) {
      log('Error changing follow status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchStateProvider);

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop && _searchFocusNode.hasFocus) {
          _searchFocusNode.unfocus();
          _searchController.clear();
          ref
              .read(searchStateProvider.notifier)
              .clearSearch(stillSearching: true);
        }
      },
      child: Scaffold(
        backgroundColor: Palette.background,
        body: Column(
          children: [
            SearchBarWidget(
              onSearchChanged: _onSearchChanged,
              onSubmit: _onSubmit,
              helpSearch: _helpSearch,
              externalFocusNode: _searchFocusNode,
              externalController: _searchController,
            ),
            Expanded(
              child: searchState.isSearching
                  ? _buildSearchResults(searchState)
                  : _buildDefaultView(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultView() {
    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Trends section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          "trends",
                          style: TextStyle(
                            color: Palette.white,
                            fontSize: 27,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 15),
                        GestureDetector(
                          onTap: () {
                            launchUrl(
                              Uri.parse("https://nostr.band"),
                              mode: LaunchMode.externalApplication,
                            );
                          },
                          child: const Text(
                            "by nostr.band",
                            style: TextStyle(color: Palette.gray, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                    _buildTrendingHashtags(),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // starter packs section
              const Padding(
                padding: EdgeInsets.only(left: 20, bottom: 10),
                child: Text(
                  "recent starter packs",
                  style: TextStyle(
                    color: Palette.white,
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(
                height: 280,
                child: TrendingStarterPacks(),
              ),

              const SizedBox(height: 20),

              // trending people section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "trending people",
                      style: TextStyle(
                        color: Palette.white,
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildTrendingPeople(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResults(SearchState searchState) {
    return Consumer(
      builder: (context, ref, child) {
        final myContactList =
            ref.watch(contactListSelfStateProvider).contactList;

        return ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          children: [
            // Search query display
            if (searchState.searchQuery.isNotEmpty) ...[
              _buildSearchQueryCard(searchState.searchQuery),
              const Divider(color: Palette.extraDarkGray, height: 20),
            ],

            // Loading indicator
            if (searchState.isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: CircularProgressIndicator(),
                ),
              ),

            // error display
            if (searchState.error != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    'Error: ${searchState.error}',
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                  ),
                ),
              ),

            // results sections
            if (!searchState.isLoading && searchState.error == null) ...[
              if (searchState.searchResultsUsers.isNotEmpty)
                _buildUsersSection(
                    searchState.searchResultsUsers, myContactList),

              if (searchState.searchResultsNotes.isNotEmpty)
                _buildNotesSection(searchState.searchResultsNotes),

              // no results
              if (searchState.searchResultsUsers.isEmpty &&
                  searchState.searchResultsNotes.isEmpty &&
                  searchState.searchQuery.isNotEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Text(
                      "No results found",
                      style: TextStyle(color: Palette.gray, fontSize: 16),
                    ),
                  ),
                ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildSearchQueryCard(String query) {
    return InkWell(
      onTap: () => _onSubmit(query),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Search for "$query"',
                style: const TextStyle(color: Palette.white, fontSize: 16),
              ),
            ),
            Icon(PhosphorIcons.arrowUpLeft(), color: Palette.gray),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersSection(List<UserMetadata> users, ContactList contactList) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "People",
          style: TextStyle(
            color: Palette.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        ...users.map((user) => PersonCard(
              showFollowButton: false,
              pubkey: user.pubkey,
              name: user.name ?? '',
              pictureUrl: user.picture ?? '',
              about: user.about ?? '',
              nip05: user.nip05,
              isFollowing: contactList.contacts.contains(user.pubkey),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfilePage2(pubkey: user.pubkey),
                  ),
                );
              },
              onFollowTab: (followState) =>
                  _changeFollowing(followState, user.pubkey),
            )),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildNotesSection(List<NostrNote> notes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Notes",
          style: TextStyle(
            color: Palette.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        ...notes.map((note) =>
            NoteCardContainer(note: NostrParser.parseEventSync(note))),
      ],
    );
  }

  Widget _buildTrendingHashtags() {
    return Consumer(
      builder: (context, ref, child) {
        final nostrBandAsync = ref.watch(
          nostrBandProvider.select(
            (provider) => provider.getTrendingHashtags(),
          ),
        );

        return FutureBuilder<NostrBandHashtags?>(
          future: nostrBandAsync,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              log(snapshot.error.toString());
              return const Text(
                'Something went wrong',
                style: TextStyle(color: Palette.gray),
              );
            }

            if (snapshot.hasData && snapshot.data != null) {
              return _buildHashtagsList(snapshot.data!, 10);
            }

            if (snapshot.connectionState == ConnectionState.done) {
              return const Text(
                'No connection',
                style: TextStyle(color: Palette.gray),
              );
            }

            return Column(
              children: List.generate(
                10,
                (i) => const HashtagCardSkeleton(),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTrendingPeople() {
    return Consumer(
      builder: (context, ref, child) {
        final contactList = ref.watch(contactListSelfStateProvider).contactList;
        final nostrBandAsync = ref.watch(
          nostrBandProvider.select(
            (provider) => provider.getTrendingPeople(),
          ),
        );

        return FutureBuilder<NostrBandPeople?>(
          future: nostrBandAsync,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              log(snapshot.error.toString());
              return const Text(
                'Something went wrong',
                style: TextStyle(color: Palette.gray),
              );
            }

            if (snapshot.hasData && snapshot.data != null) {
              return _buildPeopleList(snapshot.data!, 10, contactList);
            }

            if (snapshot.connectionState == ConnectionState.done) {
              return const Text(
                'No connection',
                style: TextStyle(color: Palette.gray),
              );
            }

            return const Center(child: CircularProgressIndicator());
          },
        );
      },
    );
  }

  Widget _buildHashtagsList(NostrBandHashtags api, int limit) {
    final hashtags = api.hashtags;
    final displayLimit = limit > hashtags.length ? hashtags.length : limit;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(
        displayLimit,
        (i) {
          final hashtag = hashtags[i];
          return HashtagCard(
            index: i,
            hashtag: hashtag.hashtag,
            postsCount: hashtag.posts,
            onTap: (hashtag) {
              Navigator.pushNamed(
                context,
                '/nostr/search',
                arguments: "#$hashtag",
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildPeopleList(
    NostrBandPeople api,
    int limit,
    ContactList contactList,
  ) {
    final profiles = api.profiles.take(limit).toList();

    return Column(
      children: profiles.map((profile) {
        try {
          final metadata = jsonDecode(profile.profile.content);
          return PersonCard(
            pubkey: profile.pubkey,
            name: metadata['name'] ?? '',
            pictureUrl: metadata['picture'] ?? '',
            about: metadata['about'] ?? '',
            nip05: metadata['nip05'],
            isFollowing: contactList.contacts.contains(profile.pubkey),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfilePage2(pubkey: profile.pubkey),
                ),
              );
            },
            onFollowTab: (followState) =>
                _changeFollowing(followState, profile.pubkey),
          );
        } catch (e) {
          log('Error parsing profile metadata: $e');
          return const SizedBox.shrink();
        }
      }).toList(),
    );
  }
}

void _helpSearch(BuildContext context) {
  showModalBottomSheet(
    backgroundColor: Palette.extraDarkGray,
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(20),
        topRight: Radius.circular(20),
      ),
    ),
    builder: (context) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(30, 20, 30, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Search',
              style: TextStyle(
                color: Palette.white,
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 25),
            _SearchHelpItem(
              title: '#hashtag',
              description: 'search for hashtags',
            ),
            SizedBox(height: 20),
            _SearchHelpItem(
              title: 'username',
              description: 'works only if already in cache',
            ),
            SizedBox(height: 20),
            _SearchHelpItem(
              title: 'user@domain.tld',
              description: 'nip05 address',
            ),
            SizedBox(height: 20),
            _SearchHelpItem(
              title: '@mastodon@domain.tld',
              description: 'mastodon address (provided by mostr.pub)',
            ),
          ],
        ),
      );
    },
  );
}

class _SearchHelpItem extends StatelessWidget {
  final String title;
  final String description;

  const _SearchHelpItem({
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Palette.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          description,
          style: const TextStyle(
            color: Palette.white,
            fontSize: 18,
          ),
        ),
      ],
    );
  }
}
