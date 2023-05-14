import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:camelus/config/palette.dart';
import 'package:camelus/helpers/bip340.dart';
import 'package:flutter/services.dart';
import 'package:camelus/helpers/helpers.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:camelus/services/nostr/nostr_injector.dart';
import 'package:camelus/services/nostr/nostr_service.dart';
import 'package:url_launcher/url_launcher.dart';

class NostrOnboarding extends StatefulWidget {
  late NostrService _nostrService;
  NostrOnboarding({Key? key}) : super(key: key) {
    NostrServiceInjector injector = NostrServiceInjector();
    _nostrService = injector.nostrService;
  }

  @override
  State<NostrOnboarding> createState() => _NostrOnboardingState();
}

class _NostrOnboardingState extends State<NostrOnboarding> {
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

  _onSubmit() {
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

    widget._nostrService.finishedOnboarding();

    Navigator.popAndPushNamed(context, '/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null,
      backgroundColor: Palette.background,
      body: SafeArea(
        // input for the user to enter their private key, should be visible on a dark background.
        child: Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              // the logo
              const Text(
                "camelus",
                style: TextStyle(
                    color: Palette.white,
                    fontSize: 45,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              // the title
              const Text(
                "early preview",
                style: TextStyle(
                  color: Palette.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              // the subtitle

              const SizedBox(height: 20),
              // the input field

              const Text(
                "This is your private key:",
                style: TextStyle(
                  color: Palette.white,
                  fontSize: 24,
                  fontWeight: FontWeight.normal,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: MediaQuery.of(context).size.width,
                height: 60,
                decoration: BoxDecoration(
                  color: Palette.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: GestureDetector(
                      onTap: () {
                        copyToClipboard(myKeys.privateKeyHr);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('private key copied to clipboard'),
                            duration: Duration(seconds: 3),
                          ),
                        );
                      },
                      child: Text(
                        myKeys.privateKeyHr,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),
              const Text(
                "keep it safe and secret!",
                style: TextStyle(
                  color: Palette.white,
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                ),
              ),
              const SizedBox(height: 50),
              // checkbox to accept the privacy policy

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      _pasteFromClipboard();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Palette.background,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: const BorderSide(color: Palette.white, width: 1),
                      ),
                    ),
                    child: const Text(
                      'paste',
                      style: TextStyle(
                        color: Palette.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      _onSubmit();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Palette.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: const BorderSide(
                            color: Palette.background, width: 1),
                      ),
                    ),
                    child: const Text(
                      'next',
                      style: TextStyle(
                        color: Palette.background,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Checkbox(
                    value: _termsAndConditions,
                    onChanged: (value) {
                      setState(() {
                        _termsAndConditions = value!;
                      });
                    },
                    activeColor: Palette.white,
                    checkColor: Palette.black,
                    fillColor: MaterialStateProperty.all(Palette.white),
                    //overlayColor: MaterialStateProperty.all(Palette.primary),
                  ),
                  const Text(
                    "I have read and accept the ",
                    style: TextStyle(
                      color: Palette.white,
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Uri url = Uri.parse("https://camelus.app/terms/");
                      launchUrl(url, mode: LaunchMode.externalApplication);
                    },
                    child: const Text(
                      "terms and conditions",
                      style: TextStyle(
                        color: Palette.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 5),
              GestureDetector(
                onTap: () {
                  Uri url = Uri.parse("https://camelus.app/privacy/");
                  launchUrl(url, mode: LaunchMode.externalApplication);
                },
                child: const Text(
                  "privacy policy",
                  style: TextStyle(
                    color: Palette.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),

              const Spacer(),

              // the bottom text
              const Text(
                "This is a very early version of the app, use at your own risk. \n\nI would not recommend using this app with your personal keys. Just use the generated ones for testing.",
                style: TextStyle(
                  color: Palette.gray,
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
