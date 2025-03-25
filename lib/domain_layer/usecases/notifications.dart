import 'dart:developer';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../repositories/notifications_repository.dart';

class Notifications {
  final NotificationsRepository _notificationsRepo;

  Notifications({
    required NotificationsRepository notificationsRepository,
  }) : _notificationsRepo = notificationsRepository;

  Future<List<Map<String, dynamic>>> registerDevice() {
    return _notificationsRepo.registerDevice();
  }

  // show multiple
  int _getNotificationId() =>
      DateTime.now().millisecondsSinceEpoch.remainder(100000);

  displayLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) {
    return _notificationsRepo.displayAvatarNotification(
      id: _getNotificationId(),
      title: "Leo",
      body: "lorem ipsum",
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
