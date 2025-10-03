import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../config/palette.dart';
import '../../../atoms/long_button.dart';

class OnboardingLoginBunkerPage extends ConsumerStatefulWidget {
  final Function? onPressedBack;
  
  const OnboardingLoginBunkerPage({
    super.key,
    this.onPressedBack,
  });
  @override
  ConsumerState<OnboardingLoginBunkerPage> createState() =>
      _OnboardingLoginBunkerPageState();
}

class _OnboardingLoginBunkerPageState
    extends ConsumerState<OnboardingLoginBunkerPage> {
  bool _termsAndConditions = false;
  bool _bunkerLoading = false;

  final TextEditingController _bunkerUrlController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();

  String? _bunkerUrl;

  void _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data == null || data.text == null) {
      _showError('No text found in clipboard');
      return;
    }
    _bunkerUrlController.text = data.text!;
    _validateBunkerUrl(data.text!);
  }

  void _validateBunkerUrl(String url) {
    url = url.trim();
    if (url.startsWith('bunker://')) {
      setState(() {
        _bunkerUrl = url;
      });
    } else {
      _showError('Invalid bunker URL. Must start with bunker://');
      setState(() {
        _bunkerUrl = null;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  void _onBunkerLogin() async {
    if (!_termsAndConditions) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please read and accept the terms and conditions first',
              style: TextStyle(color: Palette.black)),
        ),
      );
      return;
    }

    if (_bunkerUrl == null || _bunkerUrl!.isEmpty) {
      _showError('Please enter a valid bunker URL');
      return;
    }

    setState(() {
      _bunkerLoading = true;
    });

    // TODO: Implement bunker connection logic
    // This would involve:
    // 1. Parsing the bunker:// URL
    // 2. Creating a NIP-46 remote signer
    // 3. Establishing connection with the bunker
    // 4. Authenticating and storing the connection

    setState(() {
      _bunkerLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null,
      backgroundColor: Palette.background,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
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
                        color: Palette.white,
                      ),
                      onPressed: () => widget.onPressedBack!(),
                    ),
                  ],
                ),
              if (widget.onPressedBack == null) const SizedBox(height: 20),
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
              const Spacer(flex: 1),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                width: 400,
                child: TextField(
                  onSubmitted: (value) {
                    _validateBunkerUrl(value);
                  },
                  onChanged: (value) {
                    _validateBunkerUrl(value);
                  },
                  focusNode: _inputFocusNode,
                  controller: _bunkerUrlController,
                  enableIMEPersonalizedLearning: false,
                  textCapitalization: TextCapitalization.none,
                  decoration: const InputDecoration(
                    isDense: true,
                    hintText: 'bunker://',
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
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 50),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                width: 400,
                height: 40,
                child: longButton(
                  name: "connect",
                  inverted: true,
                  loading: _bunkerLoading,
                  onPressed: () => _onBunkerLogin(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
