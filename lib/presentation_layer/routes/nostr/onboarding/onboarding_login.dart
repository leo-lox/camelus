import 'dart:convert';

import 'package:bip32/bip32.dart' as bip32;
import 'package:camelus/l10n/app_localizations.dart';
import 'package:camelus/presentation_layer/atoms/long_button.dart';
import 'package:camelus/config/palette.dart';
import 'package:camelus/helpers/bip340.dart';
import 'package:camelus/helpers/helpers.dart';
import 'package:camelus/presentation_layer/routes/home_page.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hex/hex.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ndk/ndk.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:bip39_mnemonic/bip39_mnemonic.dart';

import '../../../../domain_layer/entities/key_pair.dart';

import '../../../providers/ndk_provider.dart';
import '../../../providers/signer_provider.dart';

class OnboardingLoginPage extends ConsumerStatefulWidget {
  final Function? onPressedBack;

  const OnboardingLoginPage({
    super.key,
    this.onPressedBack,
  });
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
      SnackBar(
        content:
            Text(AppLocalizations.of(context)!.invalidPrivateKeyOrSeedPhrase),
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
        myKeys = KeyPair(
          privateKey: privkey,
          publicKey: pubkey,
          privateKeyHr: privKeyHr,
          publicKeyHr: publicKeyHr,
        );
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
        myKeys = KeyPair(
          privateKey: privkeyHex,
          publicKey: pubkey,
          privateKeyHr: privKeyHr,
          publicKeyHr: publicKeyHr,
        );
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
        SnackBar(
          content: Text(AppLocalizations.of(context)!.pleaseReadAndAcceptTerms),
        ),
      );
      return;
    }

    if (_userWords.isNotEmpty) {
      _getPrivkeyFromSeed(_userWords.join(" "));
    }

    if (myKeys == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(AppLocalizations.of(context)!.pleaseImportPrivateKeyFirst),
        ),
      );
      return;
    }

    // store in secure storage
    const storage = FlutterSecureStorage();
    await storage.write(key: "nostrKeys", value: json.encode(myKeys!.toJson()));
    // save in provider

    final bip340Signer = Bip340EventSigner(
      privateKey: myKeys!.privateKey,
      publicKey: myKeys!.publicKey,
    );

    ref.watch(ndkProvider).accounts.loginExternalSigner(signer: bip340Signer);
    ref.read(signerProvider.notifier).setSigner(bip340Signer);

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
        SnackBar(
          duration: Duration(seconds: 20),
          showCloseIcon: true,
          content: Text(AppLocalizations.of(context)!.publicKeyErrorMessage),
        ),
      );
      return;
    }

    if (_checkWord(word)) {
      _userWords.add(word);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.wordNotValid(word)),
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
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        // input for the user to enter their private key, should be visible on a dark background.
        child: LayoutBuilder(builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.all(30),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (widget.onPressedBack != null)
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                PhosphorIcons.arrowLeft(),
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              onPressed: () => widget.onPressedBack!(),
                            ),
                          ],
                        ),
                      if (widget.onPressedBack == null)
                        const SizedBox(height: 20),

                      if (_userWords.isNotEmpty)
                        Column(
                          children: [
                            Container(
                              width: MediaQuery.of(context).size.width,
                              height: 200,
                              decoration: BoxDecoration(
                                color: Paletter.getExtraDarkGray(context),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Paletter.getDarkGray(context),
                                  width: 1,
                                ),
                              ),
                              child: seedPhraseCheck(),
                            ),
                            const SizedBox(height: 5),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(mneonicError ?? "",
                                      style: TextStyle(
                                        color:
                                            Theme.of(context).colorScheme.error,
                                        fontSize: 12,
                                      )),
                                  Text(
                                    "${_userWords.length}/${(_userWords.length <= 12 ? "12" : "24")}",
                                    style: TextStyle(
                                      color: (_userWords.length > 24)
                                          ? Theme.of(context).colorScheme.error
                                          : Theme.of(context)
                                              .colorScheme
                                              .onSurface,
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                AppLocalizations.of(context)!.login,
                                style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                  fontSize: 40,
                                  fontFamily: "Poppins",
                                ),
                              ),
                            ],
                          ),
                        ),

                      AnimatedOpacity(
                        opacity: (_userNsec != null && myKeys != null) ? 1 : 0,
                        duration: const Duration(milliseconds: 300),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(AppLocalizations.of(context)!.yourPublicKeyIs),
                            const SizedBox(height: 10),
                            Container(
                              decoration: BoxDecoration(
                                color: Paletter.getExtraDarkGray(context),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Paletter.getDarkGray(context),
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
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        width: 400,
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
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: AppLocalizations.of(context)!
                                .enterSeedPhraseOrNsec,
                            hintStyle: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                letterSpacing: 1.1),
                            filled: true,
                            fillColor: Paletter.getExtraDarkGray(context),
                            enabledBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10)),
                              borderSide: BorderSide(
                                  color: Paletter.getExtraDarkGray(context)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10)),
                              borderSide:
                                  BorderSide(color: Paletter.getGray(context)),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10)),
                              borderSide: BorderSide(color: Colors.purple),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 15),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        width: 400,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            SizedBox(
                              height: 31,
                              child: ElevatedButton(
                                onPressed: () {
                                  _pasteFromClipboard();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Theme.of(context).colorScheme.surface,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    side: BorderSide(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                        width: 1),
                                  ),
                                ),
                                child: Text(
                                  AppLocalizations.of(context)!.paste,
                                  style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
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
                                  backgroundColor:
                                      Theme.of(context).colorScheme.onSurface,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    side: BorderSide(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                        width: 1),
                                  ),
                                ),
                                child: Text(
                                  AppLocalizations.of(context)!.add,
                                  style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.surface,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
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
                          ),
                          Text(
                            AppLocalizations.of(context)!.iHaveReadAndAccept,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 12,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Uri url = Uri.parse("https://camelus.app/terms/");
                              launchUrl(url,
                                  mode: LaunchMode.externalApplication);
                            },
                            child: Text(
                              AppLocalizations.of(context)!.termsAndConditions,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
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
                        child: Text(
                          AppLocalizations.of(context)!.privacyPolicy,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        width: 400,
                        height: 40,
                        child: longButton(
                          name: AppLocalizations.of(context)!.login,
                          inverted: true,
                          onPressed: () => _onSubmit(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
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
                        color: Paletter.getExtraDarkGray(context),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Paletter.getDarkGray(context),
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
                              style: TextStyle(
                                color: Paletter.getGray(context),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              _userWords[index],
                              style: TextStyle(
                                color: Paletter.getExtraLightGray(context),
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
                            style: TextStyle(
                              color: Paletter.getGray(context),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            _userWords[index],
                            style: TextStyle(
                              color: Paletter.getExtraLightGray(context),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  onWillAcceptWithDetails: (data) => data.data != index,
                  onAcceptWithDetails: (data) {
                    setState(() {
                      String temp = _userWords[data.data];
                      _userWords[data.data] = _userWords[index];
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
