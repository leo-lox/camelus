import 'dart:ui';

import 'package:camelus/routes/notification_page.dart';
import 'package:camelus/routes/search_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_svg/svg.dart';
import 'package:camelus/components/write_post.dart';
import 'package:camelus/config/palette.dart';
import 'package:camelus/routes/nostr/nostr_drawer.dart';
import 'package:camelus/routes/nostr/nostr_page/nostr_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;
  PageController _myPage = PageController(initialPage: 0);

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
                  child: WritePost()),
            ));
  }

  void checkForOnboarding() {
    // check secure storage for keys
    const storage = FlutterSecureStorage();
    storage.read(key: "nostrKeys").then((nostrKeysString) {
      if (nostrKeysString == null) {
        // if keys are not found, redirect to onboarding
        Navigator.popAndPushNamed(context, '/onboarding');
      }
    });
  }

  @override
  void initState() {
    checkForOnboarding();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: NostrDrawer(),
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
            NostrPage(parentScaffoldKey: _scaffoldKey),
            SearchPage(),
            NotificationPage(),
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
            icon: SvgPicture.asset(
              height: 23,
              'assets/icons/house.svg',
              color: _selectedIndex == 0 ? Palette.primary : Palette.darkGray,
            ),
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
