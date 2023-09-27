import 'dart:convert';

import 'package:camelus/atoms/long_button.dart';
import 'package:camelus/config/palette.dart';
import 'package:camelus/helpers/bip340.dart';
import 'package:camelus/helpers/helpers.dart';
import 'package:camelus/providers/key_pair_provider.dart';
import 'package:camelus/routes/home_page.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:bip39_mnemonic/bip39_mnemonic.dart';

class OnboardingLoginPage extends ConsumerStatefulWidget {
  const OnboardingLoginPage({Key? key}) : super(key: key);
  @override
  ConsumerState<OnboardingLoginPage> createState() =>
      _OnboardingLoginPageState();
}

class _OnboardingLoginPageState extends ConsumerState<OnboardingLoginPage> {
  bool _termsAndConditions = false;

  KeyPair? myKeys;

  final TextEditingController _inputController = TextEditingController();

  List<String> _userWords = [];

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

    if (myKeys == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please import your private key first'),
        ),
      );
      return;
    }

    // store in secure storage
    const storage = FlutterSecureStorage();
    storage.write(key: "nostrKeys", value: json.encode(myKeys!.toJson()));
    // save in provider

    var provider = await ref.watch(keyPairProvider.future);
    provider.setKeyPair(myKeys!);

    setState(() {});

    // ignore: use_build_context_synchronously
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) {
      return HomePage(pubkey: myKeys!.publicKey);
    }));

    //Navigator.popAndPushNamed(context, '/');
  }

  bool _checkWord(String word) {
    const english = Language.english;

    return english.isValid(word);
  }

  void _addWords(String words) {
    List<String> wordList = words.split(' ');
    for (var word in wordList) {
      _addWord(word);
    }
    setState(() {
      _userWords = _userWords;
    });
    // clear textfield
    _inputController.clear();
  }

  void _addWord(String word) {
    word = word.toLowerCase();
    if (word.startsWith("nsec")) {
      throw Exception("Todo implement nsec1");
    }

    if (word.startsWith("npub")) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          duration: Duration(seconds: 20),
          showCloseIcon: true,
          content: Text(
              'you entered a public key, please enter a private key, it starts with nsec1'),
        ),
      );
      return;
    }

    if (_checkWord(word)) {
      _userWords.add(word);
    }
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
              const SizedBox(height: 20),
              Container(
                width: MediaQuery.of(context).size.width,
                height: 200,
                decoration: BoxDecoration(
                  color: Palette.extraDarkGray,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Palette.darkGray,
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: GridView.count(
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 5,
                      crossAxisCount: 3,
                      childAspectRatio: (20 / 9),
                      dragStartBehavior: DragStartBehavior.start,
                      children: List.generate(
                        _userWords.length,
                        (index) {
                          return Center(
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    (index + 1).toString(),
                                    style: const TextStyle(
                                      color: Palette.gray,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    _userWords[index],
                                    style: const TextStyle(
                                      color: Palette.extraLightGray,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),
              Spacer(flex: 1),
              Container(
                child: TextField(
                  autofillHints: Language.english.list,
                  controller: _inputController,
                  decoration: const InputDecoration(
                    isDense: true,
                    hintText: 'enter your seed phrase or nsec1',
                    hintStyle: const TextStyle(
                        color: Palette.white, letterSpacing: 1.1),
                    filled: true,
                    fillColor: Palette.extraDarkGray,
                    enabledBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                      borderSide: BorderSide(color: Palette.extraDarkGray),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                      borderSide: BorderSide(color: Palette.background),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    height: 31,
                    child: ElevatedButton(
                      onPressed: () {
                        _pasteFromClipboard();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Palette.background,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side:
                              const BorderSide(color: Palette.white, width: 1),
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
                  ),
                  SizedBox(
                    height: 31,
                    child: ElevatedButton(
                      onPressed: () {
                        _addWords(_inputController.text);
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
                        'add',
                        style: TextStyle(
                          color: Palette.background,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 50),
              // checkbox to accept the privacy policy

              const SizedBox(height: 15),
              const Spacer(flex: 1),
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

              const SizedBox(height: 20),

              SizedBox(
                width: MediaQuery.of(context).size.width,
                height: 40,
                child: longButton(
                  name: "login",
                  inverted: true,
                  onPressed: () => _onSubmit(),
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
