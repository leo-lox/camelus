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
    return _notificationsRepo.displayNotification(
      id: _getNotificationId(),
      title: title,
      body: body,
      payload: payload,
    );
  }

  onNotificationTap(NotificationResponse notiResponse) {
    log("onNotificationTap $notiResponse");
  }
}
