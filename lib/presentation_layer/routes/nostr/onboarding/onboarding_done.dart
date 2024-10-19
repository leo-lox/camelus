import 'package:camelus/presentation_layer/atoms/mnemonic_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../config/palette.dart';
import '../../../../domain_layer/entities/generated_private_key.dart';
import '../../../../domain_layer/entities/onboarding_user_info.dart';
import '../../../../domain_layer/usecases/generate_private_key.dart';
import '../../../atoms/long_button.dart';

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
    Clipboard.setData(ClipboardData(text: _privateKey.mnemonicSentence));
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
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palette.background,
      body: Column(
        children: [
          const SizedBox(height: 10),
          const Text(
            "Recovery Keys",
            style: TextStyle(
              color: Palette.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          MnemonicSentenceGrid(
            words: _privateKey.mnemonicWords,
            isVisible: _isVisible,
          ),
          const SizedBox(height: 10),
          Container(
            child: Text(_privateKey.publicKeyHr),
          ),
          const SizedBox(height: 15),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Palette.lightGray,
                    foregroundColor: Palette.black,
                  ),
                  onPressed: () => _copyKey(),
                  icon: const Icon(Icons.copy),
                  label: const Text('copy'),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Palette.black,
                    foregroundColor: Palette.white,
                  ),
                  onPressed: () => _generateKey(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('regenerate'),
                ),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: _toggleVisibility,
                  icon: Icon(
                      _isVisible ? Icons.visibility : Icons.visibility_off),
                  tooltip: _isVisible ? 'Hide words' : 'Show words',
                ),
              ],
            ),
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
              name: "create account",
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
