import 'dart:convert';
import 'dart:developer';

import 'package:camelus/providers/key_pair_provider.dart';
import 'package:camelus/routes/home_page.dart';
import 'package:camelus/routes/nostr/onboarding/onboarding_page01.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:camelus/config/palette.dart';
import 'package:camelus/helpers/bip340.dart';
import 'package:flutter/services.dart';
import 'package:camelus/helpers/helpers.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intro_slider/intro_slider.dart';
import 'package:url_launcher/url_launcher.dart';

class NostrOnboarding extends ConsumerStatefulWidget {
  const NostrOnboarding({Key? key}) : super(key: key);

  @override
  ConsumerState<NostrOnboarding> createState() => _NostrOnboardingState();
}

class _NostrOnboardingState extends ConsumerState<NostrOnboarding> {
  var myKeys = Bip340().generatePrivateKey();

  bool _termsAndConditions = false;

  @override
  void initState() {
    super.initState();
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

  _onSubmit() async {
    if (!_termsAndConditions) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Please read and accept the terms and conditions first'),
        ),
      );
      return;
    }

    // store in secure storage
    const storage = FlutterSecureStorage();
    storage.write(key: "nostrKeys", value: json.encode(myKeys.toJson()));
    // save in provider

    var provider = await ref.watch(keyPairProvider.future);
    provider.setKeyPair(myKeys);

    setState(() {});

    // ignore: use_build_context_synchronously
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) {
      return HomePage(pubkey: myKeys.publicKey);
    }));

    //Navigator.popAndPushNamed(context, '/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palette.background,
      body: SafeArea(
        child: IntroSlider(
          isShowSkipBtn: false,
          isShowNextBtn: false,
          listCustomTabs: [
            OnboardingPage01(),
            Text("page2"),
            Text("page3"),
          ],
        ),
      ),
    );
  }
}
