import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:camelus/config/palette.dart';
import 'package:camelus/db/entities/db_note_view.dart';
import 'package:camelus/db/entities/db_note_view_base.dart';
import 'package:camelus/helpers/search.dart';
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

  void _getTrendingNotes() async {
    // cached network request from https://api.nostr.band/v0/trending/notes

    final url = Uri.parse('https://api.nostr.band/v0/trending/notes');
    try {
      var res = await http.get(url, headers: {'cache-control': 'max-age=120'});

      res.headers.addAll({'cache-control': 'private, max-age=120'});
    } on SocketException {
      print('No internet connection');
    }
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
      body: ListView(
        children: [
          // search bar
          Padding(
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
          ),

          Column(
            children: [
              // search results
              for (var result in _searchResults)
                ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(result['picture'] ?? ''),
                  ),
                  title: Text(result['name'] ?? ''),
                  subtitle: Text(result['nip05'] ?? ''),
                )
            ],
          )
        ],
      ),
    );
  }
}
