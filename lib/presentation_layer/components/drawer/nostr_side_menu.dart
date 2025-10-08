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
import '../../../helpers/nprofile_helper.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/ndk_provider.dart';

class NostrSideMenu extends ConsumerWidget {
  final Widget leadingWidget;
  final Widget trailingWidget;
  final Widget trailingButtonWidget;
  final bool hideOnMobile;

  const NostrSideMenu({
    super.key,
    this.leadingWidget = const SizedBox(),
    this.trailingWidget = const SizedBox(),
    this.trailingButtonWidget = const SizedBox(),
    this.hideOnMobile = false,
  });

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(AppLocalizations.of(context)!.copiedToClipboard(text)),
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
            backgroundColor: Theme.of(context).colorScheme.surface,

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
                    AppLocalizations.of(context)!.shareYourProfile,
                    style: const TextStyle(color: Colors.white),
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
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface),
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

  Widget _drawerItem({
    required IconData icon,
    label,
    onTap,
    required String routeName,
  }) {
    return Builder(
      builder: (context) {
        final currentRoute = GoRouterState.of(context).uri.toString();
        final isSelected = currentRoute.contains(routeName);

        return Container(
          width: 200,
          decoration: isSelected
              ? BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(100),
                )
              : null,
          child: ListTile(
            onTap: onTap,
            leading: Icon(
              icon,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface,
              size: 22,
            ),
            title: Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Paletter.getLightGray(context),
                fontSize: 17,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _textButton({
    text,
    onPressed,
    required BuildContext context,
  }) {
    return TextButton(
        onPressed: onPressed,
        child: Text(
          text,
          style: TextStyle(
              color: Paletter.getExtraLightGray(context), fontSize: 16),
        ));
  }

  Widget _divider(BuildContext context) {
    return Divider(
      thickness: 0.3,
      color: Paletter.getDarkGray(context),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserPubkey = ref.read(ndkProvider).accounts.getPublicKey()!;

    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          leadingWidget,
          _divider(context),
          _drawerItem(
              icon: PhosphorIcons.house(),
              label: AppLocalizations.of(context)!.routeHome,
              routeName: '/home',
              onTap: () {
                context.go('/home');
              }),
          if (!hideOnMobile)
            _drawerItem(
                icon: PhosphorIcons.magnifyingGlass(),
                label: AppLocalizations.of(context)!.explore,
                routeName: '/search',
                onTap: () {
                  context.go('/search');
                }),
          if (!hideOnMobile)
            _drawerItem(
                icon: PhosphorIcons.bell(),
                label: AppLocalizations.of(context)!.routeNotifications,
                routeName: '/notifications',
                onTap: () {
                  context.go('/notifications');
                }),
          _drawerItem(
              label: AppLocalizations.of(context)!.profile,
              routeName: '/nostr/profile',
              icon: PhosphorIcons.user(),
              onTap: () {
                navigateToProfile(context, currentUserPubkey);
              }),
          _drawerItem(
              label: AppLocalizations.of(context)!.bookmarks,
              routeName: '/nostr/bookmarks',
              icon: PhosphorIcons.bookmarkSimple(),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.of(context)!.notImplementedYet),
                  ),
                );
              }),
          _drawerItem(
              label: AppLocalizations.of(context)!.payments,
              routeName: 'payments',
              icon: PhosphorIcons.lightning(),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.of(context)!.notImplementedYet),
                  ),
                );
              }),
          _drawerItem(
              label: AppLocalizations.of(context)!.blocklist,
              routeName: '/nostr/blockedUsers',
              icon: PhosphorIcons.yinYang(),
              onTap: () {
                context.push('/nostr/blockedUsers');
              }),
          trailingButtonWidget,
          const Spacer(),
          const Spacer(),
          _divider(context),
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: _textButton(
                text: AppLocalizations.of(context)!.settings,
                onPressed: () {
                  context.push("/settings");
                },
                context: context),
          ),
          const SizedBox(height: 10),
          Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 15, 20),
              child: _textButton(
                  text: AppLocalizations.of(context)!.termsOfService,
                  context: context,
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
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 10,
                        ),
                      ),
                      Text(
                        'build ${snapshot.data?.buildNumber}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 8,
                        ),
                      ),
                      Text(
                        '${snapshot.data?.buildSignature}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 6,
                        ),
                      ),
                    ],
                  );
                }),
          ),
          _divider(context),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 15, 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SvgPicture.asset(
                  'assets/icons/sun.svg',
                  color: Theme.of(context).colorScheme.primary,
                  height: 22,
                  width: 22,
                ),
                GestureDetector(
                  onTap: () {
                    openQrShareDialog(context, currentUserPubkey);
                  },
                  child: SvgPicture.asset(
                    'assets/icons/qr-code.svg',
                    color: Theme.of(context).colorScheme.primary,
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
