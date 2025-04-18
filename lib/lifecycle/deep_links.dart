import 'dart:async';

import 'package:app_links/app_links.dart';

import 'package:riverpod/riverpod.dart';

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
    if (uriString.startsWith("nostr:")) {
      _nostrLinks(
        link: uriString,
      );
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
    final String inviteListName = myMatchSplit[3];

    /// check if account already setup
    final mySigner = await AppAuth.getEventSigner();

    if (mySigner != null) {
      print("account already setup");
      return;
    }

    NprofileHelper().nprofileOrNpubToMap(invitedBy);

    final provider = providerContainer.read(onboardingProvider);

    try {
      final decoded = NprofileHelper().nprofileOrNpubToMap(invitedBy);

      provider.signUpInfo.invitedByPubkey = decoded['pubkey'];
      provider.signUpInfo.inviteListName = inviteListName;
      //todo: add relays to ndk
    } catch (e) {
      print("error $e");
    }

    // to update state
    navigatorKey.currentState?.pushReplacementNamed(
      "/onboarding",
    );
  } else {
    print("camelus link not supported ${link}");
  }
}

_nostrLinks({
  required String link,
}) {
  final myMatch = link.replaceAll("nostr:", "");
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
  }
}

_pushProfile({
  required String pubkey,
}) {
  navigatorKey.currentState?.pushNamed(
    "/nostr/profile",
    arguments: pubkey,
  );
}

_pushNote({
  required String noteId,
}) {
  navigatorKey.currentState?.pushNamed(
    "/nostr/event",
    arguments: {
      "root": noteId,
      "scrollIntoView": null,
    },
  );
}
