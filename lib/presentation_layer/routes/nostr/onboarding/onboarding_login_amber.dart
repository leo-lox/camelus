import 'package:amberflutter/amberflutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../../../config/amber_url.dart';
import '../../../../config/palette.dart';
import '../../../../domain_layer/usecases/app_auth.dart';
import '../../../atoms/long_button.dart';
import '../../../providers/event_signer_provider.dart';
import '../../home_page.dart';

class OnboardingLoginAmberPage extends ConsumerStatefulWidget {
  const OnboardingLoginAmberPage({super.key});
  @override
  ConsumerState<OnboardingLoginAmberPage> createState() =>
      _OnboardingLoginAmberPageState();
}

class _OnboardingLoginAmberPageState
    extends ConsumerState<OnboardingLoginAmberPage> {
  final amber = Amberflutter();
  bool _amberInstalled = false;

  bool _termsAndConditions = false;

  bool _amberLoading = false;

  void _checkAmberInstalled() async {
    final installed = await amber.isAppInstalled();
    setState(() {
      _amberInstalled = installed;
    });
  }

  void _promtAmberInstall() {
    launchUrlString(AMBER_INSTANCE_URL, mode: LaunchMode.externalApplication);
  }

  @override
  void initState() {
    super.initState();
    _checkAmberInstalled();
  }

  void _onAmberLogin() async {
    if (!_termsAndConditions) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please read and accept the terms and conditions first',
              style: TextStyle(color: Palette.black)),
        ),
      );
      return;
    }
    setState(() {
      _amberLoading = true;
    });

    final amberSigner = await AppAuth.amberRegister();

    ref.read(eventSignerProvider.notifier).setSigner(amberSigner);

    setState(() {});

    if (!mounted) return;

    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) {
      return HomePage(pubkey: amberSigner.publicKey);
    }));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null,
      backgroundColor: Palette.background,
      resizeToAvoidBottomInset: false,
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
              const Spacer(
                flex: 1,
              ),
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
              if (!_amberInstalled)
                SizedBox(
                  width: MediaQuery.of(context).size.width,
                  height: 40,
                  child: longButton(
                    name: "install amber",
                    inverted: true,
                    onPressed: () => _promtAmberInstall(),
                  ),
                ),
              if (_amberInstalled)
                SizedBox(
                  width: MediaQuery.of(context).size.width,
                  height: 40,
                  child: longButton(
                    name: "authorise amber",
                    inverted: true,
                    loading: _amberLoading,
                    onPressed: () => _onAmberLogin(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
