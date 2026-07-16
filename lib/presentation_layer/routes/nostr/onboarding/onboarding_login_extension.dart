import 'package:camelus/l10n/app_localizations.dart';
import 'package:camelus/presentation_layer/components/responsive_center.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nip07_event_signer/nip07_event_signer.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../domain_layer/entities/stored_account.dart';
import '../../../../domain_layer/usecases/app_auth.dart';
import '../../../atoms/long_button.dart';
import '../../../providers/messaging/dm_conversations_provider.dart';
import '../../../providers/ndk_provider.dart';
import '../../../providers/signer_provider.dart';

class _Nip07Extension {
  final String name;
  final String description;
  final String browser;
  final String url;

  const _Nip07Extension({
    required this.name,
    required this.description,
    required this.browser,
    required this.url,
  });
}

const _kExtensions = [
  _Nip07Extension(
    name: 'nos2x',
    description: 'Lightweight key signer for Chrome & Brave',
    browser: 'Chrome / Brave',
    url:
        'https://chromewebstore.google.com/detail/nos2x/kpgefcfmnafjgpblomihpgmejjdanjjp',
  ),
  _Nip07Extension(
    name: 'Alby',
    description: 'Bitcoin Lightning & Nostr browser extension',
    browser: 'Chrome / Firefox',
    url: 'https://getalby.com/alby-extension',
  ),
  _Nip07Extension(
    name: 'nos2x-fox',
    description: 'nos2x port for Firefox',
    browser: 'Firefox',
    url: 'https://addons.mozilla.org/en-US/firefox/addon/nos2x-fox/',
  ),
];

class OnboardingLoginExtensionPage extends ConsumerStatefulWidget {
  final Function? onPressedBack;

  const OnboardingLoginExtensionPage({super.key, this.onPressedBack});

  @override
  ConsumerState<OnboardingLoginExtensionPage> createState() =>
      _OnboardingLoginExtensionPageState();
}

class _OnboardingLoginExtensionPageState
    extends ConsumerState<OnboardingLoginExtensionPage> {
  bool _termsAndConditions = false;
  bool _loading = false;

  void _onExtensionLogin() async {
    if (!_termsAndConditions) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.pleaseReadAndAcceptTerms),
        ),
      );
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final webSigner = Nip07EventSigner();
      await webSigner.getPublicKeyAsync();

      final pubkey = webSigner.cachedPublicKey;
      if (pubkey == null || pubkey.isEmpty) {
        throw Exception('Could not retrieve public key from extension');
      }

      final storedAccount = LocalStorageAccount(
        loginType: LoginType.webExtension,
        pubkey: pubkey,
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
    } catch (e) {
      setState(() {
        _loading = false;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Extension login failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: null,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: ResponsiveCenter(
          maxWidth: 600,
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Back button
              if (widget.onPressedBack != null)
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        PhosphorIcons.arrowLeft,
                        color: colorScheme.onSurface,
                      ),
                      onPressed: () => widget.onPressedBack!(),
                    ),
                  ],
                ),
              if (widget.onPressedBack == null) const SizedBox(height: 20),

              // Title
              Text(
                AppLocalizations.of(context)!.login,
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 40,
                  fontFamily: "Poppins",
                ),
              ),
              const SizedBox(height: 16),

              // Explainer
              Text(
                'A NIP-07 browser extension stores your Nostr private key securely and signs events on your behalf — your key never leaves your browser.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 20),

              // Extension cards label
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Popular extensions',
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Horizontally scrollable extension cards
              SizedBox(
                height: 130,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _kExtensions.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final ext = _kExtensions[index];
                    return _ExtensionCard(ext: ext);
                  },
                ),
              ),

              const Spacer(),

              // Terms checkbox
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
                      color: colorScheme.onSurface,
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      final url = Uri.parse("https://camelus.app/terms/");
                      launchUrl(url, mode: LaunchMode.externalApplication);
                    },
                    child: Text(
                      AppLocalizations.of(context)!.termsAndConditions,
                      style: TextStyle(
                        color: colorScheme.onSurface,
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
                  final url = Uri.parse("https://camelus.app/privacy/");
                  launchUrl(url, mode: LaunchMode.externalApplication);
                },
                child: Text(
                  AppLocalizations.of(context)!.privacyPolicy,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Login button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity,
                  child: longButton(
                    name: AppLocalizations.of(context)!.extensionLogin,
                    inverted: true,
                    loading: _loading,
                    onPressed: () => _onExtensionLogin(),
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

class _ExtensionCard extends StatelessWidget {
  final _Nip07Extension ext;

  const _ExtensionCard({required this.ext});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () =>
          launchUrl(Uri.parse(ext.url), mode: LaunchMode.externalApplication),
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(color: colorScheme.outline.withValues(alpha: 0.4)),
          borderRadius: BorderRadius.circular(12),
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  PhosphorIcons.puzzlePiece,
                  size: 18,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    ext.name,
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              ext.description,
              style: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
                fontSize: 11,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Row(
              children: [
                Icon(
                  PhosphorIcons.arrowSquareOut,
                  size: 11,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  ext.browser,
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
