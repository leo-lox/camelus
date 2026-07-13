import 'package:camelus/l10n/app_localizations.dart';
import 'package:camelus/presentation_layer/components/responsive_center.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ndk_flutter/ndk_flutter.dart';

import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../../../config/amber_url.dart';
import '../../../../domain_layer/entities/stored_account.dart';
import '../../../../domain_layer/usecases/app_auth.dart';
import '../../../atoms/long_button.dart';
import '../../../providers/messaging/dm_conversations_provider.dart';
import '../../../providers/ndk_provider.dart';
import '../../../providers/signer_provider.dart';

class OnboardingLoginAmberPage extends ConsumerStatefulWidget {
  final Function? onPressedBack;

  const OnboardingLoginAmberPage({super.key, this.onPressedBack});
  @override
  ConsumerState<OnboardingLoginAmberPage> createState() =>
      _OnboardingLoginAmberPageState();
}

class _OnboardingLoginAmberPageState
    extends ConsumerState<OnboardingLoginAmberPage> {
  final amber = Nip55Signer();
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
        SnackBar(
          content: Text(AppLocalizations.of(context)!.pleaseReadAndAcceptTerms),
        ),
      );
      return;
    }
    setState(() {
      _amberLoading = true;
    });

    final amberSigner = await AppAuth.amberRegister();

    // create stored account
    final storedAccount = LocalStorageAccount(
      loginType: LoginType.amber,
      pubkey: amberSigner.publicKey,
    );

    await AppAuth.addStoredAccount(account: storedAccount, setActive: true);
    final startupData = await AppAuth.getStartupAccountData();
    await AppAuth.loginWithStoredAccount(
      startupAccountData: startupData,
      signerNoti: ref.read(signerProvider.notifier),
      ndk: ref.read(ndkProvider),
    );

    // Start DM subscription
    ref.read(dmConversationsProvider);

    setState(() {});

    if (!mounted) return;

    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: ResponsiveCenter(
          maxWidth: 600,
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
                      AppLocalizations.of(context)!.login,
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
              if (!_amberInstalled)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),

                  child: longButton(
                    name: AppLocalizations.of(context)!.installAmber,
                    inverted: true,
                    onPressed: () => _promtAmberInstall(),
                  ),
                ),
              if (_amberInstalled)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),

                  child: SizedBox(
                    width: double.infinity,
                    child: longButton(
                      name: AppLocalizations.of(context)!.authoriseAmber,
                      inverted: true,
                      loading: _amberLoading,
                      onPressed: () => _onAmberLogin(),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
