import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../config/palette.dart';
import '../../../domain_layer/entities/user_metadata.dart';
import '../../../helpers/nprofile_helper.dart';
import '../../atoms/my_profile_picture.dart';
import '../../providers/following_contact_state_provider.dart';
import '../../providers/metadata_state_provider.dart';
import '../../providers/ndk_provider.dart';

class NostrSideMenu extends ConsumerWidget {
  final Widget leadingWidget;
  final Widget trailingWidget;

  const NostrSideMenu({
    super.key,
    this.leadingWidget = const SizedBox(),
    this.trailingWidget = const SizedBox(),
  });

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("Copied to clipboard: $text"),
    ));
  }

  void openQrShareDialog(BuildContext context, String pubkey) async {
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

  Future<PackageInfo> _getPackageInfo() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();

    return packageInfo;
  }

  void navigateToProfile(BuildContext context, String pubkey) {
    context.push('/nostr/profile/$pubkey');
  }

  Widget _drawerItem(
      {required IconData icon, label, onTap, required String routeName}) {
    return Builder(
      builder: (context) {
        final currentRoute = GoRouterState.of(context).uri.toString();
        final isSelected = currentRoute.contains(routeName);

        return Container(
          decoration: isSelected
              ? BoxDecoration(
                  color: Palette.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                )
              : null,
          child: ListTile(
            onTap: onTap,
            leading: Icon(
              icon,
              color: isSelected ? Palette.primary : Palette.lightGray,
              size: 22,
            ),
            title: Text(
              label,
              style: TextStyle(
                color: isSelected ? Palette.primary : Palette.lightGray,
                fontSize: 17,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        );
      },
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserPubkey = ref.read(ndkProvider).accounts.getPublicKey()!;

    return Container(
      color: Palette.background,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          leadingWidget,
          _divider(),
          _drawerItem(
              icon: PhosphorIcons.house(),
              label: 'Home',
              routeName: '/home',
              onTap: () {
                context.go('/home');
              }),
          _drawerItem(
              label: 'Profile',
              routeName: '/nostr/profile',
              icon: PhosphorIcons.user(),
              onTap: () {
                navigateToProfile(context, currentUserPubkey);
              }),
          _drawerItem(
              label: 'Bookmarks',
              routeName: '/nostr/bookmarks',
              icon: PhosphorIcons.bookmarkSimple(),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Not implemented yet'),
                  ),
                );
              }),
          _drawerItem(
              label: 'Payments',
              routeName: 'payments',
              icon: PhosphorIcons.lightning(),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Not implemented yet'),
                  ),
                );
              }),
          _drawerItem(
              label: 'Blocklist',
              routeName: '/nostr/blockedUsers',
              icon: PhosphorIcons.yinYang(),
              onTap: () {
                context.push('/nostr/blockedUsers');
              }),
          const Spacer(),
          const Spacer(),
          _divider(),
          Padding(
              padding: const EdgeInsets.only(left: 20),
              child: _textButton(
                  text: 'Settings',
                  onPressed: () {
                    context.push("/settings");
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
                          color: Palette.gray,
                          fontSize: 10,
                        ),
                      ),
                      Text(
                        'build ${snapshot.data?.buildNumber}',
                        style: const TextStyle(
                          color: Palette.gray,
                          fontSize: 8,
                        ),
                      ),
                      Text(
                        '${snapshot.data?.buildSignature}',
                        style: const TextStyle(
                          color: Palette.gray,
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
                    openQrShareDialog(context, currentUserPubkey);
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
          trailingWidget
        ],
      ),
    );
  }
}
