import 'dart:async';

import 'package:camelus/atoms/my_profile_picture.dart';
import 'package:camelus/config/palette.dart';
import 'package:camelus/db/entities/db_user_metadata.dart';
import 'package:camelus/helpers/helpers.dart';
import 'package:camelus/providers/metadata_provider.dart';

import 'package:camelus/services/nostr/metadata/user_metadata.dart';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class BlockedUsers extends ConsumerStatefulWidget {
  const BlockedUsers({Key? key}) : super(key: key);

  @override
  ConsumerState<BlockedUsers> createState() => _BlockedUsersState();
}

class _BlockedUsersState extends ConsumerState<BlockedUsers> {
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
    var metadata = ref.watch(metadataProvider);
    return Scaffold(
        backgroundColor: Palette.background,
        appBar: AppBar(
          backgroundColor: Palette.background,
          title: const Text('Blocked Users'),
        ),
        body: CustomScrollView(
          slivers: [
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return _profile("pubkeyTODO", _streamController, widget,
                      metadata, metadata); //_nostrService.blockedUsers[index]
                },
                childCount: 0, //_nostrService.blockedUsers.length
              ),
            ),
            if (false) // is empty
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

Widget _profile(String pubkey, StreamController streamController, widget,
    UserMetadata nostrService, UserMetadata userMetadata) {
  return FutureBuilder<DbUserMetadata?>(
      future: userMetadata.getMetadataByPubkey(pubkey),
      builder: (BuildContext context, AsyncSnapshot<DbUserMetadata?> snapshot) {
        String picture = "";
        String name = "";
        String about = "";

        if (snapshot.hasData) {
          picture = snapshot.data?.picture ??
              "https://avatars.dicebear.com/api/personas/$pubkey.svg";
          name = snapshot.data?.name ?? Helpers().encodeBech32(pubkey, "npub");
          about = snapshot.data?.about ?? "";
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
            children: [
              myProfilePicture(pictureUrl: picture, pubkey: pubkey),
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
                  //nostrService.removeFromBlocklist(pubkey);
                  streamController.add(true);
                },
              ),
            ],
          ),
        );
      });
}
