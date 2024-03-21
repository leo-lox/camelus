import 'dart:ui';

import 'package:camelus/helpers/helpers.dart';
import 'package:camelus/providers/navigation_bar_provider.dart';
import 'package:camelus/routes/notification_page.dart';
import 'package:camelus/routes/search_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_svg/svg.dart';
import 'package:camelus/components/write_post.dart';
import 'package:camelus/config/palette.dart';
import 'package:camelus/routes/nostr/nostr_drawer.dart';
import 'package:camelus/routes/nostr/nostr_page/nostr_page.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:matomo_tracker/matomo_tracker.dart';

class HomePage extends ConsumerStatefulWidget {
  final String pubkey;
  const HomePage({super.key, required this.pubkey});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;
  final PageController _myPage = PageController(initialPage: 0);

  void _show(BuildContext ctx) {
    showModalBottomSheet(
        isScrollControlled: true,
        elevation: 10,
        backgroundColor: Palette.background,
        isDismissible: false,
        context: ctx,
        builder: (ctx) => BackdropFilter(
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
          siteId: 3,
          url: 'https://customer.beonde.de/matomo/matomo.php',
          visitorId: myVisitorId,
        );
      } catch (e) {}
    });
  }

  @override
  void initState() {
    super.initState();
    _initMatomo();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final navBarProvider = ref.watch(navigationBarProvider);

    return Scaffold(
      key: _scaffoldKey,
      drawer: NostrDrawer(pubkey: widget.pubkey),
      backgroundColor: Palette.background,
      floatingActionButton: AnimatedOpacity(
        opacity: (_selectedIndex != 0) ? 0.0 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: FloatingActionButton(
          backgroundColor: Palette.primary,
          child: SvgPicture.asset(
            'assets/icons/plus.svg',
            color: Palette.white,
            height: 27,
            width: 27,
          ),
          onPressed: () => {
            _show(context),
          },
        ),
      ),
      body: SafeArea(
        child: PageView(
          controller: _myPage,
          physics: const NeverScrollableScrollPhysics(),
          children: <Widget>[
            NostrPage(parentScaffoldKey: _scaffoldKey, pubkey: widget.pubkey),
            const SearchPage(),
            const NotificationPage(),
            const Center(
              child: Text('work in progress',
                  style: TextStyle(color: Colors.white)),
            )
          ], // Comment this if you need to use Swipe.
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Palette.background,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (int index) {
          // used to notify feeds to scroll up
          if (index == 0) {
            navBarProvider.tabHome();
          }
          if (index == 1) {
            navBarProvider.tabSearch();
          }

          setState(() {
            _selectedIndex = index;
            // currentPage = pages[index];

            setState(() {
              _myPage.jumpToPage(index);
            });
          });
        },
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  children: <Widget>[
                    SvgPicture.asset(
                      height: 23,
                      'assets/icons/house.svg',
                      color: _selectedIndex == 0
                          ? Palette.primary
                          : Palette.darkGray,
                    ),
                    StreamBuilder<int>(
                        stream: navBarProvider.newNotesCountStream,
                        initialData: 0,
                        builder: (context, AsyncSnapshot<int> snapshot) {
                          if (!snapshot.hasData) return Container();
                          if (snapshot.data! < 1) return Container();
                          return Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.all(1),
                              decoration: BoxDecoration(
                                color: Palette.lightGray,
                                borderRadius: BorderRadius.circular(50),
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 12,
                                minHeight: 12,
                              ),
                            ),
                          );
                        })
                  ],
                ),
              ],
            ),
            tooltip: _selectedIndex == 0 ? "scroll to top" : "home",
            label: "home",
          ),
          BottomNavigationBarItem(
            icon: SvgPicture.asset(
              height: 23,
              'assets/icons/magnifying-glass.svg',
              color: _selectedIndex == 1 ? Palette.primary : Palette.darkGray,
            ),
            label: "",
          ),
          BottomNavigationBarItem(
            icon: SvgPicture.asset(
              height: 23,
              'assets/icons/bell.svg',
              color: _selectedIndex == 2 ? Palette.primary : Palette.darkGray,
            ),
            label: "",
          ),
          BottomNavigationBarItem(
            icon: SvgPicture.asset(
              height: 23,
              'assets/icons/chats.svg',
              color: _selectedIndex == 3 ? Palette.primary : Palette.darkGray,
            ),
            label: "",
          ),
        ],
      ),
    );
  }
}
