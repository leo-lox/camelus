import 'dart:async';

import 'package:camelus/atoms/my_profile_picture.dart';
import 'package:camelus/config/palette.dart';
import 'package:camelus/helpers/helpers.dart';
import 'package:camelus/services/nostr/nostr_injector.dart';
import 'package:camelus/services/nostr/nostr_service.dart';
import 'package:flutter/material.dart';

class BlockedUsers extends StatefulWidget {
  late NostrService _nostrService;
  BlockedUsers({Key? key}) : super(key: key) {
    NostrServiceInjector injector = NostrServiceInjector();
    _nostrService = injector.nostrService;
  }

  @override
  State<BlockedUsers> createState() => _BlockedUsersState();
}

class _BlockedUsersState extends State<BlockedUsers> {
  final StreamController _streamController = StreamController();

  @override
  void initState() {
    super.initState();
    _streamController.stream.listen((event) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _streamController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Palette.background,
        appBar: AppBar(
          backgroundColor: Palette.background,
          title: Text('Blocked Users'),
        ),
        body: CustomScrollView(
          slivers: [
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return _profile(widget._nostrService.blockedUsers[index],
                      _streamController, widget);
                },
                childCount: widget._nostrService.blockedUsers.length,
              ),
            ),
            if (widget._nostrService.blockedUsers.isEmpty)
              const SliverFillRemaining(
                child: Center(
                  child: Text(
                    "No blocked users",
                    style: TextStyle(color: Palette.gray, fontSize: 24),
                  ),
                ),
              ),
          ],
        ));
  }
}

Widget _profile(String pubkey, StreamController streamController, widget) {
  return FutureBuilder<Map>(
      future: widget._nostrService.getUserMetadata(pubkey),
      builder: (BuildContext context, AsyncSnapshot<Map> snapshot) {
        String picture = "";
        String name = "";
        String about = "";

        if (snapshot.hasData) {
          picture = snapshot.data?["picture"] ??
              "https://avatars.dicebear.com/api/personas/${pubkey}.svg";
          name =
              snapshot.data?["name"] ?? Helpers().encodeBech32(pubkey, "npub");
          about = snapshot.data?["about"] ?? "";
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
            children: [
              myProfilePicture(picture, pubkey),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Palette.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.block_flipped),
                color: Palette.white,
                onPressed: () {
                  widget._nostrService.removeFromBlocklist(pubkey);
                  streamController.add(true);
                },
              ),
            ],
          ),
        );
      });
}
