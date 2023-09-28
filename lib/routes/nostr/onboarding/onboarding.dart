import 'dart:convert';
import 'dart:developer';

import 'package:camelus/providers/key_pair_provider.dart';
import 'package:camelus/routes/home_page.dart';
import 'package:camelus/routes/nostr/onboarding/onboarding_login.dart';

import 'package:camelus/routes/nostr/onboarding/onboarding_page01.dart';

import 'package:flutter/material.dart';
import 'package:camelus/config/palette.dart';
import 'package:camelus/helpers/bip340.dart';
import 'package:flutter/services.dart';
import 'package:camelus/helpers/helpers.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:url_launcher/url_launcher.dart';

class NostrOnboarding extends ConsumerStatefulWidget {
  const NostrOnboarding({Key? key}) : super(key: key);

  @override
  ConsumerState<NostrOnboarding> createState() => _NostrOnboardingState();
}

class _NostrOnboardingState extends ConsumerState<NostrOnboarding>
    with TickerProviderStateMixin {
  var myKeys = Bip340().generatePrivateKey();

  bool _termsAndConditions = false;

  late TabController _tabController;

  final PageController _horizontalPageController = PageController(
    initialPage: 1,
    keepPage: true,
  );
  bool horizontalScrollLock = false;

  void _setupTabLiseners() {
    // listen to changes of tabs
    _tabController.addListener(() {
      if (_tabController.index >= 1) {
        setState(() {
          horizontalScrollLock = true;
        });
      } else {
        setState(() {
          horizontalScrollLock = false;
        });
      }
    });
    _horizontalPageController.addListener(() {
      if (horizontalScrollLock) {
        _horizontalPageController.jumpToPage(1);
      }
    });
  }

  _navigateToLogin() {
    _horizontalPageController.animateToPage(0,
        duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      initialIndex: 0,
      vsync: this,
    );
    _setupTabLiseners();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> copyToClipboard(String data) async {
    await Clipboard.setData(ClipboardData(text: data));
  }

  void _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    //check if data starts not with with nsec
    if (data == null || !(data.text!.startsWith('nsec'))) {
      showPasteError();
      return;
    }

    var privkey = Helpers().decodeBech32(data.text!)[0];
    var pubkey = Bip340().getPublicKey(privkey);
    var privKeyHr = data.text!;
    var publicKeyHr = Helpers().encodeBech32(pubkey, 'npub');

    setState(() {
      myKeys = KeyPair(privkey, pubkey, privKeyHr, publicKeyHr);
    });
    showPasteSuccess();
  }

  void showPasteSuccess() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Private key successfully imported'),
      ),
    );
  }

  void showPasteError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Invalid private key'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palette.background,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: PageView(
          controller: _horizontalPageController,
          scrollDirection: Axis.vertical,
          children: [
            OnboardingLoginPage(),
            TabBarView(
              controller: _tabController,
              children: [
                OnboardingPage01(
                  loginCallback: _navigateToLogin,
                  registerCallback: () {
                    _tabController.animateTo(
                      1,
                      curve: Curves.easeInOut,
                      duration: const Duration(milliseconds: 500),
                    );
                  },
                ),
                Text("page2"),
                Text("page3"),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
