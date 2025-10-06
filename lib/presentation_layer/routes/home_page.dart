import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../components/drawer/nostr_drawer.dart';
import '../components/write_post.dart';
import '../providers/app_bar_provider/app_bottom_bar_provider.dart';
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

  @override
  void initState() {
    super.initState();

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
