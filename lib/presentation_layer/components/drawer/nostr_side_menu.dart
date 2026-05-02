import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:ndk/shared/nips/nip19/nip19.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/app_bar_provider/app_bottom_bar_provider.dart';
import '../../providers/wallet_settings_provider.dart';
import '../../routing/route_paths.dart';
import '../../providers/messaging/dm_conversations_provider.dart';
import '../../providers/ndk_provider.dart';
import '../../providers/theme_provider.dart';

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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.copiedToClipboard(text)),
      ),
    );
  }

  void openQrShareDialog(BuildContext context, String pubkey) async {
    String nprofile = Nip19.encodeNprofile(
      pubkey: pubkey,
    ); //todo: get recommended relays

    if (!context.mounted) return;
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
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  void navigateToProfile(BuildContext context, String pubkey) {
    context.push(RoutePaths.profile(pubkey: pubkey));
  }

  Widget _drawerItem({
    required IconData icon,
    label,
    onTap,
    required String routeName,
    int badgeCount = 0,
  }) {
    return Builder(
      builder: (context) {
        final currentRoute = GoRouterState.of(context).uri.path;
        final isSelected = currentRoute == routeName;

        final iconWidget = Icon(
          icon,
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurface,
          size: 22,
        );

        return Material(
          type: MaterialType.transparency,
          child: Ink(
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(100),
            ),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(100),
              hoverColor: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.05),
              splashColor: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.08),
              highlightColor: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.04),
              child: ListTile(
                onTap: null,
                leading: badgeCount > 0
                    ? Badge(
                        label: Text(
                          badgeCount > 99 ? '99+' : badgeCount.toString(),
                        ),
                        child: iconWidget,
                      )
                    : iconWidget,
                title: Text(
                  label,
                  style: TextStyle(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.inverseSurface,
                    fontSize: 17,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _textButton({
    required String text,
    required void Function()? onPressed,
    required BuildContext context,
  }) {
    return TextButton(
      onPressed: onPressed,
      child: Text(
        text,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _divider(BuildContext context) {
    return Divider(
      thickness: 0.3,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserPubkey = ref.read(ndkProvider).accounts.getPublicKey();
    final dmUnreadCount = ref.watch(dmUnreadCountProvider).value ?? 0;

    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          leadingWidget,
          _divider(context),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.only(left: 8.0, right: 23.0),
                child: Column(
                  spacing: 2,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _drawerItem(
                      icon: PhosphorIcons.house(),
                      label: AppLocalizations.of(context)!.routeHome,
                      routeName: '/home',
                      onTap: () {
                        context.go('/home');
                        ref
                            .read(appBottomNavigationBarProvider.notifier)
                            .selectTab(NavigationTab.home);
                      },
                    ),
                    if (!hideOnMobile)
                      _drawerItem(
                        icon: PhosphorIcons.magnifyingGlass(),
                        label: AppLocalizations.of(context)!.explore,
                        routeName: '/search',
                        onTap: () {
                          context.go('/search');
                          ref
                              .read(appBottomNavigationBarProvider.notifier)
                              .selectTab(NavigationTab.search);
                        },
                      ),
                    if (!hideOnMobile)
                      _drawerItem(
                        icon: PhosphorIcons.bell(),
                        label: AppLocalizations.of(context)!.routeNotifications,
                        routeName: '/notifications',
                        onTap: () {
                          context.go('/notifications');
                          ref
                              .read(appBottomNavigationBarProvider.notifier)
                              .selectTab(NavigationTab.notifications);
                        },
                      ),
                    if (!hideOnMobile && currentUserPubkey != null)
                      _drawerItem(
                        icon: PhosphorIcons.chatCircle(),
                        label: AppLocalizations.of(context)!.messages,
                        routeName: '/messages',
                        badgeCount: dmUnreadCount,
                        onTap: () {
                          context.go('/messages');
                          ref
                              .read(appBottomNavigationBarProvider.notifier)
                              .selectTab(NavigationTab.chat);
                        },
                      ),
                    if (currentUserPubkey != null) ...[
                      _drawerItem(
                        label: AppLocalizations.of(context)!.bookmarks,
                        routeName: '/bookmarks',
                        icon: PhosphorIcons.bookmarkSimple(),
                        onTap: () {
                          context.push('/bookmarks');
                        },
                      ),
                      _drawerItem(
                        label: AppLocalizations.of(context)!.lists,
                        routeName: '/lists',
                        icon: PhosphorIcons.listBullets(),
                        onTap: () {
                          context.push('/lists');
                        },
                      ),
                      _drawerItem(
                        label: AppLocalizations.of(context)!.profile,
                        routeName:
                            '/profile/${Nip19.encodePubKey(currentUserPubkey)}',
                        icon: PhosphorIcons.user(),
                        onTap: () {
                          navigateToProfile(context, currentUserPubkey);
                        },
                      ),
                      if (ref.watch(experimentalFeaturesProvider).wallet)
                        _drawerItem(
                          label: AppLocalizations.of(context)!.payments,
                          routeName: '/wallet/dashboard',
                          icon: PhosphorIcons.lightning(),
                          onTap: () {
                            context.push('/wallet/dashboard');
                          },
                        ),
                      _drawerItem(
                        label: AppLocalizations.of(context)!.blocklist,
                        routeName: '/blocked-users',
                        icon: PhosphorIcons.yinYang(),
                        onTap: () {
                          context.push('/blocked-users');
                        },
                      ),
                    ] else ...[
                      // Show login option when not authenticated
                      _drawerItem(
                        label: AppLocalizations.of(context)!.login,
                        routeName: '/onboarding',
                        icon: PhosphorIcons.signIn(),
                        onTap: () {
                          context.push('/onboarding');
                        },
                      ),
                    ],
                    trailingButtonWidget,
                  ],
                ),
              ),
            ),
          ),
          _divider(context),
          Padding(
            padding: const EdgeInsets.only(left: 5),
            child: _textButton(
              text: AppLocalizations.of(context)!.settings,
              onPressed: () {
                context.push("/settings");
              },
              context: context,
            ),
          ),
          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  minimumSize: const Size(50, 10),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () {
                  final url = Uri.parse("https://about.camelus.app/");
                  launchUrl(url, mode: LaunchMode.externalApplication);
                },
                child: Text(
                  AppLocalizations.of(context)!.about,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  minimumSize: const Size(50, 10),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () {
                  final url = Uri.parse("https://about.camelus.app/terms");
                  launchUrl(url, mode: LaunchMode.externalApplication);
                },
                child: Text(
                  AppLocalizations.of(context)!.termsOfService,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ),

              TextButton(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  minimumSize: const Size(50, 10),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () {
                  final url = Uri.parse("https://about.camelus.app/imprint");
                  launchUrl(url, mode: LaunchMode.externalApplication);
                },
                child: Text(
                  AppLocalizations.of(context)!.imprint,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
          _divider(context),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 15, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () {
                    ref.read(themeProvider.notifier).toggleTheme();
                  },
                  icon: Icon(
                    ref.watch(themeProvider).mode == ThemeMode.dark
                        ? PhosphorIcons.moon()
                        : PhosphorIcons.sun(),
                    color: Theme.of(context).colorScheme.primary,
                    size: 22,
                  ),
                ),
                if (currentUserPubkey != null)
                  IconButton(
                    onPressed: () {
                      openQrShareDialog(context, currentUserPubkey);
                    },
                    icon: Icon(PhosphorIcons.qrCode()),
                  ),
              ],
            ),
          ),
          trailingWidget,
        ],
      ),
    );
  }
}
