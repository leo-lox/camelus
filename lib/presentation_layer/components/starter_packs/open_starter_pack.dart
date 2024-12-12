import 'package:camelus/helpers/helpers.dart';
import 'package:camelus/helpers/nevent_helper.dart';
import 'package:camelus/helpers/nprofile_helper.dart';
import 'package:camelus/presentation_layer/atoms/follow_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/palette.dart';
import '../../../domain_layer/entities/nostr_list.dart';
import '../../atoms/long_button.dart';
import '../../atoms/my_profile_picture.dart';
import '../../providers/event_signer_provider.dart';
import '../../providers/inbox_outbox_provider.dart';
import '../../providers/metadata_state_provider.dart';
import '../../routes/nostr/profile/profile_page_2.dart';

class OpenStarterPack extends ConsumerWidget {
  final NostrSet followSet;

  const OpenStarterPack({
    super.key,
    required this.followSet,
  });

  _onShare(WidgetRef ref) async {
    final inboxOutboxP = ref.read(inboxOutboxProvider);
    final nip65data = await inboxOutboxP.getNip65data(followSet.pubKey);

    final outboxRelays = nip65data?.relays.entries
        .where((element) => element.value.isWrite)
        .map((e) => e.key)
        .toList();

    final npub = NprofileHelper().mapToBech32({
      "pubkey": followSet.pubKey,
      "relays": outboxRelays ?? [],
    });

    final url = "https://camelus.app/i/$npub/${followSet.name}";

    await Clipboard.setData(
      ClipboardData(text: url),
    );
  }

  _navigateToProfile(BuildContext context, String pubkey) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfilePage2(
          pubkey: pubkey,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mySigner = ref.watch(eventSignerProvider);

    final myPubkey = mySigner?.getPublicKey();

    final bool isOwnStarterPack = myPubkey == followSet.pubKey;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Palette.background,
        appBar: AppBar(
            title: Column(
              children: [],
            ),
            backgroundColor: Palette.background,
            toolbarHeight: 45,
            actions: [
              if (isOwnStarterPack)
                longButton(
                  name: "share",
                  onPressed: () => _onShare(ref),
                  inverted: true,
                ),
              const SizedBox(
                width: 20,
              )
            ]),
        body: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              height: 70,
              child: Column(
                children: [
                  Row(
                    children: [
                      if (followSet.image != null)
                        Image.network(followSet.image!, width: 50, height: 50),
                      if (followSet.image == null)
                        Image.asset("assets/images/list_placeholder.png",
                            width: 50, height: 50),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text.rich(TextSpan(
                            children: [
                              TextSpan(
                                text: followSet.title ?? followSet.name,
                              ),
                            ],
                            style: TextStyle(
                              fontSize: 20,
                            ),
                          )),
                          Text(
                              "by ${isOwnStarterPack ? "you" : ref.watch(metadataStateProvider(followSet.pubKey)).userMetadata?.name ?? Helpers().shortHr(
                                    followSet.pubKey,
                                  )}",
                              style: TextStyle(color: Palette.gray)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: followSet.elements.length,
                    itemBuilder: (context, index) {
                      final displayPubkey = followSet.elements[index].value;
                      final displayMetadata = ref
                          .watch(metadataStateProvider(displayPubkey))
                          .userMetadata;
                      return ListTile(
                        onTap: () {
                          _navigateToProfile(context, displayPubkey);
                        },
                        title: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            UserImage(
                              imageUrl: displayMetadata?.picture,
                              pubkey: displayPubkey,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    displayMetadata?.name ?? "",
                                    style: const TextStyle(
                                      color: Palette.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    displayMetadata?.about ?? "",
                                    style: const TextStyle(
                                      color: Palette.gray,
                                      fontSize: 12,
                                    ),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        trailing: SizedBox(
                          height: 0,
                          width: 0,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(
              height: 15,
            ),
            if (false)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                width: 400,
                height: 40,
                child: longButton(
                  name: "wip",
                  onPressed: (() {}),
                  disabled: false,
                  inverted: true,
                ),
              ),
            const SizedBox(
              height: 15,
            ),
          ],
        ),
      ),
    );
  }
}
