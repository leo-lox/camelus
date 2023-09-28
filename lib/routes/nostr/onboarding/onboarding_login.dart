import 'dart:convert';
import 'dart:developer';

import 'package:bip32/bip32.dart' as bip32;
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
import 'package:hex/hex.dart';
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
  final FocusNode _inputFocusNode = FocusNode();

  List<String> _userWords = [];
  String? mneonicError;
  String? _userNsec = "";

  void _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    //check if data starts not with with nsec
    if (data == null) {
      showPasteError();
      return;
    }
    _addWords(data.text!);
  }

  void showPasteError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Invalid private key or seed phrase'),
      ),
    );
  }

  bool _setNsec(String nsec) {
    try {
      var privkey = Helpers().decodeBech32(nsec)[0];
      var pubkey = Bip340().getPublicKey(privkey);
      var privKeyHr = nsec;
      var publicKeyHr = Helpers().encodeBech32(pubkey, 'npub');

      setState(() {
        myKeys = KeyPair(privkey, pubkey, privKeyHr, publicKeyHr);
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  bool _getPrivkeyFromSeed(String seed) {
    try {
      final mnemonic3 = Mnemonic.fromSentence(seed, Language.english);

      // list int to bytes

      final Uint8List seedBytes = Uint8List.fromList(mnemonic3.entropy);
      bip32.BIP32 node = bip32.BIP32.fromSeed(seedBytes);

      //  m/44'/1237'/<account>'/0/0
      bip32.BIP32 child = node.derivePath("m/44'/1237'/0'/0/0");

      final privkeyHex = HEX.encode(child.privateKey!);

      var pubkey = Bip340().getPublicKey(privkeyHex);
      var privKeyHr = Helpers().encodeBech32(privkeyHex, 'nsec');
      var publicKeyHr = Helpers().encodeBech32(pubkey, 'npub');

      setState(() {
        myKeys = KeyPair(privkeyHex, pubkey, privKeyHr, publicKeyHr);
      });
      return true;
    } catch (e) {
      setState(() {
        mneonicError = e.toString();
      });
      return false;
    }
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

    if (_userWords.isNotEmpty) {
      _getPrivkeyFromSeed(_userWords.join(" "));
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
      setState(() {
        _userWords = [];
        _userNsec = word;
      });
      _setNsec(word);
      return;
    }
    setState(() {
      _userNsec = null;
    });

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
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'word: $word is not valid, check if it is spelled correctly'),
        ),
      );
    }

    mneonicError = null;
    if (_userWords.length == 12 || _userWords.length == 24) {
      _getPrivkeyFromSeed(_userWords.join(" "));
    }
  }

  @override
  void initState() {
    super.initState();
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

              if (_userWords.isNotEmpty)
                Column(
                  children: [
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
                      child: seedPhraseCheck(),
                    ),
                    const SizedBox(height: 5),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(mneonicError ?? "",
                              style: const TextStyle(
                                color: Palette.error,
                                fontSize: 12,
                              )),
                          Text(
                            "${_userWords.length}/${(_userWords.length <= 12 ? "12" : "24")}",
                            style: TextStyle(
                              color: (_userWords.length > 24)
                                  ? Palette.error
                                  : Palette.white,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              if (_userWords.isEmpty)
                SizedBox(
                  height: 200,
                  width: MediaQuery.of(context).size.width,
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "login",
                        style: TextStyle(
                          color: Palette.white,
                          fontSize: 40,
                          fontFamily: "Poppins",
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 10),

              AnimatedOpacity(
                opacity: (_userNsec != null && myKeys != null) ? 1 : 0,
                duration: const Duration(milliseconds: 300),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Text("your public key is:"),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: Palette.extraDarkGray,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Palette.darkGray,
                          width: 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: SizedBox(
                          height: 40,
                          child: Text(myKeys?.publicKeyHr ?? ""),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                  ],
                ),
              ),
              Container(
                child: TextField(
                  onSubmitted: (value) {
                    _addWords(value);
                    _inputFocusNode.requestFocus();
                  },
                  focusNode: _inputFocusNode,
                  autofillHints: Language.english.list,
                  controller: _inputController,
                  enableIMEPersonalizedLearning: false,
                  textCapitalization: TextCapitalization.none,
                  decoration: const InputDecoration(
                    isDense: true,
                    hintText: 'enter your seed phrase or nsec1',
                    hintStyle:
                        TextStyle(color: Palette.white, letterSpacing: 1.1),
                    filled: true,
                    fillColor: Palette.extraDarkGray,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                      borderSide: BorderSide(color: Palette.extraDarkGray),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                      borderSide: BorderSide(color: Palette.gray),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                      borderSide: BorderSide(color: Palette.purple),
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

  Widget seedPhraseCheck() {
    return Center(
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
              return LongPressDraggable<int>(
                data: index,
                feedback: Material(
                  color: Colors.transparent,
                  child: Center(
                    child: Container(
                      width: 100,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Palette.extraDarkGray,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Palette.darkGray,
                          width: 1,
                        ),
                      ),
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
                    ),
                  ),
                ),
                child: DragTarget<int>(
                  builder: (BuildContext context, List<int?> candidateData,
                      List<dynamic> rejectedData) {
                    return Center(
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
                    );
                  },
                  onWillAccept: (data) => data != index,
                  onAccept: (data) {
                    setState(() {
                      String temp = _userWords[data];
                      _userWords[data] = _userWords[index];
                      _userWords[index] = temp;
                    });
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
