import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:camelus/presentation_layer/providers/nip05_provider.dart';

import 'package:riverpod/riverpod.dart';

import '../domain_layer/entities/starter_pack_identifier.dart';
import '../domain_layer/usecases/app_auth.dart';
import '../helpers/helpers.dart';
import '../helpers/nevent_helper.dart';
import '../helpers/nprofile_helper.dart';
import '../main.dart';
import '../presentation_layer/providers/onboarding_provider.dart';

/// sets up links listener
//todo: fetch the notes with inbox/outbox first then navigate to the note
Future<void> listenDeeplinks({
  required ProviderContainer providerContainer,
}) async {
  final appLinks = AppLinks(); // AppLinks is singleton

// Subscribe to all events (initial link and further)
  final sub = appLinks.uriLinkStream.listen((uri) async {
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
  final myMatch = link.replaceAll("https://camelus.app", "");

  if (myMatch.startsWith("/i/") || myMatch.startsWith("/ii/")) {
    final List<String> myMatchSplit = myMatch.split("/");
    final String invitedBy = myMatchSplit[2];
    final String listName = myMatchSplit[3];
    final String? listPubkey;

    final String decodedInviteBy;
    final String? decodedListPubkey;

    if (myMatchSplit.length >= 5) {
      listPubkey = myMatchSplit[4];
      decodedListPubkey =
          NprofileHelper().nprofileOrNpubToMap(listPubkey)['pubkey'];
    } else {
      listPubkey = null;
      decodedListPubkey = null;
    }

    decodedInviteBy = NprofileHelper().nprofileOrNpubToMap(invitedBy)['pubkey'];

    /// check if account already setup
    final mySigner = await AppAuth.getEventSigner();

    if (mySigner != null) {
      print("account already setup");

      navigatorKey.currentState?.pushNamed('/open-starter-pack',
          arguments: StarterPackIdentifier(
            name: listName,
            pubkey: decodedListPubkey ?? decodedInviteBy,
          ));
      return;
    }

    NprofileHelper().nprofileOrNpubToMap(invitedBy);

    final provider = providerContainer.read(onboardingProvider);

    try {
      provider.signUpInfo.invitedByPubkey = decodedInviteBy;
      provider.signUpInfo.listName = listName;
      provider.signUpInfo.listPubkey = decodedListPubkey ?? decodedInviteBy;
      //todo: add relays to ndk
    } catch (e) {
      print("error $e");
    }

    // to update state
    navigatorKey.currentState?.pushReplacementNamed(
      "/onboarding",
    );
  } else if (myMatch.startsWith("/user/")) {
    final List<String> myMatchSplit = myMatch.split("/");

    final String username = myMatchSplit[2];

    if (myMatchSplit.length > 3 && myMatchSplit[3] == "status") {
      // This is a status URL
      final String statusId = myMatchSplit[4];

      _pushNote(
        noteId: statusId,
      );
    } else {
      // This is just a user profile URL
      _nostrDecode(nostrCode: username, providerContainer: providerContainer);
    }
  } else {
    print("camelus link not supported ${link}");
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

    final List<String> myRelays = nProfileDecode['relays'];
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
    final String hr = decode[0];
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
    final String authorPubkey = map['authorPubkey'];

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
