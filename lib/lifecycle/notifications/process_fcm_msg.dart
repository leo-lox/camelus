import 'dart:convert';

import 'package:ndk/ndk.dart';
import 'package:riverpod/riverpod.dart';

import '../../config/dicebear.dart';
import '../../presentation_layer/providers/metadata_provider.dart';
import '../../presentation_layer/providers/ndk_provider.dart';
import '../../presentation_layer/providers/notifications_provider.dart';
import '../../presentation_layer/providers/signer_provider.dart';

/// processes a FCM message
Future<void> processFcmData({
  required Map<String, dynamic> data,
  required ProviderContainer provider,
  bool isBackground = false,
}) async {
  final Map<String, dynamic> encryptedEventJson = jsonDecode(
    data['encryptedEvent'],
  );

  final encryptedWrapEvent = Nip01EventModel.fromJson(encryptedEventJson);

  final ndk = isBackground
      ? provider.read(ndkProviderLight)
      : provider.read(ndkProvider);

  final unwrappedEvent = await ndk.giftWrap.unwrapEvent(
    wrappedEvent: encryptedWrapEvent,
  );

  final notiProvider = await provider.read(notificationsProvider.future);

  if (unwrappedEvent.kind == 1) {
    final metadata = await provider
        .read(metadataProvider)
        .getMetadataByPubkey(unwrappedEvent.pubKey)
        .first;

    final signer = provider.read(signerProvider);
    final myPubkey = signer!.getPublicKey();

    final lastPtag = unwrappedEvent.pTags.last;
    final likleyDirectReply = myPubkey == lastPtag;

    final threadId = unwrappedEvent
        .getTags('e')
        .where((t) => t[3] == 'root')
        .firstOrNull;

    final payload = {
      "kind": unwrappedEvent.kind,
      "event": jsonEncode(Nip01EventModel.fromEntity(unwrappedEvent).toJson()),
      "likleyDirectReply": likleyDirectReply,
      "route": "/profile/${unwrappedEvent.pubKey}/status/$threadId",
    };

    /// display notification
    await notiProvider.displayLocalAvatarNotification(
      title:
          metadata.name ??
          metadata.nip05 ??
          "${metadata.pubkey.substring(0, 15)}...",
      body: unwrappedEvent.content.length < 280
          ? unwrappedEvent.content
          : "${unwrappedEvent.content.substring(0, 280)}...",
      avatarUrl: metadata.picture ?? "${Dicebear.baseUrlPng}${metadata.pubkey}",
      pubkey: unwrappedEvent.pubKey,
      payload: jsonEncode(payload),
      type: likleyDirectReply ? "new reply" : "new mention (thread)",
      threadIdentifier: threadId,
    );

    /// Repost => 6 or
  } else if (unwrappedEvent.kind == 6) {
    final metadata = await provider
        .read(metadataProvider)
        .getMetadataByPubkey(unwrappedEvent.pubKey)
        .first;

    final repostedNoteJson = jsonDecode(unwrappedEvent.content);

    final Nip01EventModel repostedNote = Nip01EventModel.fromJson(
      repostedNoteJson,
    );

    await notiProvider.displayLocalAvatarNotification(
      title:
          metadata.name ??
          metadata.nip05 ??
          "${metadata.pubkey.substring(0, 15)}...",
      body:
          "reposted your note: ${repostedNote.content.length < 280 ? repostedNote.content : "${repostedNote.content.substring(0, 280)}..."}",
      avatarUrl: metadata.picture ?? "${Dicebear.baseUrlPng}${metadata.pubkey}",
      pubkey: unwrappedEvent.pubKey,
      payload: jsonEncode({
        "kind": unwrappedEvent.kind,
        "event": jsonEncode(
          Nip01EventModel.fromEntity(unwrappedEvent).toJson(),
        ),
        "route": "/notifications",
      }),
      type: "repost",
    );

    /// 7=> Reaction
  } else if (unwrappedEvent.kind == 7) {
    final metadata = await provider
        .read(metadataProvider)
        .getMetadataByPubkey(unwrappedEvent.pubKey)
        .first;

    /// convert + and - to like or dislike otherwise just show the content as is (e.g. for custom emojis)
    final content = unwrappedEvent.content;

    final idOfOriginEvent = unwrappedEvent.getEId();

    if (idOfOriginEvent == null) {
      return;
    }
    final query = ndk.requests.query(
      filter: Filter(ids: [idOfOriginEvent]),
      timeout: Duration(seconds: 5),
    );

    final originEvent = (await query.future).firstOrNull;

    final reaction = content == "+"
        ? "liked"
        : content == "-"
        ? "disliked"
        : content;

    await notiProvider.displayLocalAvatarNotification(
      title:
          "$reaction from ${metadata.name ?? metadata.nip05 ?? "${metadata.pubkey.substring(0, 15)}..."}",
      body: originEvent != null
          ? originEvent.content.length < 280
                ? originEvent.content
                : "${originEvent.content.substring(0, 280)}..."
          : "reacted with $content",
      avatarUrl: metadata.picture ?? "${Dicebear.baseUrlPng}${metadata.pubkey}",
      pubkey: unwrappedEvent.pubKey,
      payload: jsonEncode({
        "kind": unwrappedEvent.kind,
        "event": jsonEncode(
          Nip01EventModel.fromEntity(unwrappedEvent).toJson(),
        ),
        "route": "/notifications",
      }),
      type: "reaction",
    );

    /// is gift wrap
  } else if (unwrappedEvent.kind == 1059) {
    final eventJson = jsonDecode(unwrappedEvent.content);
    final wrappedEventLevel2 = Nip01EventModel.fromJson(eventJson);
    final unwrappedEventLevel2 = await ndk.giftWrap.unwrapEvent(
      wrappedEvent: wrappedEventLevel2,
    );

    /// is Chat message (rumor, unsigned)
    if (unwrappedEventLevel2.kind == 14) {
      final metadata = await provider
          .read(metadataProvider)
          .getMetadataByPubkey(unwrappedEvent.pubKey)
          .first;

      await notiProvider.displayLocalAvatarNotification(
        title:
            metadata.name ??
            metadata.nip05 ??
            "${metadata.pubkey.substring(0, 15)}...",
        body: unwrappedEvent.content.length < 280
            ? unwrappedEvent.content
            : "${unwrappedEvent.content.substring(0, 280)}...",
        avatarUrl:
            metadata.picture ?? "${Dicebear.baseUrlPng}${metadata.pubkey}",
        pubkey: unwrappedEvent.pubKey,
        payload: jsonEncode({
          "kind": unwrappedEventLevel2.kind,
          "event": jsonEncode(
            Nip01EventModel.fromEntity(unwrappedEvent).toJson(),
          ),
          "route": "/messages/${unwrappedEvent.pubKey}",
        }),
        type: "chat_message",
      );
    } else {
      await notiProvider.displayGenericNotification(
        title:
            "recieved a gift wrapped event of kind ${unwrappedEventLevel2.kind}",
        body: unwrappedEventLevel2.content,
        payload: jsonEncode({
          "kind": unwrappedEventLevel2.kind,
          "event": jsonEncode(
            Nip01EventModel.fromEntity(unwrappedEvent).toJson(),
          ),
          "route": "/",
        }),
      );
    }
  } else {
    await notiProvider.displayGenericNotification(
      title: "New event of kind ${unwrappedEvent.kind}",
      body: unwrappedEvent.content,
      payload: jsonEncode({
        "kind": unwrappedEvent.kind,
        "event": jsonEncode(
          Nip01EventModel.fromEntity(unwrappedEvent).toJson(),
        ),
        "route": "/",
      }),
    );
  }
}
