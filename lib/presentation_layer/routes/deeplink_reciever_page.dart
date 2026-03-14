import 'dart:developer';

import 'package:camelus/l10n/app_localizations.dart';
import 'package:camelus/presentation_layer/providers/ndk_provider.dart';
import 'package:camelus/presentation_layer/providers/signer_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ndk/shared/nips/nip19/nip19.dart';

import '../../domain_layer/entities/invite_data.dart';
import '../../domain_layer/entities/starter_pack_identifier.dart';
import '../../domain_layer/usecases/app_auth.dart';
import '../../helpers/helpers.dart';
import '../routing/route_paths.dart';
import '../atoms/long_button.dart';
import '../atoms/spinner_center.dart';
import '../providers/nip05_provider.dart';
import '../providers/onboarding_provider.dart';
import '../providers/serverpod_provider.dart';

class DeeplinkRecieverPage extends ConsumerStatefulWidget {
  final String userParam;

  const DeeplinkRecieverPage({super.key, required this.userParam});

  @override
  ConsumerState<DeeplinkRecieverPage> createState() =>
      _DeeplinkRecieverPageState();
}

class _DeeplinkRecieverPageState extends ConsumerState<DeeplinkRecieverPage> {
  bool loading = true;
  String userErrorMsg = "";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      /// check if the param has no /

