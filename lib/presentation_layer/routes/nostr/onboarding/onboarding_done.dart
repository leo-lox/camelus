import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../config/palette.dart';
import '../../../../domain_layer/entities/generated_private_key.dart';
import '../../../../domain_layer/entities/onboarding_user_info.dart';
import '../../../../domain_layer/entities/user_metadata.dart';
import '../../../../domain_layer/usecases/generate_private_key.dart';
import '../../../../helpers/bip340.dart';
import '../../../atoms/long_button.dart';
import '../../../atoms/mnemonic_grid.dart';
import '../../../providers/file_upload_provider.dart';
import '../../../providers/following_provider.dart';
import '../../../providers/key_pair_provider.dart';
import '../../../providers/metadata_provider.dart';
import '../../home_page.dart';

class OnboardingDone extends ConsumerStatefulWidget {
  final Function() submitCallback;

  final OnboardingUserInfo userInfo;

  const OnboardingDone({
    super.key,
    required this.submitCallback,
    required this.userInfo,
  });
  @override
  ConsumerState<OnboardingDone> createState() => _OnboardingDoneState();
}

class _OnboardingDoneState extends ConsumerState<OnboardingDone> {
  bool _termsAndConditions = false;
  bool _isVisible = false;

  void _toggleVisibility() {
    setState(() {
      _isVisible = !_isVisible;
    });
  }

  late GeneratedPrivateKey _privateKey;

  void _generateKey() {
    setState(() {
      _privateKey = GeneratePrivateKey.generateKey();
    });
  }

  void _copyKey() {
    final clipData = """
Public Key:
${_privateKey.publicKeyHr}


Private Key:
${_privateKey.privKeyHr}


SeedPhrase:
${_privateKey.mnemonicSentence}
    """;

    Clipboard.setData(ClipboardData(text: clipData));
  }

  Future<void> _broadcastAcc() async {
    String? uploadedPicture;
    String? uploadedBanner;
    final fileUploadP = ref.watch(fileUploadProvider);

    if (widget.userInfo.picture != null) {
      uploadedPicture = await fileUploadP.uploadImage(widget.userInfo.picture!);
    }
    if (widget.userInfo.banner != null) {
      uploadedBanner = await fileUploadP.uploadImage(widget.userInfo.banner!);
    }

    //! todo: broadcast data to nostr network
    final metadataP = ref.watch(metadataProvider);
    final followP = ref.watch(followingProvider);

    final UserMetadata userMetadata = UserMetadata(
      eventId: '',
      lastFetch: 0,
      pubkey: _privateKey.publicKey,
      name: widget.userInfo.name,
      picture: uploadedPicture,
      banner: uploadedBanner,
      about: widget.userInfo.about,
      website: widget.userInfo.website,
      nip05: widget.userInfo.nip05,
      lud06: widget.userInfo.lud06,
      lud16: widget.userInfo.lud16,
    );

    metadataP.broadcastMetadata(userMetadata);
    followP.setContacts(widget.userInfo.followPubkeys);
  }

  @override
  void initState() {
    super.initState();
    _generateKey();
  }

  @override
  void dispose() {
    super.dispose();
  }

  _onSubmit() async {
    if (!_termsAndConditions) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please read and accept the terms and conditions first',
              style: TextStyle(color: Palette.black)),
        ),
      );
      return;
    }

    final myKeyPair = KeyPair(
      privateKey: _privateKey.privateKey,
      publicKey: _privateKey.publicKey,
      privateKeyHr: _privateKey.privKeyHr,
      publicKeyHr: _privateKey.publicKeyHr,
    );

    final keyPairP = ref.watch(keyPairProvider);
    keyPairP.setKeyPair(myKeyPair);

    // save in storage
    const storage = FlutterSecureStorage();
    storage.write(key: "nostrKeys", value: json.encode(myKeyPair.toJson()));

    await _broadcastAcc();

    if (!mounted) return;

    // naviage to /
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) {
      return HomePage(pubkey: myKeyPair.publicKey);
    }));
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palette.background,
      body: Column(
        children: [
          const SizedBox(height: 20),
          const Text(
            "recovery phrase",
            style: TextStyle(
              color: Palette.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 25),
          MnemonicSentenceGrid(
            words: _privateKey.mnemonicWords,
            isVisible: _isVisible,
          ),
          const SizedBox(height: 25),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Palette.black,
                    foregroundColor: Palette.white,
                  ),
                  onPressed: () => {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        duration: Duration(seconds: 2),
                        content: Text('a new seed phrase has been generated',
                            style: TextStyle(color: Palette.black)),
                      ),
                    ),
                    _generateKey()
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('regenerate'),
                ),
                const SizedBox(width: 5),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Palette.lightGray,
                    foregroundColor: Palette.black,
                  ),
                  onPressed: () => {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        duration: Duration(seconds: 2),
                        content: Text('copied seed phrase to clipboard',
                            style: TextStyle(color: Palette.black)),
                      ),
                    ),
                    _copyKey()
                  },
                  icon: const Icon(Icons.copy),
                  label: const Text('copy'),
                ),
                const SizedBox(width: 5),
                IconButton(
                  onPressed: _toggleVisibility,
                  icon: Icon(
                      _isVisible ? Icons.visibility : Icons.visibility_off),
                  tooltip: _isVisible ? 'Hide words' : 'Show words',
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
                "You need the recovery phrase to login again. Make sure to keep it safe!"),
          ),
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
                fillColor: WidgetStateProperty.all(Palette.white),
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
          const SizedBox(height: 50),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            width: 400,
            height: 40,
            child: longButton(
              name: "publish account",
              inverted: true,
              onPressed: () => _onSubmit(),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
