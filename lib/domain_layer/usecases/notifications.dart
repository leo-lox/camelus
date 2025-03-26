import 'dart:developer';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:ndk/ndk.dart' as ndk;

import '../entities/nostr_note.dart';
import '../entities/nostr_tag.dart';
import '../repositories/notifications_repository.dart';

class Notifications {
  final NotificationsRepository _notificationsRepo;
  final ndk.EventSigner? _eventSigner;

  Notifications({
    required NotificationsRepository notificationsRepository,
    required ndk.EventSigner? eventSigner,
  })  : _notificationsRepo = notificationsRepository,
        _eventSigner = eventSigner;

  Future<bool> registerDevice({
    required String token,
  }) {
    if (_eventSigner == null) {
      throw Exception("cannot register device without signer");
    }

    //! todo WIP
    final registrationNote = NostrNote(
      id: "",
      pubkey: _eventSigner!.getPublicKey(),
      created_at: 0,
      kind: 0,
      content: "",
      sig: "",
      tags: [
        NostrTag(
          type: "challenge",
          value: token,
        ),
        NostrTag(
          type: "relay",
          value: "ws://localhost:10547",
        ),
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

  onNotificationTap(NotificationResponse notiResponse) {
    log("onNotificationTapUsecase ${notiResponse.data}");
  }
}
