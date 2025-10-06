import 'dart:ui';

import 'package:camelus/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:matomo_tracker/matomo_tracker.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/palette.dart';
import '../../domain_layer/entities/app_update.dart';
import '../../helpers/helpers.dart';
import '../components/drawer/nostr_drawer.dart';
import '../components/write_post.dart';
import '../providers/app_bar_provider/app_bottom_bar_provider.dart';
import '../providers/app_update_provider.dart';
import '../providers/language_provider.dart';
import '../providers/ndk_provider.dart';
import 'nostr/nostr_page/nostr_page.dart';

class HomePage extends ConsumerStatefulWidget {
  final String? initialTab;
  final int initialPage;

  const HomePage({
    super.key,
    this.initialTab,
    this.initialPage = 0,
  });

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Future<void> _checkForUpdates() async {
    await Future.delayed(const Duration(seconds: 15));
    if (!mounted) return;

    final appUpdate = ref.read(appUpdateProvider);
    final updateInfo = await appUpdate.call();

    if (updateInfo.isUpdateAvailable && mounted) {
      _showUpdateDialog(updateInfo);
    }
  }

  void _showUpdateDialog(AppUpdate updateInfo) {
    showDialog(
      context: context,
      builder: (BuildContext context) => UpdateDialog(updateInfo: updateInfo),
    );
  }

  void _show(BuildContext context) {
    showModalBottomSheet(
        isScrollControlled: true,
        elevation: 10,
        isDismissible: false,
        context: context,
        builder: (context) => BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Padding(
                  padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom),
                  child: const WritePost()),
            ));
  }

  void _initMatomo() async {
    // get or create visitor id
    const storage = FlutterSecureStorage();

    storage.read(key: "visitorId").then((visitorId) async {
      var myVisitorId = visitorId;
      if (myVisitorId == null) {
        myVisitorId = Helpers().getRandomString(16);
        // if visitor id is not found, create one
        storage.write(key: "visitorId", value: myVisitorId);
      }
      try {
        //todo: fix onboarding
        await MatomoTracker.instance.initialize(
          siteId: "3",
          url: 'https://customer.beonde.de/matomo/matomo.php',
          visitorId: myVisitorId,
        );
      } catch (e) {
        //
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _initMatomo();
    _checkForUpdates();

    // set initail page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // set system locale if no locale is set
      ref
          .read(languageProvider.notifier)
          .initializeWithSystemLocaleIfNeeded(context);
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final navigationState = ref.watch(appBottomNavigationBarProvider);

    final isHomeSelected = navigationState.selectedTab == NavigationTab.home;

    final currentUserPubkey = ref.read(ndkProvider).accounts.getPublicKey()!;

    return Scaffold(
      key: _scaffoldKey,
      drawer: NostrDrawer(pubkey: currentUserPubkey),
      backgroundColor: Theme.of(context).colorScheme.surface,
      floatingActionButton: AnimatedSwitcher(
        duration: const Duration(milliseconds: 150),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        child: isHomeSelected
            ? FloatingActionButton(
                key: const ValueKey<String>('FAB'),
                backgroundColor: Theme.of(context).colorScheme.onPrimary,
                child: Icon(
                  PhosphorIcons.plus(),
                  color: Theme.of(context).colorScheme.onSurface,
                  size: 27,
                ),
                onPressed: () => {
                  _show(context),
                },
              )
            : null,
      ),
      body: SafeArea(
        child: NostrPage(
          parentScaffoldKey: _scaffoldKey,
          pubkey: currentUserPubkey,
          initialTab: widget.initialTab,
        ),
      ),
    );
  }
}

class UpdateDialog extends StatelessWidget {
  final AppUpdate updateInfo;

  const UpdateDialog({super.key, required this.updateInfo});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Paletter.getExtraDarkGray(context),
      title: Text(updateInfo.title),
      content: Text(updateInfo.body),
      actions: <Widget>[
        TextButton(
          child: Text(AppLocalizations.of(context)!.cancel),
          onPressed: () => Navigator.of(context).pop(),
        ),
        TextButton(
          child: Text(AppLocalizations.of(context)!.update),
          onPressed: () {
            launchUrl(Uri.parse(updateInfo.url),
                mode: LaunchMode.externalApplication);
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
