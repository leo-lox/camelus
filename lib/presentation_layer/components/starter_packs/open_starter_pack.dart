import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ndk/shared/nips/nip19/nip19.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../config/palette.dart';
import '../../../domain_layer/entities/starter_pack_identifier.dart';
import '../../../helpers/helpers.dart';
import '../../../helpers/nprofile_helper.dart';
import '../../atoms/long_button.dart';
import '../../atoms/my_profile_picture.dart';
import '../../atoms/spinner_center.dart';
import '../../providers/inbox_outbox_provider.dart';
import '../../providers/metadata_state_provider.dart';
import '../../providers/ndk_provider.dart';
import '../../providers/nostr_list_provider.dart';
import '../../providers/nostr_lists_follow_state_provider.dart';
import '../../routes/nostr/profile/profile_page_2.dart';

class OpenStarterPack extends ConsumerStatefulWidget {
  final StarterPackIdentifier starterPackIdentifier;

  const OpenStarterPack({
    super.key,
    required this.starterPackIdentifier,
  });

  @override
  ConsumerState<OpenStarterPack> createState() => _OpenStarterPackState();
}

class _OpenStarterPackState extends ConsumerState<OpenStarterPack> {
  bool _isDeleting = false;
  bool _deleteSuccess = false;

  _onShare(WidgetRef ref) async {
    final inboxOutboxP = ref.read(inboxOutboxProvider);
    final nip65data =
        await inboxOutboxP.getNip65data(widget.starterPackIdentifier.pubkey);

    final outboxRelays = nip65data?.relays.entries
        .where((element) => element.value.isWrite)
        .map((e) => e.key)
        .toList();

    final npub = NprofileHelper().mapToBech32({
      "pubkey": widget.starterPackIdentifier.pubkey,
      "relays": outboxRelays ?? [],
    });

    final ndk = ref.watch(ndkProvider);

    final myPubkey = ndk.accounts.getPublicKey();

    final myNpub = Nip19.encodePubKey(myPubkey!);

    ///  /invitee/pubkeyList/listName
    final url =
        "https://camelus.app/i/${myNpub}/${widget.starterPackIdentifier.name}";

    await Clipboard.setData(
      ClipboardData(text: url),
    );
  }

  _onEdit(
    BuildContext context,
  ) {
    Navigator.pushNamed(context, '/edit-starter-pack',
        arguments: StarterPackIdentifier(
          name: widget.starterPackIdentifier.name,
          pubkey: widget.starterPackIdentifier.pubkey,
        ));
  }

  _showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Palette.extraDarkGray,
          title: Text(
            'Delete Starter Pack',
            style: TextStyle(color: Palette.white),
          ),
          content: Text(
            'Are you sure you want to delete this starter pack? This action cannot be undone.',
            style: TextStyle(color: Palette.lightGray),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancel',
                style: TextStyle(color: Palette.lightGray),
              ),
            ),
            TextButton(
              onPressed: () {
                // pop dialog
                Navigator.pop(context);
                _onDelete(ref, context);
              },
              child: Text(
                'Delete',
                style: TextStyle(color: Palette.primary),
              ),
            ),
          ],
        );
      },
    );
  }

  _onDelete(WidgetRef ref, BuildContext context) async {
    setState(() {
      _isDeleting = true;
    });

    final listP = ref.read(nostrListProvider);

    await listP.deleteStarterPack(name: widget.starterPackIdentifier.name);

    setState(() {
      _isDeleting = false;
      _deleteSuccess = true;
    });

    ref.invalidate(nostrListProvider);
    ref.invalidate(
      nostrListsFollowStateProvider(widget.starterPackIdentifier.pubkey),
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
  Widget build(BuildContext context) {
    final ndk = ref.watch(ndkProvider);

    final myPubkey = ndk.accounts.getPublicKey();

    final starterSets = ref
        .watch(
            nostrListsFollowStateProvider(widget.starterPackIdentifier.pubkey))
        .publicNostrFollowSets;
    final myStarterSet = starterSets
        .where((e) => e.name == widget.starterPackIdentifier.name)
        .firstOrNull;

    final bool isOwnStarterPack =
        myPubkey == widget.starterPackIdentifier.pubkey;

    if (_isDeleting) {
      return Scaffold(
        backgroundColor: Palette.black,
        body: Center(
          child: SpinnerCenter(),
        ),
      );
    }

    if (_deleteSuccess) {
      return Scaffold(
        backgroundColor: Palette.black,
        body: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "deletion requested",
                style: TextStyle(fontSize: 25),
              ),
              SizedBox(height: 25),
              longButton(
                name: "go back",
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      );
    }

    if (myStarterSet == null) {
      return Scaffold(
        backgroundColor: Palette.background,
        body: Center(
          child: Text("unknown starter pack"),
        ),
      );
    }

    return DefaultTabController(
      length: 1,
      child: Scaffold(
        backgroundColor: Palette.background,
        appBar: AppBar(
            title: Column(
              children: [],
            ),
            backgroundColor: Palette.background,
            toolbarHeight: 45,
            actions: [
              longButton(
                name: "share",
                onPressed: () => _onShare(ref),
                inverted: true,
              ),
              const SizedBox(
                width: 20,
              ),
              if (isOwnStarterPack)
                PopupMenuButton<String>(
                  icon: Icon(
                    PhosphorIcons.dotsThreeVertical(),
                    color: Palette.white,
                  ),
                  color: Palette.extraDarkGray,
                  onSelected: (String value) {
                    switch (value) {
                      case 'edit':
                        _onEdit(context);
                        break;
                      case 'delete':
                        _showDeleteConfirmationDialog(context);
                        break;
                    }
                  },
                  itemBuilder: (BuildContext context) => [
                    PopupMenuItem<String>(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(PhosphorIcons.pen(),
                              color: Palette.white, size: 20),
                          SizedBox(width: 8),
                          Text('Edit',
                              style: TextStyle(color: Palette.lightGray)),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(PhosphorIcons.trash(),
                              color: Colors.red, size: 20),
                          SizedBox(width: 8),
                          Text('Delete',
                              style: TextStyle(color: Palette.lightGray)),
                        ],
                      ),
                    ),
                  ],
                ),
              const SizedBox(
                width: 20,
              ),
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
                      if (myStarterSet.image != null)
                        Image.network(myStarterSet.image!,
                            width: 50, height: 50),
                      if (myStarterSet.image == null)
                        Image.asset("assets/images/list_placeholder.png",
                            width: 50, height: 50),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text.rich(TextSpan(
                            children: [
                              TextSpan(
                                text: myStarterSet.title ??
                                    widget.starterPackIdentifier.name,
                              ),
                            ],
                            style: TextStyle(
                              fontSize: 20,
                            ),
                          )),
                          Text(
                              "by ${isOwnStarterPack ? "you" : ref.watch(metadataStateProvider(widget.starterPackIdentifier.pubkey)).userMetadata?.name ?? Helpers().shortHr(
                                    widget.starterPackIdentifier.pubkey,
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
                    itemCount: myStarterSet.elements.length,
                    itemBuilder: (context, index) {
                      final displayPubkey = myStarterSet.elements[index].value;
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
          ],
        ),
      ),
    );
  }
}