      if (widget.userParam.contains("-_-")) {
        /// handle camelus link with path segments joined by -_-
        final segments = widget.userParam.split("-_-");
        final reconstructedPath = segments.join("/");

        try {
          _camelusLinks(path: "/$reconstructedPath", ref: ref);
        } catch (e) {
          setState(() {
            userErrorMsg = "Error processing link: $e";
            loading = false;
          });
        }
      } else if (!widget.userParam.contains("/")) {
        /// check if its nostr code
        try {
          _nostrDecode(nostrCode: widget.userParam, providerContainer: ref);
        } catch (e) {
          setState(() {
            userErrorMsg = "Error processing link: $e";
            loading = false;
          });
        }
      }
    });
  }

  void _pushProfile({required String pubkey}) {
    context.go(RoutePaths.profile(pubkey: pubkey));
  }

  void _pushNote({required String noteId}) {
    context.go(
      RoutePaths.statusByIdentifier(
        profileIdentifier: 'unknown',
        eventId: noteId,
      ),
    );
  }

  void _navigateToStarterPack(String listName, String pubkey) {
    context.go(
      '/open-starter-pack',
      extra: StarterPackIdentifier(name: listName, pubkey: pubkey),
    );
  }

  Future<void> _nostrDecode({
    required String nostrCode,
    required WidgetRef providerContainer,
  }) async {
    final myMatch = nostrCode;
    String myPubkeyHex = "";

    if (myMatch.contains("nprofile")) {
      //TODO: remove the "nostr:" part

      final nprofile = Nip19.decodeNprofile(myMatch);
      myPubkeyHex = nprofile.pubkey;

      _pushProfile(pubkey: myPubkeyHex);
    } else if (myMatch.contains("npub")) {
      final List decode = Helpers().decodeBech32(myMatch);

      myPubkeyHex = decode[0];

      _pushProfile(pubkey: myPubkeyHex);
    } else if (myMatch.contains("note1")) {
      final decode = Helpers().decodeBech32(myMatch);
      final String noteId = decode[1];
      if (noteId.isEmpty) {
        return;
      }
      _pushNote(noteId: noteId);
    } else if (myMatch.contains("nevent")) {
      final nevent = Nip19.decodeNevent(myMatch);

      if (nevent.kind == 1) {
        _pushNote(noteId: nevent.eventId);
      }
    } else if (myMatch.contains("@")) {
      final nip05P = providerContainer.read(nip05provider);
      final nip05Data = await nip05P.get(myMatch);
      if (nip05Data != null) {
        _pushProfile(pubkey: nip05Data.pubkey);
      }
    }
  }

  bool _isInviteLink(String path) {
    return path.startsWith("/i/") || path.startsWith("/ii/");
  }

  bool _isUserLink(String path) {
    return path.startsWith('/user/') || path.startsWith('/profile/');
  }

  Future<void> _camelusLinks({
    required String path,
    required WidgetRef ref,
  }) async {
    if (_isInviteLink(path)) {
      await _handleInviteLink(path, ref);
    } else if (_isUserLink(path)) {
      await _handleUserLink(path, ref);
    } else {
      if (kDebugMode) {
        print("Camelus link not supported: $path");
      }
    }
  }

  Future<void> _handleInviteLink(String path, WidgetRef ref) async {
    final pathSegments = path.split("/");
    if (pathSegments.length < 3) return;

    final firstParam = pathSegments[2];
    final InviteData inviteData;

    if (firstParam.startsWith("s")) {
      inviteData = await _getShortInviteData(firstParam, ref);
      if (inviteData.isEmpty) return;
    } else {
      inviteData = InviteData(
        inviteByNpub: firstParam,
        listName: pathSegments.length > 3 ? pathSegments[3] : "",
        listNpub: pathSegments.length >= 5 ? pathSegments[4] : null,
      );
    }

    final decodedInviteBy = _decodePubkey(inviteData.inviteByNpub);
    final decodedListPubkey = inviteData.listNpub != null
        ? _decodePubkey(inviteData.listNpub!)
        : null;

    final startupAcc = await AppAuth.getStartupAccountData();
    final mySigner = await AppAuth.loginWithStoredAccount(
      startupAccountData: startupAcc,
      signerNoti: ref.read(signerProvider.notifier),
      ndk: ref.read(ndkProvider),
    );

    if (mySigner != null) {
      _navigateToStarterPack(
        inviteData.listName,
        decodedListPubkey ?? decodedInviteBy,
      );
      return;
    }

    await _setupOnboarding(
      ref,
      decodedInviteBy,
      inviteData.listName,
      decodedListPubkey ?? decodedInviteBy,
    );
  }

  Future<InviteData> _getShortInviteData(
    String shortLink,
    WidgetRef ref,
  ) async {
    try {
      final serverpodProv = ref.read(serverpodProvider);
      final shortInviteData = await serverpodProv.client.linkShorter
          .getInviteByShortLink(shortLink: shortLink);

      if (shortInviteData == null) {
        return InviteData.empty();
      }

      return InviteData(
        inviteByNpub: shortInviteData.invitedByNpub,
        listName: shortInviteData.listName,
        listNpub: shortInviteData.listNpub,
      );
    } catch (e) {
      if (kDebugMode) {
        log("Error fetching short invite data: $e");
      }
      return InviteData.empty();
    }
  }

  String _decodePubkey(String npubOrNprofile) {
    if (npubOrNprofile.startsWith('nprofile')) {
      return Nip19.decodeNprofile(npubOrNprofile).pubkey;
    }
    return Nip19.decode(npubOrNprofile);
  }

  Future<void> _setupOnboarding(
    WidgetRef ref,
    String decodedInviteBy,
    String listName,
    String listPubkey,
  ) async {
    try {
      final provider = ref.read(onboardingProvider);
      provider.signUpInfo.invitedByPubkey = decodedInviteBy;
      provider.signUpInfo.listName = listName;
      provider.signUpInfo.listPubkey = listPubkey;

      context.go('/onboarding');
    } catch (e) {
      log("Error setting up onboarding: $e");
    }
  }

  Future<void> _handleUserLink(String path, WidgetRef ref) async {
    final pathSegments = path.split("/");
    if (pathSegments.length < 3) return;

    final username = pathSegments[2];

    if (pathSegments.length > 4 && pathSegments[3] == "status") {
      final statusId = pathSegments[4];
      context.go(
        RoutePaths.statusByIdentifier(
          profileIdentifier: username,
          eventId: statusId,
        ),
      );
    } else {
      _nostrDecode(nostrCode: username, providerContainer: ref);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Center(
              child: Text(
                AppLocalizations.of(context)!.processingLink,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.userParam,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
            const SizedBox(height: 20),
            if (loading) const SpinnerCenter(),
            if (!loading)
              Text(AppLocalizations.of(context)!.noMatchingActionFound),
            if (!loading && userErrorMsg != "")
              Text(
                userErrorMsg,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            const SizedBox(height: 20),
            longButton(
              name: AppLocalizations.of(context)!.home,
              onPressed: () {
                context.go('/home');
              },
            ),
          ],
        ),
      ),
    );
  }
}
