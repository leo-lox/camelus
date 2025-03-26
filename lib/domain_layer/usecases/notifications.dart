import 'dart:developer';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../entities/nostr_note.dart';
import '../entities/nostr_tag.dart';
import '../repositories/notifications_repository.dart';

class Notifications {
  final NotificationsRepository _notificationsRepo;

  Notifications({
    required NotificationsRepository notificationsRepository,
  }) : _notificationsRepo = notificationsRepository;

  Future<bool> registerDevice({
    required String token,
  }) {
    //! todo WIP
    final registrationNote = NostrNote(
      id: "",
      pubkey:
          "da1678cd43b0afed5c5566b878a0a5faae97b16635b47d58b9179a75de500801",
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

  displayLocalAvatarNotification({
    required String title,
    required String body,
    String? payload,
  }) {
    return _notificationsRepo.displayAvatarNotification(
      id: _getNotificationId(),
      title: title,
      body: body,
      avatarUrl: "https://lox.de/downloads/profile.jpg",
      pubkey:
          "717ff238f888273f5d5ee477097f2b398921503769303a0c518d06a952f2a75e",
      type: "new reply",
      threadIdentifier:
          "717ff238f888273f5d5ee477097f2b398921503769303a0c518d06a952f2a75e",
      payload: payload,
    );
  }

  onNotificationTap(NotificationResponse notiResponse) {
    log("onNotificationTap $notiResponse");
  }
}
