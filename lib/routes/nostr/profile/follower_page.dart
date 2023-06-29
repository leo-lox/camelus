import 'package:camelus/atoms/follow_button.dart';
import 'package:camelus/models/nostr_tag.dart';
import 'package:camelus/providers/metadata_provider.dart';
import 'package:camelus/providers/nostr_service_provider.dart';
import 'package:camelus/services/nostr/metadata/user_metadata.dart';
import 'package:flutter/material.dart';
import 'package:camelus/config/palette.dart';
import 'package:camelus/helpers/helpers.dart';
import 'package:camelus/routes/nostr/profile/profile_page.dart';
import 'package:camelus/services/nostr/nostr_injector.dart';
import 'package:camelus/services/nostr/nostr_service.dart';

import 'package:camelus/atoms/my_profile_picture.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class FollowerPage extends ConsumerStatefulWidget {
  String title;
  List<NostrTag> contacts;

  FollowerPage({
    Key? key,
    required this.title,
    required this.contacts,
  }) : super(key: key) {}

  @override
  ConsumerState<FollowerPage> createState() => _FollowerPageState();
}

class _FollowerPageState extends ConsumerState<FollowerPage> {
  late NostrService _nostrService;
  List<String> _myFollowing = [];
  final List<String> _myNewFollowing = [];
  final List<String> _myNewUnfollowing = [];

  void getFollowed() {
    List<List> folloing =
        _nostrService.following[_nostrService.myKeys.publicKey] ?? [];
    for (var i = 0; i < folloing.length; i++) {
      _myFollowing.add(folloing[i][1]);
    }

    setState(() {
      _myFollowing = _myFollowing;
    });
  }

  _updateUi() {
    setState(() {});
  }

  _calculateFollowing() {
    for (var i = 0; i < _myNewFollowing.length; i++) {
      if (!_myFollowing.contains(_myNewFollowing[i])) {
        _myFollowing.add(_myNewFollowing[i]);
      }
    }

    for (var i = 0; i < _myNewUnfollowing.length; i++) {
      if (_myFollowing.contains(_myNewUnfollowing[i])) {
        _myFollowing.remove(_myNewUnfollowing[i]);
      }
    }
    if (_myNewFollowing.isNotEmpty || _myNewUnfollowing.isNotEmpty) {
      // write event to nostr

      var tags = [];

      for (var i = 0; i < _myFollowing.length; i++) {
        var d = ["p", _myFollowing[i]];
        tags.add(d);
      }

      _nostrService.writeEvent("", 3, tags);

      // update following locally
      _nostrService.following[_nostrService.myKeys.publicKey] = [];
      for (var i = 0; i < _myFollowing.length; i++) {
        var d = ["p", _myFollowing[i]];
        _nostrService.following[_nostrService.myKeys.publicKey]!.add(d);
      }
    }
    // get updated contacts
    _nostrService.getUserContacts(_nostrService.myKeys.publicKey);
  }

  void _initNostrService() {
    _nostrService = ref.read(nostrServiceProvider);
  }

  @override
  void initState() {
    super.initState();
    _initNostrService();
    getFollowed();
  }

  @override
  void dispose() {
    _calculateFollowing();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var metadata = ref.watch(metadataProvider);
    return Scaffold(
      backgroundColor: Palette.background,
      appBar: AppBar(
        backgroundColor: Palette.background,
        title: Text(widget.title),
      ),
      body: CustomScrollView(
        slivers: [
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return _profile(
                    widget.contacts[index].value,
                    widget,
                    _myFollowing,
                    _myNewFollowing,
                    _myNewUnfollowing,
                    _updateUi,
                    _nostrService,
                    metadata);
              },
              childCount: widget.contacts.length,
            ),
          ),
        ],
      ),
    );
  }
}

Widget _profile(
    String pubkey,
    widget,
    List myFollowing,
    List myNewFollowing,
    List myNewUnfollowing,
    Function updateUi,
    NostrService nostrService,
    UserMetadata metadata) {
  Future<String> checkNip05(String nip05, String pubkey) async {
    try {
      var check = await nostrService.checkNip05(nip05, pubkey);

      if (check["valid"] == true) {
        return check["nip05"];
      }
      // ignore: empty_catches
    } catch (e) {}
    return "";
  }

  return FutureBuilder<Map>(
      future: metadata.getMetadataByPubkey(pubkey),
      builder: (BuildContext context, AsyncSnapshot<Map> snapshot) {
        String picture = "";
        String name = "";
        String about = "";
        String? nip05 = "";

        if (snapshot.hasData) {
          picture = snapshot.data?["picture"] ??
              "https://avatars.dicebear.com/api/personas/$pubkey.svg";
          name =
              snapshot.data?["name"] ?? Helpers().encodeBech32(pubkey, "npub");
          about = snapshot.data?["about"] ?? "";
          nip05 = snapshot.data?["nip05"] ?? "";
        } else if (snapshot.hasError) {
          picture = "https://avatars.dicebear.com/api/personas/$pubkey.svg";
          name = Helpers().encodeBech32(pubkey, "npub");
          about = "";
        } else {
          // loading
          picture = "https://avatars.dicebear.com/api/personas/$pubkey.svg";
          name = "loading...";
          about = "";
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
          child: Row(
            // profile
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfilePage(
                        pubkey: pubkey,
                      ),
                    ),
                  );
                },
                child: myProfilePicture(
                    pictureUrl: picture,
                    pubkey: pubkey,
                    filterQuality: FilterQuality.high),
              ),
              const SizedBox(width: 16),
              //text section
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfilePage(
                          pubkey: pubkey,
                        ),
                      ),
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (name.startsWith("npub"))
                        Text(
                          "${name.substring(0, 7)}...${name.substring(name.length - 7, name.length)}",
                          style: const TextStyle(
                            color: Palette.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      if (!name.startsWith("npub"))
                        Row(
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                color: Palette.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            FutureBuilder(
                                future: checkNip05(nip05 ?? "", pubkey),
                                builder: (context, snapshot) {
                                  if (snapshot.hasData && snapshot.data != "") {
                                    return Container(
                                      margin: const EdgeInsets.only(
                                          top: 0, left: 5),
                                      child: const Icon(
                                        Icons.verified,
                                        color: Palette.white,
                                        size: 18,
                                      ),
                                    );
                                  } else {
                                    return Container();
                                  }
                                }),
                          ],
                        ),
                      const SizedBox(height: 4),
                      SizedBox(
                        // 1/3 of screen width
                        width: MediaQuery.of(context).size.width / 2,
                        child: Text(
                          about,
                          style: const TextStyle(
                            color: Palette.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 16),
              //follow and unfollow button
              followButton(
                  isFollowing: myFollowing.contains(pubkey),
                  onPressed: () {
                    if (!myFollowing.contains(pubkey)) {
                      myFollowing.add(pubkey);
                      myNewFollowing.add(pubkey);
                      updateUi();
                    } else {
                      myFollowing.remove(pubkey);
                      myNewUnfollowing.add(pubkey);
                      updateUi();
                    }
                  }),
            ],
          ),
        );
      });
}
