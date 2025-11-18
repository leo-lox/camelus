import 'dart:convert';
import 'dart:math';

import 'package:camelus/l10n/app_localizations.dart';
import 'package:camelus/presentation_layer/components/full_screen_loading.dart';
import 'package:camelus/presentation_layer/components/responsive_center.dart';
import 'package:camelus/presentation_layer/providers/ndk_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ndk/ndk.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../config/default_blossom.dart';
import '../../../../config/default_relays.dart';
import '../../../../domain_layer/entities/generated_private_key.dart';
import '../../../../domain_layer/entities/key_pair.dart';
import '../../../../domain_layer/entities/nip_65.dart';
import '../../../../domain_layer/entities/onboarding_user_info.dart';
import '../../../../domain_layer/entities/stored_account.dart';
import '../../../../domain_layer/entities/user_metadata.dart';
import '../../../../domain_layer/usecases/app_auth.dart';
import '../../../../domain_layer/usecases/generate_private_key.dart';
import '../../../atoms/long_button.dart';
import '../../../atoms/mnemonic_grid.dart';
import '../../../providers/file_upload_provider.dart';
import '../../../providers/following_contact_state_provider.dart';
import '../../../providers/inbox_outbox_provider.dart';
import '../../../providers/metadata_provider.dart';
import '../../../providers/signer_provider.dart';

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
  bool _isLoading = false;
  double _loadingOpacity = 0.0;

  late List<String> loadingTexts;

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
    final clipData =
        """
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

    final metadataP = ref.watch(metadataProvider);

    final myContactListNotifier = ref.watch(
      contactListStateProvider(_privateKey.publicKey).notifier,
    );

    final inboxOutboxP = ref.read(inboxOutboxProvider);
    final fileUploadP = ref.watch(fileUploadProvider);

    // set nip65 - inbox/outbox
    final Nip65 myNip65 = Nip65(
      pubKey: _privateKey.publicKey,
      createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      relays: defaultAccountCreationRelays,
    );

    /// broadcast nip65
    await inboxOutboxP.setNip65data(myNip65);

    /// broadcast blossom servers
    await fileUploadP.setFileUploadServers(defaultBlossomServers);

    if (widget.userInfo.picture != null) {
      setState(() {
        // add to start
        loadingTexts.insert(
          0,
          AppLocalizations.of(context)!.uploadingProfilePicture,
        );
      });

      try {
        uploadedPicture = (await fileUploadP.uploadImage(
          widget.userInfo.picture!,
        ))[0].descriptor!.url;
      } catch (_) {}
    }

    if (widget.userInfo.banner != null) {
      try {
        uploadedBanner = (await fileUploadP.uploadImage(
          widget.userInfo.banner!,
        ))[0].descriptor!.url;
      } catch (_) {}
    }

    final UserMetadata userMetadata = UserMetadata(
      eventId: '',
      lastFetch: 0,
      pubkey: _privateKey.publicKey,
      name: widget.userInfo.name,
      picture: uploadedPicture,
      banner: uploadedBanner,
      about: widget.userInfo.about,
      pronouns: widget.userInfo.pronouns,
      website: widget.userInfo.website,
      nip05: widget.userInfo.nip05,
      lud06: widget.userInfo.lud06,
      lud16: widget.userInfo.lud16,
    );

    await metadataP.broadcastMetadata(userMetadata);
    await myContactListNotifier.setContacts(widget.userInfo.followPubkeys);
  }

  @override
  void initState() {
    super.initState();
    _generateKey();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    loadingTexts = [
      AppLocalizations.of(context)!.settingUpYourAccount,
      AppLocalizations.of(context)!.followingPeople,
      AppLocalizations.of(context)!.movingData,
      AppLocalizations.of(context)!.cleaningUp,
    ];
  }

  @override
  void dispose() {
    super.dispose();
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
    setState(() {
      _isLoading = true;
      _loadingOpacity = 1.0;
    });

    final myKeyPair = KeyPair(
      privateKey: _privateKey.privateKey,
      publicKey: _privateKey.publicKey,
      privateKeyHr: _privateKey.privKeyHr,
      publicKeyHr: _privateKey.publicKeyHr,
    );

    // create stored account
    final storedAccount = LocalStorageAccount(
      loginType: LoginType.privateKey,
      pubkey: myKeyPair.publicKey,
      keyPair: myKeyPair,
    );

    await AppAuth.addStoredAccount(account: storedAccount, setActive: true);
    final startupData = await AppAuth.getStartupAccountData();
    await AppAuth.loginWithStoredAccount(
      startupAccountData: startupData,
      signerNoti: ref.read(signerProvider.notifier),
      ndk: ref.read(ndkProvider),
    );

    await _broadcastAcc();

    if (!mounted) return;

    // naviage to home
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ResponsiveCenter(
        maxWidth: 700,
        child: Stack(
          children: [
            AnimatedOpacity(
              duration: const Duration(seconds: 3),
              opacity: max(1 - _loadingOpacity, 0.07),
              curve: Curves.easeOut,
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                        const SizedBox(height: 20),
                        Text(
                          AppLocalizations.of(context)!.recoveryPhrase,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
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
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.surface,
                                  foregroundColor: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                                onPressed: () => {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      duration: Duration(seconds: 2),
                                      content: Text(
                                        AppLocalizations.of(
                                          context,
                                        )!.newSeedPhraseGenerated,
                                      ),
                                    ),
                                  ),
                                  _generateKey(),
                                },
                                icon: const Icon(Icons.refresh),
                                label: Text(
                                  AppLocalizations.of(context)!.regenerate,
                                ),
                              ),
                              const SizedBox(width: 5),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.inverseSurface,
                                  foregroundColor: Theme.of(
                                    context,
                                  ).colorScheme.surface,
                                ),
                                onPressed: () => {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      duration: Duration(seconds: 2),
                                      content: Text(
                                        AppLocalizations.of(
                                          context,
                                        )!.copiedSeedPhraseToClipboard,
                                      ),
                                    ),
                                  ),
                                  _copyKey(),
                                },
                                icon: const Icon(Icons.copy),
                                label: Text(AppLocalizations.of(context)!.copy),
                              ),
                              const SizedBox(width: 5),
                              IconButton(
                                onPressed: _toggleVisibility,
                                icon: Icon(
                                  _isVisible
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                                tooltip: _isVisible
                                    ? AppLocalizations.of(context)!.hideWords
                                    : AppLocalizations.of(context)!.showWords,
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            AppLocalizations.of(context)!.recoveryPhraseWarning,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Fixed bottom section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
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
                              launchUrl(
                                url,
                                mode: LaunchMode.externalApplication,
                              );
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
                      const SizedBox(height: 50),
                      SizedBox(
                        width: double.infinity,
                        height: 40,
                        child: longButton(
                          name: AppLocalizations.of(context)!.publishAccount,
                          inverted: true,
                          onPressed: () => _onSubmit(),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            AnimatedOpacity(
              opacity: _loadingOpacity,
              curve: Curves.easeInOut,
              duration: const Duration(seconds: 2),
              child: _isLoading
                  ? Center(
                      child: FullScreenLoading(
                        loadingTexts: loadingTexts,
                        updateState: (function) => {},
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
        ],
      ),
    );
  }
}
