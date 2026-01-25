import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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

  Future<bool> registerDevice({required String token}) async {
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
  }) {
    return _notificationsRepo.displayAvatarNotification(
      id: _getNotificationId(),
      title: title,
      body: body,
      avatarUrl: avatarUrl,
      pubkey: pubkey,
      type: type,
      threadIdentifier: threadIdentifier,
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
    if (payload != null) {
      final payloadJson = jsonDecode(payload);
      final nostrNoteJson = jsonDecode(payloadJson['note']);
      final bool likleyDirectReply = payloadJson['likleyDirectReply'];
      final nostrNote = NostrNoteModel.fromJson(nostrNoteJson);

      if (likleyDirectReply) {
        final replyId = nostrNote.getDirectReply?.value;
        final rootId = nostrNote.getRootReply?.value;

        navigatorKey.currentState?.pushNamed(
          "/nostr/event",
          arguments: <String, String?>{
            "root": rootId ?? replyId ?? nostrNote.id,
            "scrollIntoView": replyId,
          },
        );
      }
    }
  }
}
