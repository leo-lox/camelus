import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:camelus/domain_layer/entities/nostr_band_hashtags.dart';
import 'package:camelus/domain_layer/entities/nostr_band_people.dart';
import 'package:camelus/domain_layer/entities/user_metadata.dart';
import 'package:camelus/presentation_layer/atoms/hashtag_card.dart';
import 'package:camelus/presentation_layer/components/note_card/note_card_container.dart';
import 'package:camelus/presentation_layer/components/person_card.dart';
import 'package:camelus/config/palette.dart';
import 'package:camelus/helpers/helpers.dart';
import 'package:camelus/helpers/nprofile_helper.dart';
import 'package:camelus/presentation_layer/providers/following_provider.dart';
import 'package:camelus/presentation_layer/providers/language_provider.dart';
import 'package:camelus/presentation_layer/providers/metadata_provider.dart';
import 'package:camelus/presentation_layer/providers/navigation_bar_provider.dart';
import 'package:camelus/presentation_layer/providers/ndk_provider.dart';
import 'package:camelus/presentation_layer/providers/nostr_band_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain_layer/entities/contact_list.dart';
import '../../domain_layer/entities/nostr_note.dart';
import '../components/note_card/note_card.dart';
import '../components/search_bar.dart';
import '../providers/search_provider.dart';
import 'nostr/profile/profile_page_2.dart';

// Search state provider
final searchStateProvider =
    StateNotifierProvider<SearchStateNotifier, SearchState>((ref) {
  return SearchStateNotifier();
});

// Search state class
class SearchState {
  final bool isSearching;
  final String searchQuery;
  final List<UserMetadata> searchResultsUsers;
  final List<NostrNote> searchResultsNotes;

  SearchState({
    this.isSearching = false,
    this.searchQuery = '',
    this.searchResultsUsers = const [],
    this.searchResultsNotes = const [],
  });

  SearchState copyWith({
    bool? isSearching,
    String? searchQuery,
    List<UserMetadata>? searchResultsUsers,
    List<NostrNote>? searchResultsNotes,
  }) {
    return SearchState(
      isSearching: isSearching ?? this.isSearching,
      searchQuery: searchQuery ?? this.searchQuery,
      searchResultsUsers: searchResultsUsers ?? this.searchResultsUsers,
      searchResultsNotes: searchResultsNotes ?? this.searchResultsNotes,
    );
  }
}

// Search state notifier
class SearchStateNotifier extends StateNotifier<SearchState> {
  SearchStateNotifier() : super(SearchState());

  void setSearching(bool isSearching) {
    state = state.copyWith(isSearching: isSearching);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setSearchResultsUsers(List<UserMetadata> users) {
    state = state.copyWith(searchResultsUsers: users);
  }

  void setSearchResultsNotes(List<NostrNote> notes) {
    state = state.copyWith(searchResultsNotes: notes);
  }

  void clearSearch({bool stillSearching = false}) {
    state = SearchState(isSearching: stillSearching);
  }
}

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final List<StreamSubscription> _subscriptions = [];

  @override
  void initState() {
    super.initState();
    _initSequence();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _disposeSubscriptions();
    super.dispose();
  }

  void _initSequence() async {
    await Future.delayed(const Duration(milliseconds: 200)).then((value) {
      if (mounted) {
        _listenToNavigationBar();
      }
    });

    _setupFocusNodeListener();
  }

  void _listenToNavigationBar() {
    final navigationBar = ref.read(navigationBarProvider);
    _subscriptions.add(navigationBar.onTabSearch.listen((event) {
      _focusSearchBar();
    }));
  }

  void _setupFocusNodeListener() {
    _searchFocusNode.addListener(() {
      ref
          .read(searchStateProvider.notifier)
          .setSearching(_searchFocusNode.hasFocus);
    });
  }

  void _focusSearchBar() {
    FocusScope.of(context).requestFocus(_searchFocusNode);
  }

  void _disposeSubscriptions() {
    for (var s in _subscriptions) {
      s.cancel();
    }
  }

  void _onSearchChanged(String value) async {
    ref.read(searchStateProvider.notifier).setSearchQuery(value);

    if (value.isEmpty) {
      ref.read(searchStateProvider.notifier).clearSearch(stillSearching: true);
      return;
    }

    final searchService = ref.read(searchProvider);
    final metadata = ref.read(metadataProvider);

    // Search for users
    final users = await searchService.searchMetadata(value);
    ref.read(searchStateProvider.notifier).setSearchResultsUsers(users);

    // Search for notes
    final notes =
        await searchService.searchNotes(search: value, kinds: [1], limit: 10);
    ref.read(searchStateProvider.notifier).setSearchResultsNotes(
          notes,
        );
  }

