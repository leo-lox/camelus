import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

import 'package:riverpod/riverpod.dart';

import '../domain_layer/entities/invite_data.dart';
import '../domain_layer/entities/starter_pack_identifier.dart';
import '../domain_layer/usecases/app_auth.dart';
import '../helpers/helpers.dart';
import '../helpers/nevent_helper.dart';
import '../helpers/nprofile_helper.dart';
import '../main.dart';
import '../presentation_layer/providers/nip05_provider.dart';
import '../presentation_layer/providers/onboarding_provider.dart';
import '../presentation_layer/providers/serverpod_provider.dart';

/// sets up links listener
//todo: fetch the notes with inbox/outbox first then navigate to the note
Future<void> listenDeeplinks({
  required ProviderContainer providerContainer,
}) async {
  final appLinks = AppLinks(); // AppLinks is singleton

// Subscribe to all events (initial link and further)
  appLinks.uriLinkStream.listen((uri) async {
    final uriString = uri.toString();
    if (uriString.startsWith(RegExp(r'nostr:(//)?'))) {
      final nostrCode = uriString.replaceAll(RegExp(r'nostr:(//)?'), "");
      _nostrDecode(nostrCode: nostrCode, providerContainer: providerContainer);
    } else if (uriString.startsWith(RegExp(r'camelus:(//)?'))) {
      final nostrCode = uriString.replaceAll(RegExp(r'camelus:(//)?'), "");

      _nostrDecode(nostrCode: nostrCode, providerContainer: providerContainer);
    } else if (uriString.startsWith("https://camelus.app")) {
      await _camelusLinks(
        link: uriString,
        providerContainer: providerContainer,
      );
    }
  });
}

Future<void> _camelusLinks({
  required String link,
  required ProviderContainer providerContainer,
}) async {
  final path = link.replaceAll("https://camelus.app", "");

  if (_isInviteLink(path)) {
    await _handleInviteLink(path, providerContainer);
  } else if (_isUserLink(path)) {
    await _handleUserLink(path, providerContainer);
  } else {
    if (kDebugMode) {
      print("Camelus link not supported: $link");
    }
  }
}

bool _isInviteLink(String path) {
  return path.startsWith("/i/") || path.startsWith("/ii/");
}

bool _isUserLink(String path) {
  return path.startsWith("/user/");
}

Future<void> _handleInviteLink(
  String path,
  ProviderContainer providerContainer,
) async {
  final pathSegments = path.split("/");
  if (pathSegments.length < 3) return;

  final firstParam = pathSegments[2];
  final InviteData inviteData;

  if (firstParam.startsWith("s")) {
    inviteData = await _getShortInviteData(firstParam, providerContainer);
    if (inviteData.isEmpty) return;
  } else {
    inviteData = InviteData(
      inviteByNpub: firstParam,
      listName: pathSegments.length > 3 ? pathSegments[3] : "",
      listNpub: pathSegments.length >= 5 ? pathSegments[4] : null,
    );
  }

  final decodedInviteBy = _decodePubkey(inviteData.inviteByNpub);
  final decodedListPubkey =
      inviteData.listNpub != null ? _decodePubkey(inviteData.listNpub!) : null;

  final mySigner = await AppAuth.getEventSigner();

  if (mySigner != null) {
    _navigateToStarterPack(
      inviteData.listName,
      decodedListPubkey ?? decodedInviteBy,
    );
    return;
  }

  await _setupOnboarding(
    providerContainer,
    decodedInviteBy,
    inviteData.listName,
    decodedListPubkey ?? decodedInviteBy,
  );
}

Future<InviteData> _getShortInviteData(
  String shortLink,
  ProviderContainer providerContainer,
) async {
  try {
    final serverpodProv = providerContainer.read(serverpodProvider);
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
      print("Error fetching short invite data: $e");
    }
    return InviteData.empty();
  }
}

String _decodePubkey(String npubOrNprofile) {
  return NprofileHelper().nprofileOrNpubToMap(npubOrNprofile)['pubkey'];
}

void _navigateToStarterPack(String listName, String pubkey) {
  navigatorKey.currentState?.pushNamed(
    '/open-starter-pack',
    arguments: StarterPackIdentifier(
      name: listName,
      pubkey: pubkey,
    ),
  );
}

Future<void> _setupOnboarding(
  ProviderContainer providerContainer,
  String decodedInviteBy,
  String listName,
  String listPubkey,
) async {
  try {
    final provider = providerContainer.read(onboardingProvider);
    provider.signUpInfo.invitedByPubkey = decodedInviteBy;
    provider.signUpInfo.listName = listName;
    provider.signUpInfo.listPubkey = listPubkey;

    navigatorKey.currentState?.pushReplacementNamed("/onboarding");
  } catch (e) {
    if (kDebugMode) {
      print("Error setting up onboarding: $e");
    }
  }
}

Future<void> _handleUserLink(
  String path,
  ProviderContainer providerContainer,
) async {
  final pathSegments = path.split("/");
  if (pathSegments.length < 3) return;

  final username = pathSegments[2];

  if (pathSegments.length > 4 && pathSegments[3] == "status") {
    final statusId = pathSegments[4];
    _pushNote(noteId: statusId);
  } else {
    _nostrDecode(nostrCode: username, providerContainer: providerContainer);
  }
}

_nostrDecode({
  required String nostrCode,
  required ProviderContainer providerContainer,
}) async {
  final myMatch = nostrCode;
  String myPubkeyHex = "";

  if (myMatch.contains("nprofile")) {
    // remove the "nostr:" part

    Map<String, dynamic> nProfileDecode = NprofileHelper().bech32toMap(myMatch);

    myPubkeyHex = nProfileDecode['pubkey'];

    _pushProfile(
      pubkey: myPubkeyHex,
    );
  } else if (myMatch.contains("npub")) {
    final List decode = Helpers().decodeBech32(myMatch);

    myPubkeyHex = decode[0];

    _pushProfile(
      pubkey: myPubkeyHex,
    );
  } else if (myMatch.contains("note1")) {
    final decode = Helpers().decodeBech32(myMatch);
    final String noteId = decode[1];
    if (noteId.isEmpty) {
      return;
    }
    _pushNote(
      noteId: noteId,
    );
  } else if (myMatch.contains("nevent")) {
    final map = NeventHelper().bech32ToMap(myMatch);
    final String eventId = map['eventId'];

    if (eventId.isEmpty) {
      return;
    }

    _pushNote(
      noteId: eventId,
    );
  } else if (myMatch.contains("@")) {
    final nip05P = providerContainer.read(nip05provider);
    final nip05Data = await nip05P.get(myMatch);
    if (nip05Data != null) {
      _pushProfile(pubkey: nip05Data.pubkey);
    }
  }
}

_pushProfile({
  required String pubkey,
}) {
  navigatorKey.currentState?.pushNamedAndRemoveUntil(
    "/nostr/profile",
    (route) => route.isFirst,
    arguments: pubkey,
  );
}

_pushNote({
  required String noteId,
}) {
  navigatorKey.currentState?.pushNamedAndRemoveUntil(
    "/nostr/event",
    (route) => route.isFirst,
    arguments: {
      "root": noteId,
      "scrollIntoView": null,
    },
  );
}
