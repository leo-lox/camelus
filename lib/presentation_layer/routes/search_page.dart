import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:camelus/domain_layer/entities/nostr_band_hashtags.dart';
import 'package:camelus/domain_layer/entities/nostr_band_people.dart';
import 'package:camelus/domain_layer/entities/user_metadata.dart';
import 'package:camelus/presentation_layer/atoms/hashtag_card.dart';
import 'package:camelus/presentation_layer/components/person_card.dart';
import 'package:camelus/config/palette.dart';
import 'package:camelus/helpers/helpers.dart';
import 'package:camelus/helpers/nprofile_helper.dart';
import 'package:camelus/presentation_layer/providers/following_provider.dart';
import 'package:camelus/presentation_layer/providers/metadata_provider.dart';
import 'package:camelus/presentation_layer/providers/navigation_bar_provider.dart';
import 'package:camelus/presentation_layer/providers/nostr_band_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain_layer/entities/contact_list.dart';
import 'nostr/profile/profile_page_2.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  final List<StreamSubscription> _subscriptions = [];

  bool _isSearching = false;

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
        log("schould unfocus");
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

  void _initSequence() async {
    // wait 1 second with then
    await Future.delayed(const Duration(milliseconds: 200)).then((value) {
      // check if mounted
      if (mounted) {
        _listenToNavigationBar();
      }
    });

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

  void _onSearchChanged(String value) async {
    var metadata = ref.watch(metadataProvider);
    List<UserMetadata> workingMetadata = [];

    final pattern = RegExp(r"nostr:(nprofile|npub)[a-zA-Z0-9]+");

    // check if it is a valid nip05
    RegExp nip05Regex =
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    RegExp mastodonRegex =
        RegExp(r'^@[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');

    RegExp hastagRegex = RegExp(r'^#\S+');

    RegExp cashtagRegex = RegExp(r'^(\$|\€|\£|\¥|\₿)\S+');

    RegExp hexRegex = RegExp(r'[a-fA-F0-9]{64}');

    RegExp nprofileNpubRegex = RegExp(r'(nostr:|)(nprofile|npub)[a-zA-Z0-9]+');

    String? finalNip05;

    if (hexRegex.hasMatch(value) || nprofileNpubRegex.hasMatch(value)) {
      String hex = '';
      if (value.contains('nostr:')) {
        value = value.replaceAll('nostr:', '');
      }

      if (value.contains('nprofile')) {
        Map nprofile = NprofileHelper().bech32toMap(value);
        hex = nprofile['pubkey'];
        var relays = nprofile['relays'];
      }

      if (value.contains('npub')) {
        List<String> npub = Helpers().decodeBech32(value);
        hex = npub[0];
      }

      if (hexRegex.hasMatch(value)) {
        hex = value;
      }

      var personMetadata =
          await metadata.getMetadataByPubkey(hex).first.timeout(
                const Duration(seconds: 1),
              );

      if (personMetadata != null) {
        workingMetadata.add(personMetadata);
        personMetadata.pubkey = hex;
      } else {
        final mockUser =
            UserMetadata(pubkey: value, eventId: "", lastFetch: 0, name: value);
        workingMetadata.add(mockUser);
      }
    }

    if (nip05Regex.hasMatch(value)) {
      finalNip05 = value;
    }
    if (mastodonRegex.hasMatch(value)) {
      //turn into https://mostr.pub/.well-known/nostr.json?name=username_at_domain.tld
      final String removeAt = value.replaceFirst('@', '');
      final String snakeCase = removeAt.replaceAll('@', '_at_');
      //finalNip05 = 'https://mostr.pub/.well-known/nostr.json?name=$snakeCase';
      finalNip05 = "$snakeCase@mostr.pub";
    }
    if (finalNip05 != null) {
      log('finalNip05 $finalNip05');
      var nip05Metadata = {}; //await _search.searchNip05(finalNip05);

      if (nip05Metadata != null) {
        final String nipPubkey = nip05Metadata['pubkey'];
        final List nipRelays = nip05Metadata['relays'];

        var personMetadata = await metadata
            .getMetadataByPubkey(nipPubkey)
            .first
            .timeout(const Duration(seconds: 1));
        personMetadata!.pubkey = nipPubkey;

        workingMetadata.add(personMetadata);
      }
    }

    if (hastagRegex.hasMatch(value)) {
      // search for hashtag

      log('hashtagRelays $value');
    }

    if (cashtagRegex.hasMatch(value)) {
      // search for cashtag
      log('cashtag $value');
    }

    setState(() {
      //_searchResultsUsers = workingMetadata;
    });
  }

  void _onSubmit(String value) {
    if (value.startsWith('#')) {
      var hastag = value.substring(1);
      Navigator.pushNamed(context, '/nostr/hastag', arguments: hastag);
    }
  }

  void _changeFollowing(
      bool followChange, String pubkey, ContactList currentOwnContacts) async {
    List<String> newContacts = [...currentOwnContacts.contacts];

    if (followChange) {
      newContacts.add(pubkey);
    } else {
      newContacts.removeWhere((element) => element == pubkey);
    }

    throw UnimplementedError("save contacts");
  }

  @override
  Widget build(BuildContext context) {
    var followingService = ref.watch(followingProvider);

    return WillPopScope(
      onWillPop: () async {
        // check if search is focused
        if (_searchFocusNode.hasFocus) {
          _searchFocusNode.unfocus();
          _searchController.clear();
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Palette.background,
        // scrollable column
        body: StreamBuilder<ContactList>(
          stream: followingService.getContactsStreamSelf(),
          builder: (context, ownFollowingSnapshot) {
            return Column(
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
                        child: _defaultView(ownFollowingSnapshot.data!),
                      ),
                      if (_searchFocusNode.hasFocus)
                        Column(
                          children: [
                            // search results
                            Text("todo: search results")
                          ],
                        )
                    ],
                  ),
                ),
              ],
            );
          },
        ),
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
            FutureBuilder<NostrBandHashtags?>(
                future: ref.watch(nostrBandProvider).getTrendingHashtags(),
                builder: (context, AsyncSnapshot<NostrBandHashtags?> snapshot) {
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
            FutureBuilder<NostrBandPeople?>(
                future: ref.watch(nostrBandProvider).getTrendingPeople(),
                builder: (context, AsyncSnapshot<NostrBandPeople?> snapshot) {
                  if (snapshot.hasError) {
                    log(snapshot.error.toString());
                    return const Text('Something went wrong');
                  }
                  if (snapshot.hasData) {
                    return _trendingPeople(
                        snapshot.data!, 10, currentFollowing);
                  }
                  if (snapshot.connectionState == ConnectionState.done) {
                    return const Text('no connection');
                  }

                  return const Center(child: CircularProgressIndicator());
                }),
          ],
        ));
  }

  Widget _trendingHashtags({required NostrBandHashtags api, int? limit}) {
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
          onTap: (hashtag) {
            Navigator.pushNamed(context, '/nostr/hastag', arguments: hashtag);
          },
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: hashtagWidgets,
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
        nip05: metadata['nip05'] ?? '',
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

  Padding _searchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, left: 15, right: 10, bottom: 10),
      child: Row(
        children: [
          // back button
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              //color: Palette.extraDarkGray,
              borderRadius: BorderRadius.circular(200),
            ),
            child: IconButton(
              icon: _searchFocusNode.hasFocus
                  ? const Icon(Icons.arrow_back)
                  : const Icon(Icons.search),
              color: Palette.white,
              onPressed: () {
                _searchController.clear();
                // unfocus search bar
                _searchFocusNode.hasFocus
                    ? _searchFocusNode.unfocus()
                    : _searchFocusNode.requestFocus();
              },
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                isDense: true,
                hintText: ' Search',
                hintStyle:
                    const TextStyle(color: Palette.white, letterSpacing: 1.1),
                filled: true,
                fillColor: _searchFocusNode.hasFocus
                    ? Palette.background
                    : Palette.extraDarkGray,
                enabledBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(50.0)),
                  borderSide: BorderSide(color: Palette.extraDarkGray),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(25.0)),
                  borderSide: BorderSide(color: Palette.background),
                ),
              ),
              style: const TextStyle(color: Palette.white),
              onChanged: (value) {
                _onSearchChanged(value);
              },
              onSubmitted: (value) {
                _onSubmit(value);
              },
              onTapOutside: (value) {
                // close keyboard
                //FocusScope.of(context).requestFocus(FocusNode());
              },
            ),
          ),
          const SizedBox(width: 5),
          SizedBox(
            width: 41,
            height: 41,
            child: IconButton(
              icon: SvgPicture.asset(
                'assets/icons/question.svg',
                color: Palette.extraLightGray,
              ),
              color: Palette.white,
              onPressed: () => _helpSearch(context),
            ),
          ),
        ],
      ),
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
