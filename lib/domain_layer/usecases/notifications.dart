import 'dart:convert';
import 'dart:developer' as developer;
import 'package:camelus/presentation_layer/routing/route_paths.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:ndk/ndk.dart' as ndk;

import '../../config/default_relays.dart';
import '../../data_layer/models/nostr_note_model.dart';
import '../../main.dart';
import '../entities/nostr_note.dart';
import '../entities/nostr_tag.dart';
import '../repositories/notifications_repository.dart';
import 'inbox_outbox.dart';

class Notifications {
  final NotificationsRepository _notificationsRepo;
  final ndk.EventSigner? _eventSigner;
  final InboxOutbox _inboxOutbox;

  Notifications({
    required NotificationsRepository notificationsRepository,
    required ndk.EventSigner? eventSigner,
    required InboxOutbox inboxOutbox,
  }) : _notificationsRepo = notificationsRepository,
       _eventSigner = eventSigner,
       _inboxOutbox = inboxOutbox;

  Future<bool> registerDevice({required String token, List<int>? kinds}) async {
    if (_eventSigner == null) {
      throw Exception("cannot register device without signer");
    }

    final myPubkey = _eventSigner.getPublicKey();

    final nip65data = await _inboxOutbox.getNip65data(myPubkey);

    List<String> readRelays;

    if (nip65data != null) {
      readRelays = nip65data.relays.entries
          .where((e) => e.value.isRead)
          .map((e) => e.key)
          .toList();
    } else {
      readRelays = defaultAccountCreationRelays.entries
          .where((e) => e.value.isRead)
          .map((e) => e.key)
          .toList();
    }

    final kindTags = (kinds ?? [])
        .map((kind) => NostrTag(type: "kind", value: kind.toString()))
        .toList();

    final registrationNote = NostrNote(
      id: "",
      pubkey: myPubkey,
      createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      kind: 0,
      content: "",
      sig: "",
      tags: [
        NostrTag(type: "challenge", value: token),
        ...readRelays.map((relayUrl) {
          return NostrTag(type: "relay", value: relayUrl);
        }),
        ...kindTags,

        //NostrTag(type: "relay", value: "ws://localhost:10547")
      ],
    );

    //   ["challenge", "your_firebase_token_or_webhook_url"],
    //   ["relay", "wss://relay1.example.com"],
    //   ["relay", "wss://relay2.example.com"]

    return _notificationsRepo.registerDevice(
      token: token,
      registrationNote: registrationNote,
    );
  }

  Future<void> deleteNotification(int id) async {
    await _notificationsRepo.deleteNotification(id);
  }

  // show multiple
  int _getNotificationId() =>
      DateTime.now().millisecondsSinceEpoch.remainder(100000);

  Future<void> displayLocalAvatarNotification({
    required String title,
    required String body,
    required String avatarUrl,
    required String pubkey,

    /// e.g. new reply
    required String type,
    String? threadIdentifier,
    String? payload,
    int? notificationId,
  }) {
    return _notificationsRepo.displayAvatarNotification(
      id: notificationId ?? _getNotificationId(),
      title: title,
      body: body,
      avatarUrl: avatarUrl,
      pubkey: pubkey,
      type: type,
      threadIdentifier: threadIdentifier,
      payload: payload,
    );
  }

  Future<void> displayGenericNotification({
    required String title,
    required String body,
    String? payload,
    int? notificationId,
  }) {
    return _notificationsRepo.displayGenericNotification(
      id: notificationId ?? _getNotificationId(),
      title: title,
      body: body,
      payload: payload,
    );
  }

  /// called on foreground or paused
  void onNotificationTap(NotificationResponse notiResponse) {
    developer.log("onNotificationTapUsecase ${notiResponse.payload}");

    processNotificationPayload(notiResponse.payload);
  }

  /// gets called on lauch if payload is found
  static void processNotificationPayload(String? payload) {
    if (payload == null) {
      return;
    }
    final payloadJson = jsonDecode(payload);
    final routeTo = payloadJson['route'] as String?;

    if (payloadJson['kind'] == 1) {
      final nostrEventJson = jsonDecode(payloadJson['event']);
      final bool likleyDirectReply = payloadJson['likleyDirectReply'];
      final nostrEvent = NostrNoteModel.fromJson(nostrEventJson);

      if (likleyDirectReply) {
        final replyId = nostrEvent.getDirectReply?.value;
        final rootId = nostrEvent.getRootReply?.value;

        GoRouter.of(navigatorKey.currentContext!).push(
          RoutePaths.status(
            pubkey: nostrEvent.pubkey,
            eventId: rootId ?? replyId ?? nostrEvent.id,
            scrollIntoView: replyId,
          ),
        );
      }
      return;
    }
    if (routeTo != null) {
      GoRouter.of(navigatorKey.currentContext!).push(routeTo);
    } else {
      developer.log("no route found in payload");
    }
  }
}