  void _onSubmit(String value) {
    Navigator.pushNamed(context, '/nostr/search', arguments: value);
  }

  void _changeFollowing(
      bool followChange, String pubkey, ContactList currentOwnContacts) async {
    final followingService = ref.read(followingProvider);

    if (followChange) {
      await followingService.followUser(pubkey);
    } else {
      await followingService.unfollowUser(pubkey);
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchStateProvider);
    final isSearching = searchState.isSearching;

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
        body: Consumer(
          builder: (context, ref, child) {
            final followingService = ref.watch(followingProvider);

            return StreamBuilder<ContactList>(
              stream: followingService.getContactsStreamSelf(),
              builder: (context, ownFollowingSnapshot) {
                if (!ownFollowingSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                return Column(
                  children: [
                    SearchBarWidget(
                      onSearchChanged: (value) {
                        if (value.length < 2) {
                          ref
                              .read(searchStateProvider.notifier)
                              .clearSearch(stillSearching: true);
                          return;
                        }

                        _onSearchChanged(value);
                      },
                      onSubmit: (value) {
                        _onSubmit(value);
                      },
                      helpSearch: (context) {
                        _helpSearch(context);
                      },
                      externalFocusNode: _searchFocusNode,
                      externalController: _searchController,
                    ),
                    Expanded(
                      child: ListView(
                        physics: const BouncingScrollPhysics(),
                        children: [
                          // Default view (trends)
                          Visibility(
                            maintainState: true,
                            maintainInteractivity: false,
                            visible: !isSearching,
                            child: _defaultView(ownFollowingSnapshot.data!),
                          ),

                          // Search results
                          if (isSearching)
                            _buildSearchResults(ownFollowingSnapshot.data!)
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildSearchResults(ContactList currentFollowing) {
    final searchState = ref.watch(searchStateProvider);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (searchState.searchQuery.isNotEmpty)
            InkWell(
              onTap: () {
                _onSubmit(searchState.searchQuery);
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 0, vertical: 15),
                decoration: BoxDecoration(
                  //color: Palette.extraDarkGray,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'search for "${searchState.searchQuery}"',
                          style: const TextStyle(
                            color: Palette.white,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Icon(
                        PhosphorIcons.arrowUpLeft(),
                        color: Palette.gray,
                      )
                    ],
                  ),
                ),
              ),
            ),
          // horizontal line
          if (searchState.searchQuery.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 10),
              height: 1,
              color: Palette.extraDarkGray,
            ),

          // Users section
          if (searchState.searchResultsUsers.isNotEmpty) ...[
            const Text(
              "People",
              style: TextStyle(
                color: Palette.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            ...searchState.searchResultsUsers.map((user) => PersonCard(
                  showFollowButton: false,
                  pubkey: user.pubkey,
                  name: user.name ?? '',
                  pictureUrl: user.picture ?? '',
                  about: user.about ?? '',
                  nip05: user.nip05,
                  isFollowing: currentFollowing.contacts.contains(user.pubkey),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfilePage2(
                          pubkey: user.pubkey,
                        ),
                      ),
                    );
                  },
                  onFollowTab: (followState) {
                    _changeFollowing(
                      followState,
                      user.pubkey,
                      currentFollowing,
                    );
                  },
                )),
            const SizedBox(height: 20),
          ],

          // Notes section
          if (searchState.searchResultsNotes.isNotEmpty) ...[
            const Text(
              "Notes",
              style: TextStyle(
                color: Palette.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            ...searchState.searchResultsNotes.map((note) => NoteCardContainer(
                  note: note,

                  // onTap: () {
                  //   // Navigate to note detail
                  //   Navigator.pushNamed(context, '/nostr/note', arguments: note.id);
                  // },
                )),
          ],

          // No results
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
      ),
    );
  }

  Container _defaultView(ContactList currentFollowing) {
    return Container(
        padding: const EdgeInsets.only(left: 20, top: 20, bottom: 10),
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
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 15),
                GestureDetector(
                  onTap: () {
                    Uri url = Uri.parse("https://nostr.band");
                    launchUrl(url, mode: LaunchMode.externalApplication);
                  },
                  child: const Text("by nostr.band",
                      style: TextStyle(color: Palette.gray, fontSize: 14)),
                ),
              ],
            ),
            _buildTrendingHashtags(),
            const SizedBox(height: 20),
            const Text(
              "trending people",
              style: TextStyle(
                  color: Palette.white,
                  fontSize: 25,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildTrendingPeople(currentFollowing),
          ],
        ));
  }

  Widget _buildTrendingHashtags() {
    return Consumer(builder: (context, ref, child) {
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
            return const Text('Something went wrong',
                style: TextStyle(color: Palette.gray));
          }

          if (snapshot.hasData) {
            return _trendingHashtags(
              api: snapshot.data!,
              limit: 10,
            );
          }

          if (snapshot.connectionState == ConnectionState.done) {
            return const Text('No connection',
                style: TextStyle(color: Palette.gray));
          }

          return Column(
            children: List.generate(10, (i) => const HashtagCardSkeleton()),
          );
        },
      );
    });
  }

  Widget _buildTrendingPeople(ContactList currentFollowing) {
    return Consumer(builder: (context, ref, child) {
      final nostrBandAsync = ref.watch(
          nostrBandProvider.select((provider) => provider.getTrendingPeople()));

      return FutureBuilder<NostrBandPeople?>(
        future: nostrBandAsync,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            log(snapshot.error.toString());
            return const Text('Something went wrong',
                style: TextStyle(color: Palette.gray));
          }

          if (snapshot.hasData) {
            return _trendingPeople(snapshot.data!, 10, currentFollowing);
          }

          if (snapshot.connectionState == ConnectionState.done) {
            return const Text('No connection',
                style: TextStyle(color: Palette.gray));
          }

          return const Center(child: CircularProgressIndicator());
        },
      );
    });
  }

  Widget _trendingHashtags({required NostrBandHashtags api, int? limit}) {
    final myHashtags = api.hashtags;
    int displayLimit = limit ?? myHashtags.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(
        displayLimit > myHashtags.length ? myHashtags.length : displayLimit,
        (i) {
          final hashtag = myHashtags[i];

          return HashtagCard(
            index: i,
            hashtag: hashtag.hashtag,
            postsCount: hashtag.posts,
            onTap: (hashtag) {
              Navigator.pushNamed(context, '/nostr/search',
                  arguments: "#$hashtag");
            },
          );
        },
      ),
    );
  }

  Widget _trendingPeople(
      NostrBandPeople api, int limit, ContactList currentFollowing) {
    List<PersonCard> personCards = [];

    for (int i = 0; i < api.profiles.length; i++) {
      if (i == limit) {
        break;
      }
      var profile = api.profiles[i];
      Map metadata = jsonDecode(profile.profile.content);
      PersonCard myCard = PersonCard(
        pubkey: profile.pubkey,
        name: metadata['name'] ?? '',
        pictureUrl: metadata['picture'] ?? '',
        about: metadata['about'] ?? '',
        nip05: metadata['nip05'],
        isFollowing: currentFollowing.contacts
            .any((element) => element == profile.pubkey),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProfilePage2(
                pubkey: profile.pubkey,
              ),
            ),
          );
        },
        onFollowTab: (followState) {
          _changeFollowing(
            followState,
            profile.pubkey,
            currentFollowing,
          );
        },
      );
      personCards.add(myCard);
    }
    return Column(
      children: personCards,
    );
  }
}

