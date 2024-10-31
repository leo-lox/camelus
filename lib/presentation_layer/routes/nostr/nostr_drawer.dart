import 'package:camelus/domain_layer/entities/contact_list.dart';
import 'package:camelus/domain_layer/entities/user_metadata.dart';
import 'package:camelus/domain_layer/usecases/follow.dart';
import 'package:camelus/domain_layer/usecases/get_user_metadata.dart';
import 'package:camelus/helpers/nprofile_helper.dart';
import 'package:camelus/domain_layer/entities/nostr_tag.dart';
import 'package:camelus/presentation_layer/atoms/my_profile_picture.dart';
import 'package:camelus/presentation_layer/providers/following_provider.dart';
import 'package:camelus/presentation_layer/providers/metadata_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:camelus/config/palette.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class NostrDrawer extends ConsumerWidget {
  final String pubkey;

  //late NostrService _nostrService;

  const NostrDrawer({super.key, required this.pubkey});

  void navigateToProfile(BuildContext context) {
    Navigator.pushNamed(context, "/nostr/profile", arguments: pubkey);
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("Copied to clipboard: $text"),
    ));
  }

  void openQrShareDialog(BuildContext context) async {
    String nprofile = await NprofileHelper()
        .getNprofile(pubkey, []); //todo: get recommended relays

    // ignore: use_build_context_synchronously
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            backgroundColor: Palette.extraDarkGray,

            //white border
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              //side: const BorderSide(color: Colors.white, width: 1),
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Share your Profile",
                    style: TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 40),
                  QrImageView(
                    data: "nostr:$nprofile",
                    version: QrVersions.auto,
                    size: 300.0,
                    backgroundColor: Colors.white,

                    //embeddedImage: AssetImage('assets/app_icons/icon.png'),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () => _copyToClipboard(context, nprofile),
                    child: Text(
                      "nostr:$nprofile",
                      style: const TextStyle(color: Palette.lightGray),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        });
  }

  Widget _drawerHeader(
      context, GetUserMetadata metadata, Follow followingService) {
    return DrawerHeader(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => navigateToProfile(context),
            child: Container(
              width: 35,
              height: 35,
              decoration: const BoxDecoration(
                color: Palette.primary,
                shape: BoxShape.circle,
              ),
              child: StreamBuilder<UserMetadata?>(
                  stream: metadata.getMetadataByPubkey(pubkey),
                  builder: (BuildContext context,
                      AsyncSnapshot<UserMetadata?> snapshot) {
                    return UserImage(
                      imageUrl: snapshot.data?.picture,
                      pubkey: pubkey,
                    );
                  }),
            ),
          ),
          const SizedBox(
            height: 8,
          ),
          GestureDetector(
            onTap: () => navigateToProfile(context),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StreamBuilder<UserMetadata?>(
                        stream: metadata.getMetadataByPubkey(pubkey),
                        builder: (BuildContext context,
                            AsyncSnapshot<UserMetadata?> snapshot) {
                          var name = "";
                          var nip05 = "";

                          if (snapshot.hasData) {
                            name = snapshot.data?.name ?? "";
                            nip05 = snapshot.data?.nip05 ?? "";
                          } else if (snapshot.hasError) {
                            name = "error";
                            nip05 = "error";
                          } else {
                            // loading
                            name = snapshot.data?.name ?? "";
                            nip05 = snapshot.data?.nip05 ?? "";
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                    color: Palette.extraLightGray,
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(
                                height: 3,
                              ),
                              Text(
                                nip05,
                                style: const TextStyle(
                                  color: Palette.gray,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          );
                        }),
                  ],
                ),
                //Icon(
                //  Icons.arrow_drop_down_rounded,
                //  color: Palette.primary,
                //  size: 30,
                //)
              ],
            ),
          ),
          const SizedBox(
            height: 15,
          ),
          Row(
            children: [
              FutureBuilder<ContactList?>(
                  future: followingService.getContacts(pubkey),
                  builder: (context, snapshot) {
                    return RichText(
                        text: TextSpan(
                            text: snapshot.hasData
                                ? snapshot.data?.contacts.length.toString()
                                : 'n.a.',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Palette.extraLightGray,
                            ),
                            children: const [
                          TextSpan(
                            text: ' Following  ',
                            style: TextStyle(
                                color: Palette.gray,
                                fontSize: 13,
                                fontWeight: FontWeight.normal),
                          )
                        ]));
                  }),
              const SizedBox(
                width: 6,
              ),
              RichText(
                  text: const TextSpan(
                      text: 'n.a.',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Palette.extraLightGray,
                      ),
                      children: [
                    TextSpan(
                      text: 'Followers',
                      style: TextStyle(
                          color: Palette.gray,
                          fontSize: 13,
                          fontWeight: FontWeight.normal),
                    )
                  ])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _drawerItem({icon, label, onTap}) {
    return ListTile(
      onTap: onTap,
      leading: SvgPicture.asset(
        icon,
        height: 25,
        color: Palette.gray,
      ),
      title: Text(label,
          style: const TextStyle(color: Palette.lightGray, fontSize: 17)),
    );
  }

  Widget _textButton({text, onPressed}) {
    return TextButton(
        onPressed: onPressed,
        child: Text(
          text,
          style: const TextStyle(color: Palette.extraLightGray, fontSize: 16),
        ));
  }

  Widget _divider() {
    return const Divider(
      thickness: 0.3,
      color: Palette.darkGray,
    );
  }

  // Add method to get version
  Future<PackageInfo> _getPackageInfo() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();

    return packageInfo;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var metadata = ref.watch(metadataProvider);
    var followingService = ref.watch(followingProvider);

    return Drawer(
      child: Container(
        color: Palette.background,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _drawerHeader(context, metadata, followingService),
            _divider(),
            _drawerItem(
                label: 'Profile',
                icon: 'assets/icons/user.svg',
                onTap: () {
                  navigateToProfile(context);
                }),
            _drawerItem(
                label: 'Bookmarks',
                icon: 'assets/icons/bookmark-simple.svg',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Not implemented yet'),
                    ),
                  );
                }),
            _drawerItem(
                label: 'Payments',
                icon: 'assets/icons/lightning.svg',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Not implemented yet'),
                    ),
                  );
                }),
            _drawerItem(
                label: 'Blocklist',
                icon: 'assets/icons/yin-yang.svg',
                onTap: () {
                  // navigate to blocklist
                  Navigator.pushNamed(context, '/nostr/blockedUsers');
                }),
            const Spacer(),
            const Spacer(),
            _divider(),
            Padding(
                padding: const EdgeInsets.only(left: 20),
                child: _textButton(
                    text: 'Settings',
                    onPressed: () {
                      Navigator.pushNamed(context, '/settings');
                    })),
            const SizedBox(height: 10),
            Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 15, 20),
                child: _textButton(
                    text: 'Terms of Service',
                    onPressed: () {
                      // lauch url
                      Uri url = Uri.parse("https://camelus.app/terms");
                      launchUrl(url, mode: LaunchMode.externalApplication);
                    })),
            const Spacer(),
            Padding(
              padding: EdgeInsets.only(left: 20),
              child: FutureBuilder(
                  future: _getPackageInfo(),
                  builder: (context, snapshot) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'v${snapshot.data?.version}',
                          style: const TextStyle(
                            color: Palette.extraLightGray,
                            fontSize: 10,
                          ),
                        ),
                        Text(
                          'build ${snapshot.data?.buildNumber}',
                          style: const TextStyle(
                            color: Palette.extraLightGray,
                            fontSize: 8,
                          ),
                        ),
                        Text(
                          '${snapshot.data?.buildSignature}',
                          style: const TextStyle(
                            color: Palette.extraLightGray,
                            fontSize: 6,
                          ),
                        ),
                      ],
                    );
                  }),
            ),
            _divider(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 15, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SvgPicture.asset(
                    'assets/icons/sun.svg',
                    color: Palette.primary,
                    height: 22,
                    width: 22,
                  ),
                  GestureDetector(
                    onTap: () {
                      openQrShareDialog(context);
                    },
                    child: SvgPicture.asset(
                      'assets/icons/qr-code.svg',
                      color: Palette.primary,
                      height: 22,
                      width: 22,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
