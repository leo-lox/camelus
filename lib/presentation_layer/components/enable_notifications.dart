import 'dart:developer';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/palette.dart';
import '../providers/db_app_provider.dart';

// Create a provider to track notification enabled status
final notificationsEnabledProvider = StateProvider<bool>((ref) => false);

// Create a provider to track if permissions were explicitly denied
final notificationsDeniedProvider = StateProvider<bool>((ref) => false);

class PushNotificationToggle extends ConsumerStatefulWidget {
  const PushNotificationToggle({super.key});

  @override
  PushNotificationToggleState createState() => PushNotificationToggleState();
}

class PushNotificationToggleState
    extends ConsumerState<PushNotificationToggle> {
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    // Check if notifications are already enabled
    checkNotificationStatus();
  }

  Future<void> checkNotificationStatus() async {
    setState(() {
      isLoading = true;
    });

    // Check current permission status
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    final settings = await messaging.getNotificationSettings();

    // If authorized, consider notifications as enabled
    final isEnabled =
        settings.authorizationStatus == AuthorizationStatus.authorized;
    ref.read(notificationsEnabledProvider.notifier).state = isEnabled;

    // Check if permissions were explicitly denied
    final isDenied = settings.authorizationStatus == AuthorizationStatus.denied;
    ref.read(notificationsDeniedProvider.notifier).state = isDenied;

    // If enabled, ensure we have the token stored
    if (isEnabled) {
      await getAndStoreToken();
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> toggleNotifications(bool newValue) async {
    if (newValue) {
      await requestPermission();
    } else {
      ref.read(notificationsEnabledProvider.notifier).state = false;

      // Clear the stored token
      final appDb = ref.read(dbAppProvider);

      await FirebaseMessaging.instance.deleteToken();
      await appDb.delete("fcm_token");

      // await FirebaseMessaging.instance.unsubscribeFromTopic('news');
    }
  }

  Future<void> requestPermission() async {
    setState(() {
      isLoading = true;
    });

    FirebaseMessaging messaging = FirebaseMessaging.instance;

    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    final isAuthorized =
        settings.authorizationStatus == AuthorizationStatus.authorized;
    ref.read(notificationsEnabledProvider.notifier).state = isAuthorized;

    // Update denied status
    final isDenied = settings.authorizationStatus == AuthorizationStatus.denied;
    ref.read(notificationsDeniedProvider.notifier).state = isDenied;

    if (isAuthorized) {
      await getAndStoreToken();
    } else {
      log("not authorized: ${settings.authorizationStatus}");
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> getAndStoreToken() async {
    String? token = await FirebaseMessaging.instance.getToken();

    if (token != null) {
      log("got token: $token");
      // Store token in your database
      final appDb = ref.read(dbAppProvider);
      await appDb.save(key: "fcm_token", value: token);

      // Set up token refresh listener
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        if (ref.read(notificationsEnabledProvider)) {
          await appDb.save(key: "fcm_token", value: newToken);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final notificationsEnabled = ref.watch(notificationsEnabledProvider);
    final notificationsDenied = ref.watch(notificationsDeniedProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Push Notifications',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (isLoading)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Switch(
                  value: notificationsEnabled,
                  onChanged: toggleNotifications,
                  activeColor: Palette.white,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            notificationsEnabled
                ? 'You will receive notifications about new events.'
                : 'Enable notifications to receive events.',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          // Only show the hint message if permissions were explicitly denied
          if (notificationsDenied)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'Note: You previously denied notifications. Please enable them in your device settings to receive notifications.',
                style: TextStyle(
                  color: Colors.orange[700],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