_helpSearch(BuildContext context) {
  // open bottom sheet
  return showModalBottomSheet(
    backgroundColor: Palette.extraDarkGray,
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(20),
        topRight: Radius.circular(20),
      ),
    ),
    //showDragHandle: true,
    builder: (context) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(30, 20, 30, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
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
            // hashtag
            Text(
              '#hashtag',
              style: TextStyle(
                color: Palette.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 5),
            Expanded(
              child: Text(
                'search for hashtags',
                style: TextStyle(
                  color: Palette.white,
                  fontSize: 18,
                ),
              ),
            ),
            SizedBox(height: 20),
            // username
            Text(
              'username',
              style: TextStyle(
                color: Palette.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 5),
            Expanded(
              child: Text(
                'works only if already in cache',
                style: TextStyle(
                  color: Palette.white,
                  fontSize: 18,
                ),
              ),
            ),
            SizedBox(height: 20),
            // nip05
            Text(
              'user@domain.tld',
              style: TextStyle(
                color: Palette.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 5),
            Expanded(
              child: Text(
                'nip05 address',
                style: TextStyle(
                  color: Palette.white,
                  fontSize: 18,
                ),
              ),
            ),
            SizedBox(height: 20),
            // mastodon
            Text(
              '@mastodon@domain.tld',
              style: TextStyle(
                color: Palette.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 5),
            Expanded(
              child: Text(
                'mastodon address (provided by mostr.pub)',
                style: TextStyle(
                  color: Palette.white,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}
