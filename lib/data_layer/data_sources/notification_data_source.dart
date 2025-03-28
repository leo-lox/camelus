import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../config/camelus_config.dart';

class NotificationDataSource {
  final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Use a callback setter instead of constructor injection
  void Function(NotificationResponse)? _onNotificationTap;

  NotificationDataSource();

  // Setter method to update the callback
  set onNotificationTap(void Function(NotificationResponse) callback) {
    _onNotificationTap = callback;
  }

  // Internal handler that delegates to the current callback
  void _handleNotificationResponse(NotificationResponse response) {
    if (_onNotificationTap != null) {
      _onNotificationTap!(response);
    }
  }

  // Initialize the plugin
  Future<void> initializeNotifications() async {
    // Android initialization settings
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('ic_notification');

    // iOS initialization settings
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const WindowsInitializationSettings initializationSettingsWindows =
        WindowsInitializationSettings(
      appName: "camelus",
      appUserModelId: CamelusConfig.appUserModelId,
      guid: CamelusConfig.notificationGUid,
    );

    const LinuxInitializationSettings initializationSettingsLinux =
        LinuxInitializationSettings(
      defaultActionName: "camelus",
    );

    // Initialization settings
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
      windows: initializationSettingsWindows,
      linux: initializationSettingsLinux,
      macOS: initializationSettingsIOS,
    );

    // Initialize the plugin
    await notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _handleNotificationResponse,
    );

    // Create notification channel for Android
    await createNotificationChannel();
  }

  Future<void> createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'nostr_notifications',
      'Nostr Notifications',
      description: 'This channel is used to recieve nostr notifications',
      importance: Importance.high,
    );

    await notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }
}
