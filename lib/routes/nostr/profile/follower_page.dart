import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:camelus/config/palette.dart';
import 'package:camelus/helpers/helpers.dart';
import 'package:camelus/routes/nostr/profile/profile_page.dart';
import 'package:camelus/services/nostr/nostr_injector.dart';
import 'package:camelus/services/nostr/nostr_service.dart';

import 'package:camelus/atoms/my_profile_picture.dart';

class FollowerPage extends StatefulWidget {
  late NostrService _nostrService;
  String title;
  List<List<dynamic>> contacts;

  FollowerPage({
    Key? key,
    required this.title,
    required this.contacts,
  }) : super(key: key) {
    NostrServiceInjector injector = NostrServiceInjector();
    _nostrService = injector.nostrService;
  }

  @override
  State<FollowerPage> createState() => _FollowerPageState();
}

class _FollowerPageState extends State<FollowerPage> {
  List<String> _myFollowing = [];
  List<String> _myNewFollowing = [];
  List<String> _myNewUnfollowing = [];

  void getFollowed() {
    List<List> folloing =
        widget._nostrService.following[widget._nostrService.myKeys.publicKey] ??
            [];
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

      widget._nostrService.writeEvent("", 3, tags);

      // update following locally
      widget._nostrService.following[widget._nostrService.myKeys.publicKey] =
          [];
      for (var i = 0; i < _myFollowing.length; i++) {
        var d = ["p", _myFollowing[i]];
        widget._nostrService.following[widget._nostrService.myKeys.publicKey]!
            .add(d);
      }
    }
    // get updated contacts
    widget._nostrService.getUserContacts(widget._nostrService.myKeys.publicKey);
  }

  @override
  void initState() {
    super.initState();
    getFollowed();
  }

  @override
  void dispose() {
    _calculateFollowing();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                return _profile(widget.contacts[index][1], widget, _myFollowing,
                    _myNewFollowing, _myNewUnfollowing, _updateUi);
              },
              childCount: widget.contacts.length,
            ),
          ),
        ],
      ),
    );
  }
}

Widget _profile(String pubkey, widget, List myFollowing, List myNewFollowing,
    List myNewUnfollowing, Function updateUi) {
  Future<String> checkNip05(String nip05, String pubkey) async {
    try {
      var check = await widget._nostrService.checkNip05(nip05, pubkey);

      if (check["valid"] == true) {
        return check["nip05"];
      }
      // ignore: empty_catches
    } catch (e) {}
    return "";
  }

  return FutureBuilder<Map>(
      future: widget._nostrService.getUserMetadata(pubkey),
      builder: (BuildContext context, AsyncSnapshot<Map> snapshot) {
        String picture = "";
        String name = "";
        String about = "";
        String? nip05 = "";

        if (snapshot.hasData) {
          picture = snapshot.data?["picture"] ??
              "https://avatars.dicebear.com/api/personas/${pubkey}.svg";
          name =
              snapshot.data?["name"] ?? Helpers().encodeBech32(pubkey, "npub");
          about = snapshot.data?["about"] ?? "";
          nip05 = snapshot.data?["nip05"] ?? "";
        } else if (snapshot.hasError) {
          picture = "https://avatars.dicebear.com/api/personas/${pubkey}.svg";
          name = Helpers().encodeBech32(pubkey, "npub");
          about = "";
        } else {
          // loading
          picture = "https://avatars.dicebear.com/api/personas/${pubkey}.svg";
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
                child: myProfilePicture(picture, pubkey),
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
              if (!myFollowing.contains(pubkey))
                Container(
                  margin: const EdgeInsets.only(top: 0, right: 10),
                  child: ElevatedButton(
                    onPressed: () {
                      myFollowing.add(pubkey);
                      myNewFollowing.add(pubkey);
                      updateUi();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Palette.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(color: Palette.black, width: 1),
                      ),
                    ),
                    child: const Text(
                      'follow',
                      style: TextStyle(
                        color: Palette.black,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),

              if (myFollowing.contains(pubkey))
                Container(
                  margin: const EdgeInsets.only(top: 0, right: 10),
                  child: ElevatedButton(
                    onPressed: () {
                      myFollowing.remove(pubkey);
                      myNewUnfollowing.add(pubkey);
                      updateUi();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Palette.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: const BorderSide(color: Palette.white, width: 1),
                      ),
                    ),
                    child: const Text(
                      'unfollow',
                      style: TextStyle(
                        color: Palette.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      });
}
