import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:camelus/atoms/person_card.dart';
import 'package:camelus/config/palette.dart';
import 'package:camelus/db/entities/db_note_view.dart';
import 'package:camelus/db/entities/db_note_view_base.dart';
import 'package:camelus/helpers/search.dart';
import 'package:camelus/models/api_nostr_band.dart';
import 'package:camelus/models/nostr_note.dart';
import 'package:camelus/models/nostr_tag.dart';
import 'package:camelus/providers/navigation_bar_provider.dart';
import 'package:camelus/providers/nostr_service_provider.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:camelus/providers/database_provider.dart';
import 'package:http/http.dart' as http;

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

  List<Map<String, dynamic>> _searchResults = [];

  _listeToNavigationBar() {
    // listen to home bar
    final navigationBar = ref.watch(navigationBarProvider);
    _subscriptions.add(navigationBar.onTabSearch.listen((event) {
      _focusSearchBar();
    }));
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
        _listeToNavigationBar();
      }
    });
    _setupSearchObj();
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

  Future<ApiNostrBand> _getTrendingProfiles() async {
    // cached network request from https://api.nostr.band/v0/trending/notes

    var result;

    final url = Uri.parse('https://api.nostr.band/v0/trending/profiles');
    try {
      var res = await http.get(url, headers: {'cache-control': 'max-age=120'});

      res.headers.addAll({'cache-control': 'private, max-age=120'});

      if (res.statusCode == 200) {
        result = jsonDecode(res.body);
      } else {
        print('Request failed with status: ${res.statusCode}.');
      }
    } on SocketException {
      print('No internet connection');
    }

    return ApiNostrBand.fromJson(result);
  }

  void _onSearchChanged(String value) async {
    if (value.length < 3) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    var localMetadata = _search.searchUsersMetadata(value);

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
              children: [
                Container(
                    padding: EdgeInsets.only(left: 20, top: 20, bottom: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "trending people",
                          style: TextStyle(
                              color: Palette.white,
                              fontSize: 25,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        FutureBuilder<ApiNostrBand>(
                            future: _getTrendingProfiles(),
                            builder: (context,
                                AsyncSnapshot<ApiNostrBand> snapshot) {
                              if (snapshot.hasError) {
                                return const Text('Something went wrong');
                              }
                              if (snapshot.hasData) {
                                return _trendingPeople(snapshot.data!, 5);
                              }

                              return const Center(
                                  child: CircularProgressIndicator());
                            }),
                      ],
                    )),
                Column(
                  children: [
                    // search results
                    for (var result in _searchResults)
                      ListTile(
                        leading: CircleAvatar(
                          backgroundImage:
                              NetworkImage(result['picture'] ?? ''),
                        ),
                        title: Text(result['name'] ?? ''),
                        subtitle: Text(result['nip05'] ?? ''),
                      )
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _trendingPeople(ApiNostrBand api, int limit) {
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
      padding: EdgeInsets.only(top: 20, left: 20, right: 20),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        decoration: InputDecoration(
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
        style: TextStyle(color: Palette.white),
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
