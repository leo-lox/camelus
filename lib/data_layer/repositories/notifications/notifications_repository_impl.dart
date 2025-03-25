import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../../domain_layer/repositories/notifications_repository.dart';
import '../../data_sources/notification_data_source.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  NotificationDataSource notiDs;

  NotificationsRepositoryImpl({
    required this.notiDs,
  });

  @override
  Future<List<Map<String, dynamic>>> registerDevice() {
    // TODO: implement registerDevice
    throw UnimplementedError();
  }

  @override
  Future<void> displayNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    // Android notification details
    AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'nostr_notifications',
      'Nostr Notifications',
      channelDescription: 'This channel is used to recieve nostr notifications',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      showWhen: true,
      styleInformation: MessagingStyleInformation(
        Person(
          name: title,
          icon: FlutterBitmapAssetAndroidIcon(
              "assets/images/list_placeholder.png"),
        ),
        conversationTitle: 'New Message',
        messages: [
          Message(
            body,
            DateTime.now(),
            Person(
              name: title,
              icon: FlutterBitmapAssetAndroidIcon(
                  "assets/images/list_placeholder.png"),
            ),
          ),
        ],
      ),
    );

    // iOS notification details
    const DarwinNotificationDetails iosNotificationDetails =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    // General notification details
    NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: iosNotificationDetails,
    );

    // Show the notification
    await notiDs.notificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }
}
