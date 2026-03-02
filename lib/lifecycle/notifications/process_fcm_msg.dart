import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:ndk/ndk.dart';
import 'package:riverpod/riverpod.dart';

import '../../config/dicebear.dart';
import '../../presentation_layer/providers/metadata_provider.dart';
import '../../presentation_layer/providers/ndk_provider.dart';
import '../../presentation_layer/providers/notifications_provider.dart';
import '../../presentation_layer/providers/signer_provider.dart';
import 'notification_types.dart';

/// processes a FCM message
Future<void> processFcmData({
  required Map<String, dynamic> data,
  required ProviderContainer provider,
  bool isBackground = false,
}) async {
  try {
    final encryptedEventRaw = data['encryptedEvent'];
    if (encryptedEventRaw is! String || encryptedEventRaw.isEmpty) {
      throw const FormatException('Missing encryptedEvent in FCM payload');
    }

    final Map<String, dynamic> encryptedEventJson = jsonDecode(
      encryptedEventRaw,
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
      if (signer == null) {
        throw StateError('No signer available while processing mention/reply');
      }
      final myPubkey = signer.getPublicKey();

      final lastPtag = unwrappedEvent.pTags.last;
      final likleyDirectReply = myPubkey == lastPtag;

      final threadId = unwrappedEvent
          .getTags('e')
          .where((t) => t[3] == 'root')
          .firstOrNull;

      final payload = {
        "kind": unwrappedEvent.kind,
        "event": jsonEncode(
          Nip01EventModel.fromEntity(unwrappedEvent).toJson(),
        ),
        "likleyDirectReply": likleyDirectReply,
        "route": "/profile/${unwrappedEvent.pubKey}/status/$threadId",
      };

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
        payload: jsonEncode(payload),
        type: likleyDirectReply
            ? NotificationTypeLocal.reply
            : NotificationTypeLocal.mention,
        threadIdentifier: threadId,
      );
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
        avatarUrl:
            metadata.picture ?? "${Dicebear.baseUrlPng}${metadata.pubkey}",
        pubkey: unwrappedEvent.pubKey,
        payload: jsonEncode({
          "kind": unwrappedEvent.kind,
          "event": jsonEncode(
            Nip01EventModel.fromEntity(unwrappedEvent).toJson(),
          ),
          "route": "/notifications",
        }),
        type: NotificationTypeLocal.repost,
      );
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
        avatarUrl:
            metadata.picture ?? "${Dicebear.baseUrlPng}${metadata.pubkey}",
        pubkey: unwrappedEvent.pubKey,
        payload: jsonEncode({
          "kind": unwrappedEvent.kind,
          "event": jsonEncode(
            Nip01EventModel.fromEntity(unwrappedEvent).toJson(),
          ),
          "route": "/notifications",
        }),
        type: NotificationTypeLocal.reaction,
      );

      /// is gift wrap
    } else if (unwrappedEvent.kind == 1059) {
      final unwrappedEventLevel2 = await ndk.giftWrap.fromGiftWrap(
        giftWrap: unwrappedEvent,
      );

      /// is Chat message (rumor, unsigned)
      if (unwrappedEventLevel2.kind == 14) {
        final metadata = await provider
            .read(metadataProvider)
            .getMetadataByPubkey(unwrappedEventLevel2.pubKey)
            .first;

        await notiProvider.displayLocalAvatarNotification(
          notificationId: metadata.pubkey.hashCode,
          title:
              metadata.name ??
              metadata.nip05 ??
              "${metadata.pubkey.substring(0, 15)}...",
          body: unwrappedEventLevel2.content.length < 280
              ? unwrappedEventLevel2.content
              : "${unwrappedEventLevel2.content.substring(0, 280)}...",
          avatarUrl:
              metadata.picture ?? "${Dicebear.baseUrlPng}${metadata.pubkey}",
          pubkey: unwrappedEventLevel2.pubKey,
          payload: jsonEncode({
            "kind": unwrappedEventLevel2.kind,
            "event": jsonEncode(
              Nip01EventModel.fromEntity(unwrappedEventLevel2).toJson(),
            ),
            "route": "/messages/${unwrappedEventLevel2.pubKey}",
          }),
          type: NotificationTypeLocal.chatMessage,
        );
      } else {
        await notiProvider.displayGenericNotification(
          title:
              "recieved a gift wrapped event of kind ${unwrappedEventLevel2.kind}",
          body: unwrappedEventLevel2.content,
          payload: jsonEncode({
            "kind": unwrappedEventLevel2.kind,
            "event": jsonEncode(
              Nip01EventModel.fromEntity(unwrappedEventLevel2).toJson(),
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
  } catch (e, st) {
    print('[BG_FCM] processFcmData error: $e');
    print('[BG_FCM] processFcmData stack: $st');
    developer.log(
      'Failed to process FCM payload',
      name: 'processFcmData',
      error: e,
      stackTrace: st,
    );
    await _showProcessingFailureNotification(
      provider: provider,
      data: data,
      error: e,
      isBackground: isBackground,
    );
  }
}

Future<void> _showProcessingFailureNotification({
  required ProviderContainer provider,
  required Map<String, dynamic> data,
  required Object error,
  required bool isBackground,
}) async {
  final title = isBackground
      ? 'Background push processing failed'
      : 'Push processing failed';
  final body =
      'Reason: ${_truncate(error.toString(), 140)}. Keys: ${data.keys.join(', ')}';

  try {
    final notiProvider = await provider.read(notificationsProvider.future);
    await notiProvider.displayGenericNotification(
      title: title,
      body: _truncate(body, 220),
      payload: jsonEncode({
        'kind': -1,
        'route': '/notifications',
        'debugError': _truncate(error.toString(), 300),
      }),
    );
    return;
  } catch (e, st) {
    print('[BG_FCM] provider failure notification failed: $e');
    developer.log(
      'Failed to show error notification via provider; trying plugin fallback',
      name: 'processFcmData',
      error: e,
      stackTrace: st,
    );
  }

  await _showFallbackNotification(title: title, body: _truncate(body, 220));
}

Future<void> _showFallbackNotification({
  required String title,
  required String body,
}) async {
  final notificationsPlugin = FlutterLocalNotificationsPlugin();

  const initSettings = InitializationSettings(
    android: AndroidInitializationSettings('ic_notification'),
    iOS: DarwinInitializationSettings(),
    macOS: DarwinInitializationSettings(),
  );

  await notificationsPlugin.initialize(initSettings);

  const details = NotificationDetails(
    android: AndroidNotificationDetails(
      'nostr_notifications',
      'Nostr Notifications',
      channelDescription: 'This channel is used to recieve nostr notifications',
      importance: Importance.high,
      priority: Priority.high,
      icon: 'ic_notification',
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    ),
  );

  await notificationsPlugin.show(
    DateTime.now().millisecondsSinceEpoch.remainder(100000),
    title,
    body,
    details,
  );
}

String _truncate(String value, int maxLength) {
  if (value.length <= maxLength) {
    return value;
  }
  return '${value.substring(0, maxLength - 3)}...';
}
