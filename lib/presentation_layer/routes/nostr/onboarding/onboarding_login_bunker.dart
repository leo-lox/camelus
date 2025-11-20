import 'package:camelus/domain_layer/usecases/app_auth.dart';
import 'package:camelus/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../domain_layer/entities/stored_account.dart';
import '../../../atoms/long_button.dart';
import '../../../components/responsive_center.dart';
import '../../../providers/ndk_provider.dart';
import '../../../providers/signer_provider.dart';

class OnboardingLoginBunkerPage extends ConsumerStatefulWidget {
  final Function? onPressedBack;

  const OnboardingLoginBunkerPage({super.key, this.onPressedBack});
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
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

  String? _bunkerUrl;

  void _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data == null || data.text == null) {
      _showError(AppLocalizations.of(context)!.noTextFoundInClipboard);
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
      _showError(AppLocalizations.of(context)!.invalidBunkerUrl);
      setState(() {
        _bunkerUrl = null;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _onBunkerLogin() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_termsAndConditions) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.pleaseReadAndAcceptTerms,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 12,
              fontWeight: FontWeight.normal,
            ),
          ),
        ),
      );
      return;
    }

    if (_bunkerUrl == null || _bunkerUrl!.isEmpty) {
      _showError(l10n.pleaseEnterValidBunkerUrl);
      return;
    }

    setState(() {
      _bunkerLoading = true;
    });

    try {
      final ndk = ref.read(ndkProvider);

      final connection = await ndk.accounts.loginWithBunkerUrl(
        bunkerUrl: _bunkerUrl!,
        bunkers: ndk.bunkers,
      );

      if (connection == null) {
        _showError(AppLocalizations.of(context)!.failedToConnectToBunker);
        setState(() {
          _bunkerLoading = false;
        });
        return;
      }

      // create stored account
      final storedAccount = LocalStorageAccount(
        loginType: LoginType.bunkerConnection,
        pubkey: connection.remotePubkey,
        bunkerConnection: connection,
      );

      await AppAuth.addStoredAccount(account: storedAccount, setActive: true);
      final startupData = await AppAuth.getStartupAccountData();
      await AppAuth.loginWithStoredAccount(
        startupAccountData: startupData,
        signerNoti: ref.read(signerProvider.notifier),
        ndk: ndk,
      );

      setState(() {
        _bunkerLoading = false;
      });

      if (!mounted) return;

      // Navigate to home page
      context.go('/home');
    } catch (e) {
      _showError(
        AppLocalizations.of(context)!.failedToConnectWithError(e.toString()),
      );
      setState(() {
        _bunkerLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null,
      backgroundColor: Theme.of(context).colorScheme.surface,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: ResponsiveCenter(
          maxWidth: 700,
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
              if (widget.onPressedBack == null) const SizedBox(height: 20),
              SizedBox(
                height: 200,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "login",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 40,
                        fontFamily: "Poppins",
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 1),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
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
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: AppLocalizations.of(context)!.bunkerUrlHint,
                    hintStyle: TextStyle(letterSpacing: 1.1),
                    filled: true,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
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
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: Theme.of(context).colorScheme.onSurface,
                              width: 1,
                            ),
                          ),
                        ),
                        child: Text(
                          'paste',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
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
                  ),
                  Text(
                    AppLocalizations.of(context)!.iHaveReadAndAcceptThe,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Uri url = Uri.parse("https://camelus.app/terms/");
                      launchUrl(url, mode: LaunchMode.externalApplication);
                    },
                    child: Text(
                      "terms and conditions",
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
                  "privacy policy",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),

                child: longButton(
                  name: AppLocalizations.of(context)!.connect,
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
