import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:ndk/ndk.dart' as ndk;

import '../../../domain_layer/entities/nostr_note.dart';
import '../../../domain_layer/repositories/notifications_repository.dart';
import '../../data_sources/http_request_data_source.dart';
import '../../data_sources/notification_data_source.dart';
import '../../data_sources/serverpod_data_source.dart';
import '../../models/nostr_note_model.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  final NotificationDataSource notiDs;
  final HttpRequestDataSource http;
  final ServerpodDataSource serverpodDs;
  final ndk.EventSigner? eventSigner;

  NotificationsRepositoryImpl({
    required this.notiDs,
    required this.http,
    required this.serverpodDs,
    required this.eventSigner,
  });

  @override
  Future<bool> registerDevice({
    required String token,
    required NostrNote registrationNote,
  }) async {
    final registrationNoteModel = NostrNoteModel.fromEntity(registrationNote);
    final ndkEvent = registrationNoteModel.toNDKEvent();

    if (eventSigner == null) {
      throw Exception("cannot register device without signer");
    }

    await eventSigner!.sign(ndkEvent);
    return serverpodDs.client.nostrPush.register(
      token,
      [ndkEvent],
    );
  }

  @override
  // 1. Generic notification method
  Future<void> displayGenericNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    // Android notification details
    final AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'nostr_notifications',
      'Nostr Notifications',
      channelDescription: 'This channel is used to receive nostr notifications',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      showWhen: true,
      icon: 'ic_notification',
    );

    // iOS notification details
    const DarwinNotificationDetails iosNotificationDetails =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    // General notification details
    final NotificationDetails notificationDetails = NotificationDetails(
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

  @override
  Future<void> displayAvatarNotification({
    required int id,
    required String title,
    required String body,
    required String type,
    required String avatarUrl,
    required String pubkey,
    String? threadIdentifier,
    String? payload,
  }) async {
    // For Android, download the image from URL
    AndroidNotificationDetails? androidNotificationDetails;
    DarwinNotificationDetails? iosNotificationDetails;

    try {
      // Download the image from URL
      final imageBytes = await http.getBytes(avatarUrl);

      // Create Android notification with avatar
      androidNotificationDetails = AndroidNotificationDetails(
        'nostr_notifications',
        'Nostr Notifications',
        channelDescription:
            'This channel is used to receive nostr notifications',

        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        showWhen: true,
        icon: 'ic_notification',

        // Use a large icon (avatar) for the notification

        // Use person-to-person messaging style
        styleInformation: MessagingStyleInformation(
          Person(
            name: title,
            key: pubkey,
          ),
          conversationTitle: type,
          groupConversation: threadIdentifier != null,
          messages: [
            Message(
              body,
              DateTime.now(),
              Person(
                name: title,
                key: pubkey,
                icon: ByteArrayAndroidIcon(imageBytes),
              ),
            ),
          ],
        ),

        category: AndroidNotificationCategory.message,
        channelAction: AndroidNotificationChannelAction.createIfNotExists,
      );

      // Create iOS notification with attachment
      iosNotificationDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        threadIdentifier: threadIdentifier, // Group related notifications
        subtitle: type,
      );
    } catch (e) {
      // If there's an error, we'll fall back to default notification
      print('Error downloading avatar image: $e');
    }

    // If we couldn't set up the avatar notification, fall back to default
    androidNotificationDetails ??=
        _createDefaultAndroidNotification(title, body);
    iosNotificationDetails ??= const DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    // General notification details
    final NotificationDetails notificationDetails = NotificationDetails(
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

// Helper method for creating default Android notification with messaging style
  AndroidNotificationDetails _createDefaultAndroidNotification(
      String title, String body) {
    return AndroidNotificationDetails(
      'nostr_notifications',
      'Nostr Notifications',
      channelDescription: 'This channel is used to receive nostr notifications',
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
  }
}
