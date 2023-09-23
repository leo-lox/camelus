import 'dart:async';
import 'package:camelus/atoms/my_profile_picture.dart';
import 'package:camelus/atoms/spinner_center.dart';
import 'package:camelus/config/palette.dart';
import 'package:camelus/db/entities/db_user_metadata.dart';
import 'package:camelus/helpers/helpers.dart';
import 'package:camelus/models/nostr_tag.dart';
import 'package:camelus/providers/block_mute_provider.dart';
import 'package:camelus/providers/metadata_provider.dart';
import 'package:camelus/providers/relay_provider.dart';
import 'package:camelus/services/nostr/metadata/block_mute_service.dart';
import 'package:camelus/services/nostr/metadata/user_metadata.dart';
import 'package:camelus/services/nostr/relays/relay_coordinator.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class BlockedUsers extends ConsumerStatefulWidget {
  const BlockedUsers({Key? key}) : super(key: key);

  @override
  ConsumerState<BlockedUsers> createState() => _BlockedUsersState();
}

class _BlockedUsersState extends ConsumerState<BlockedUsers> {
  late final BlockMuteService blockMuteService;
  late final RelayCoordinator relayService;

  Completer initDone = Completer();

  List<NostrTag> contentTags = [];

  @override
  void initState() {
    super.initState();
    _initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _initState() async {
    blockMuteService = await ref.read(blockMuteProvider.future);
    relayService = ref.read(relayServiceProvider);

    // get current state
    contentTags = blockMuteService.contentObj;
    initDone.complete();
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
        body: FutureBuilder(
            future: initDone.future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return spinnerCenter();
              }

              return StreamBuilder<List<NostrTag>>(
                  stream: blockMuteService.blockListStream,
                  initialData: blockMuteService.contentObj,
                  builder: (context, snapshot) {
                    if (snapshot.data == null) {
                      return spinnerCenter();
                    }
                    return CustomScrollView(
                      slivers: [
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              return _profile(
                                snapshot.data![index].value,
                                widget,
                                blockMuteService,
                                metadata,
                                relayService,
                              );
                            },
                            childCount: snapshot.data!.length,
                          ),
                        ),
                        if (snapshot.data!.isEmpty) // is empty
                          const SliverFillRemaining(
                            child: Center(
                              child: Text(
                                "No blocked users",
                                style: TextStyle(
                                    color: Palette.gray, fontSize: 24),
                              ),
                            ),
                          ),
                      ],
                    );
                  });
            }));
  }
}

Widget _profile(String pubkey, widget, BlockMuteService muteService,
    UserMetadata userMetadata, RelayCoordinator relayService) {
  return StreamBuilder<DbUserMetadata?>(
      stream: userMetadata.getMetadataByPubkeyStream(pubkey),
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
          name = Helpers().encodeBech32(pubkey, "npub");
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
                  muteService.unBlockUser(
                      pubkey: pubkey, relayService: relayService);
                },
              ),
            ],
          ),
        );
      });
}
