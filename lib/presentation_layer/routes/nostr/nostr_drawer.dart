import 'package:camelus/domain_layer/entities/user_metadata.dart';

import 'package:camelus/helpers/nprofile_helper.dart';

import 'package:camelus/presentation_layer/atoms/my_profile_picture.dart';

import 'package:camelus/presentation_layer/providers/metadata_state_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:camelus/config/palette.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/following_contact_state_provider.dart';

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
            backgroundColor: Paletter.getExtraDarkGray(context),

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
                  Text(
                    "Share your Profile",
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                  ),
                  const SizedBox(height: 40),
                  QrImageView(
                    data: "nostr:$nprofile",
                    version: QrVersions.auto,
                    size: 300.0,
                    backgroundColor: Theme.of(context).colorScheme.surface,

                    //embeddedImage: AssetImage('assets/app_icons/icon.png'),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () => _copyToClipboard(context, nprofile),
                    child: Text(
                      "nostr:$nprofile",
                      style: TextStyle(color: Paletter.getLightGray(context)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        });
  }

  Widget _drawerHeader(context, UserMetadata? metadata, WidgetRef ref) {
    final myContactList = ref.watch(contactListSelfStateProvider);
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
              decoration: BoxDecoration(
                color: Paletter.getPrimary(context),
                shape: BoxShape.circle,
              ),
              child: UserImage(
                imageUrl: metadata?.picture,
                pubkey: pubkey,
              ),
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          metadata?.name ?? '',
                          style: TextStyle(
                              color: Paletter.getExtraLightGray(context),
                              fontSize: 17,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(
                          height: 3,
                        ),
                        Text(
                          metadata?.nip05 ?? '',
                          style: TextStyle(
                            color: Paletter.getGray(context),
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                //Icon(
                //  Icons.arrow_drop_down_rounded,
                //  color: Paletter.getPrimary(context),
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
              RichText(
                text: TextSpan(
                  text: !myContactList.isLoading
                      ? myContactList.contactList.contacts.length.toString()
                      : 'n.a.',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Paletter.getExtraLightGray(context),
                  ),
                  children: [
                    TextSpan(
                      text: ' Following  ',
                      style: TextStyle(
                          color: Paletter.getGray(context),
                          fontSize: 13,
                          fontWeight: FontWeight.normal),
                    )
                  ],
                ),
              ),
              const SizedBox(
                width: 6,
              ),
              RichText(
                  text: TextSpan(
                      text: 'n.a.',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Paletter.getExtraLightGray(context),
                      ),
                      children: [
                    TextSpan(
                      text: 'Followers',
                      style: TextStyle(
                          color: Paletter.getGray(context),
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
    return Builder(
      builder: (context) {
        return ListTile(
          onTap: onTap,
          leading: SvgPicture.asset(
            icon,
            height: 25,
            colorFilter: ColorFilter.mode(Paletter.getGray(context), BlendMode.srcIn),
          ),
          title: Text(label,
              style: TextStyle(color: Paletter.getLightGray(context), fontSize: 17)),
        );
      }
    );
  }

  Widget _textButton({text, onPressed}) {
    return TextButton(
        onPressed: onPressed,
        child: Builder(
          builder: (context) {
            return Text(
              text,
              style: TextStyle(color: Paletter.getExtraLightGray(context), fontSize: 16),
            );
          }
        ));
  }

  Widget _divider() {
    return Builder(
      builder: (context) {
        return Divider(
          thickness: 0.3,
          color: Paletter.getDarkGray(context),
        );
      }
    );
  }

  // Add method to get version
  Future<PackageInfo> _getPackageInfo() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();

    return packageInfo;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myUserMetadata =
        ref.watch(metadataStateProvider(pubkey)).userMetadata;

    return Drawer(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _drawerHeader(context, myUserMetadata, ref),
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
                        style: TextStyle(
                          color: Paletter.getGray(context),
                          fontSize: 10,
                        ),
                      ),
                      Text(
                        'build ${snapshot.data?.buildNumber}',
                        style: TextStyle(
                          color: Paletter.getGray(context),
                          fontSize: 8,
                        ),
                      ),
                      Text(
                        '${snapshot.data?.buildSignature}',
                        style: TextStyle(
                          color: Paletter.getGray(context),
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
                  colorFilter: ColorFilter.mode(Paletter.getPrimary(context), BlendMode.srcIn),
                  height: 22,
                  width: 22,
                ),
                GestureDetector(
                  onTap: () {
                    openQrShareDialog(context);
                  },
                  child: SvgPicture.asset(
                    'assets/icons/qr-code.svg',
                    colorFilter: ColorFilter.mode(Paletter.getPrimary(context), BlendMode.srcIn),
                    height: 22,
                    width: 22,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
