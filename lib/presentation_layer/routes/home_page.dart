import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:camelus/presentation_layer/components/write_post.dart';
import 'package:camelus/config/palette.dart';
import 'package:camelus/presentation_layer/routes/nostr/nostr_drawer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:matomo_tracker/matomo_tracker.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain_layer/entities/app_update.dart';
import '../../helpers/helpers.dart';
import '../components/app_bottom_navigation_bar/app_bottom_navigation_bar.dart';
import '../providers/app_bar_provider/app_bottom_bar_provider.dart';
import '../providers/app_update_provider.dart';
import '../providers/language_provider.dart';
import 'nostr/nostr_page/nostr_page.dart';
import 'notification_page.dart';
import 'search_page.dart';

class HomePage extends ConsumerStatefulWidget {
  final String pubkey;
  final String? initialTab;
  final int initialPage;

  const HomePage({
    super.key,
    required this.pubkey,
    this.initialTab,
    this.initialPage = 0,
  });

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final PageController _myPage = PageController(initialPage: 0);

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
        backgroundColor: Paletter.getBackground(context),
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
      _myPage.jumpToPage(widget.initialPage);

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

    return Scaffold(
      key: _scaffoldKey,
      drawer: NostrDrawer(pubkey: widget.pubkey),
      backgroundColor: Paletter.getBackground(context),
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
                backgroundColor: Paletter.getPrimary(context),
                child: Icon(
                  PhosphorIcons.plus(),
                  color: Paletter.getWhite(context),
                  size: 27,
                ),
                onPressed: () => {
                  _show(context),
                },
              )
            : null,
      ),
      body: SafeArea(
        child: PageView(
          controller: _myPage,
          physics: const NeverScrollableScrollPhysics(),
          children: <Widget>[
            NostrPage(
              parentScaffoldKey: _scaffoldKey,
              pubkey: widget.pubkey,
              initialTab: widget.initialTab,
            ),
            const SearchPage(),
            NotificationPage(
              pubkey: widget.pubkey,
            ),
            Center(
              child: Text('work in progress',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
            )
          ],
          onPageChanged: (index) {
            // Update the selected tab when page changes
            ref
                .read(appBottomNavigationBarProvider.notifier)
                .selectTab(NavigationTab.values[index]);
          },
        ),
      ),
      bottomNavigationBar: AppBottomNavigationBar(
        pageController: _myPage,
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
          child: const Text("Cancel"),
          onPressed: () => Navigator.of(context).pop(),
        ),
        TextButton(
          child: const Text("Update"),
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
