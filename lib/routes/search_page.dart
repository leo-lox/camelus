import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:camelus/atoms/hashtag_card.dart';
import 'package:camelus/atoms/person_card.dart';
import 'package:camelus/config/palette.dart';
import 'package:camelus/db/entities/db_note_view.dart';
import 'package:camelus/db/entities/db_note_view_base.dart';
import 'package:camelus/helpers/search.dart';
import 'package:camelus/models/api_nostr_band_hashtags.dart';
import 'package:camelus/models/api_nostr_band_people.dart';
import 'package:camelus/models/nostr_note.dart';
import 'package:camelus/models/nostr_tag.dart';
import 'package:camelus/providers/navigation_bar_provider.dart';
import 'package:camelus/providers/nostr_service_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:camelus/providers/database_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  final List<StreamSubscription> _subscriptions = [];

  late Search _search;

  bool _isSearching = false;

  List<Map<String, dynamic>> _searchResults = [];

  _listenToNavigationBar() {
    // listen to home bar
    final navigationBar = ref.watch(navigationBarProvider);
    _subscriptions.add(navigationBar.onTabSearch.listen((event) {
      _focusSearchBar();
    }));
  }

  void _setupFocusNodeListener() {
    _searchFocusNode.addListener(() {
      if (_searchFocusNode.hasFocus) {
        setState(() {
          _isSearching = true;
        });
      } else {
        setState(() {
          _isSearching = false;
        });
      }
    });
  }

  void _focusSearchBar() {
    log("message");
    // focus input
    FocusScope.of(context).requestFocus(_searchFocusNode);
  }

  void _setupSearchObj() async {
    var database = await ref.watch(databaseProvider.future);

    _search = Search(database);
  }

  void _initSequence() async {
    // wait 1 second with then
    await Future.delayed(const Duration(milliseconds: 200)).then((value) {
      // check if mounted
      if (mounted) {
        _listenToNavigationBar();
      }
    });
    _setupSearchObj();
    _setupFocusNodeListener();
  }

  @override
  void initState() {
    super.initState();
    _initSequence();
  }

  @override
  void dispose() {
    super.dispose();
    _disposeSubscriptions();
  }

  void _disposeSubscriptions() {
    for (var s in _subscriptions) {
      s.cancel();
    }
  }

  Future<ApiNostrBandPeople?> _getTrendingProfiles() async {
    // cached network request from https://api.nostr.band/v0/trending/profiles

    var file = await DefaultCacheManager().getSingleFile(
      'https://api.nostr.band/v0/trending/profiles',
      key: 'trending_profiles_nostr_band',
      // 30 min
      headers: {'cache-control': 'max-age=1800, immutable'},
    );
    var result = await file.readAsString();
    if (result.isEmpty) {
      return null;
    }
    var json = jsonDecode(result);

    return ApiNostrBandPeople.fromJson(json);
  }

  Future<ApiNostrBandHashtags?> _getTrendingHashtags() async {
    //var file = await DefaultCacheManager().getSingleFile(url);
    var file = await DefaultCacheManager().getSingleFile(
      'https://api.nostr.band/nostr?method=trending&type=hashtags',
      key: 'trending_hashtags_nostr_band',
      // 30 min
      headers: {'cache-control': 'max-age=1800'},
    );
    var result = await file.readAsString();
    if (result.isEmpty) {
      return null;
    }
    var json = jsonDecode(result);
    return ApiNostrBandHashtags.fromJson(json);
  }

  void _onSearchChanged(String value) async {
    if (value.length < 3) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    var localMetadata = _search.searchUsersMetadata(value);

    // check if it is a valid nip05
    RegExp nip05Regex =
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    RegExp mastodonRegex =
        RegExp(r'^@[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');

    String? finalNip05;

    if (nip05Regex.hasMatch(value)) {
      finalNip05 = value;
    }
    if (mastodonRegex.hasMatch(value)) {
      //turn into https://mostr.pub/.well-known/nostr.json?name=username_at_domain.tld
      final String removeAt = value.replaceFirst('@', '');
      final String snakeCase = removeAt.replaceAll('@', '_at_');
      finalNip05 = 'https://mostr.pub/.well-known/nostr.json?name=$snakeCase';
    }
    if (finalNip05 != null) {
      log('finalNip05 $finalNip05');
      //var nip05Metadata = await _search.searchNip05(finalNip05);
      //final String nipPubkey = nip05Metadata!['pubkey'];
      //final List<String> nipRelays = nip05Metadata['relays'];
    }

    setState(() {
      _searchResults = localMetadata;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palette.background,
      // scrollable column
      body: Column(
        children: [
          _searchBar(context),
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              children: [
                // hide default view when searching
                Visibility(
                  maintainState: true,
                  maintainInteractivity: false,
                  visible: !_isSearching,
                  child: _defaultView(),
                ),
                if (_searchFocusNode.hasFocus)
                  Column(
                    children: [
                      // search results
                      for (var result in _searchResults)
                        PersonCard(
                          name: result['name'] ?? '',
                          nip05: result['nip05'] ?? '',
                          pictureUrl: result['picture'] ?? '',
                          about: result['about'] ?? '',
                          pubkey: result['pubkey'] ?? '',
                          isFollowing: false,
                        ),
                    ],
                  )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Container _defaultView() {
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
                      fontSize: 25,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 18),
                GestureDetector(
                  onTap: () {
                    Uri url = Uri.parse("https://nostr.band");
                    launchUrl(url, mode: LaunchMode.externalApplication);
                  },
                  child: const Text("by nostr.band",
                      style: TextStyle(color: Palette.gray, fontSize: 15)),
                ),
              ],
            ),
            FutureBuilder<ApiNostrBandHashtags?>(
                future: _getTrendingHashtags(),
                builder:
                    (context, AsyncSnapshot<ApiNostrBandHashtags?> snapshot) {
                  if (snapshot.hasError) {
                    log(snapshot.error.toString());
                    return const Text('Something went wrong');
                  }
                  if (snapshot.hasData) {
                    return _trendingHashtags(api: snapshot.data!, limit: 10);
                  }
                  if (snapshot.connectionState == ConnectionState.done) {
                    return const Text('no connection');
                  }

                  return Column(
                    children: [
                      for (var i = 0; i < 10; i++) const HashtagCardSkeleton()
                    ],
                  );
                }),
            const SizedBox(height: 20),
            const Text(
              "trending people",
              style: TextStyle(
                  color: Palette.white,
                  fontSize: 25,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            FutureBuilder<ApiNostrBandPeople?>(
                future: _getTrendingProfiles(),
                builder:
                    (context, AsyncSnapshot<ApiNostrBandPeople?> snapshot) {
                  if (snapshot.hasError) {
                    log(snapshot.error.toString());
                    return const Text('Something went wrong');
                  }
                  if (snapshot.hasData) {
                    return _trendingPeople(snapshot.data!, 5);
                  }
                  if (snapshot.connectionState == ConnectionState.done) {
                    return const Text('no connection');
                  }

                  return const Center(child: CircularProgressIndicator());
                }),
          ],
        ));
  }

  Widget _trendingHashtags({required ApiNostrBandHashtags api, int? limit}) {
    var myHashtags = api.hashtags;

    List<Widget> hashtagWidgets = [];

    for (int i = 0; i < myHashtags.length; i++) {
      if (i == limit) {
        break;
      }
      var hashtag = myHashtags[i];
      String cleanHashtag = hashtag.hashtag.replaceFirst('#', '');
      hashtagWidgets.add(
        HashtagCard(
          index: i,
          hashtag: cleanHashtag,
          threadsCount: hashtag.threadsCount,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: hashtagWidgets,
    );
  }

  Widget _trendingPeople(ApiNostrBandPeople api, int limit) {
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
        nip05: metadata['nip05'] ?? '',
        isFollowing: false,
      );
      personCards.add(myCard);
    }
    return Column(
      children: personCards,
    );
  }

  Padding _searchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, left: 20, right: 20),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        decoration: const InputDecoration(
          hintText: 'Search',
          hintStyle: TextStyle(color: Palette.white),
          prefixIcon: Icon(Icons.search, color: Palette.white),
          filled: true,
          fillColor: Palette.extraDarkGray,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12.0)),
            borderSide: BorderSide(color: Palette.gray),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10.0)),
            borderSide: BorderSide(color: Palette.gray),
          ),
        ),
        style: const TextStyle(color: Palette.white),
        onChanged: (value) {
          _onSearchChanged(value);
        },
        onTapOutside: (value) {
          // close keyboard
          FocusScope.of(context).requestFocus(FocusNode());
        },
      ),
    );
  }
}
