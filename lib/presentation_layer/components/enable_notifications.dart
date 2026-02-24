import 'dart:async';
import 'dart:developer';

import 'package:camelus/l10n/app_localizations.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../atoms/spinner_center.dart';
import '../providers/db_app_provider.dart';
import '../providers/notifications_provider.dart';

// Create a provider to track notification enabled status
final notificationsEnabledProvider =
    NotifierProvider<NotificationsEnabledNotifier, bool>(
      NotificationsEnabledNotifier.new,
    );

class NotificationsEnabledNotifier extends Notifier<bool> {
  @override
  bool build() {
    return false;
  }

  void setEnabled(bool enabled) {
    state = enabled;
  }
}

// Create a provider to track if permissions were explicitly denied
final notificationsDeniedProvider =
    NotifierProvider<NotificationsDeniedNotifier, bool>(
      NotificationsDeniedNotifier.new,
    );

class NotificationsDeniedNotifier extends Notifier<bool> {
  @override
  bool build() {
    return false;
  }

  void setDenied(bool denied) {
    state = denied;
  }
}

class PushNotificationToggle extends ConsumerStatefulWidget {
  const PushNotificationToggle({super.key});

  @override
  PushNotificationToggleState createState() => PushNotificationToggleState();
}

class PushNotificationToggleState
    extends ConsumerState<PushNotificationToggle> {
  bool isLoading = true;
  bool platformSupported = true;

  @override
  void initState() {
    super.initState();

    // platform supported?
    if (kIsWeb ||
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      // Check if notifications are already enabled
      checkNotificationStatus();
    } else {
      setState(() {
        platformSupported = false;
      });
    }
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
    ref.read(notificationsEnabledProvider.notifier).setEnabled(isEnabled);

    // Check if permissions were explicitly denied
    final isDenied = settings.authorizationStatus == AuthorizationStatus.denied;
    ref.read(notificationsDeniedProvider.notifier).setDenied(isDenied);

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
      ref.read(notificationsEnabledProvider.notifier).setEnabled(false);

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
    ref.read(notificationsEnabledProvider.notifier).setEnabled(isAuthorized);

    // Update denied status
    final isDenied = settings.authorizationStatus == AuthorizationStatus.denied;
    ref.read(notificationsDeniedProvider.notifier).setDenied(isDenied);

    if (isAuthorized) {
      final token = await getAndStoreToken();
      if (token != null) {
        final result = await registerToken(token);
        log(result.toString());
      }
    } else {
      log("not authorized: ${settings.authorizationStatus}");
    }

    setState(() {
      isLoading = false;
    });
  }

  /// [returns] token
  Future<String?> getAndStoreToken() async {
    String? token = await FirebaseMessaging.instance.getToken();

    if (token != null) {
      log("got token: $token");
      // Store token in your database
      final appDb = ref.read(dbAppProvider);
      await appDb.save(key: "fcm_token", value: token);
    }
    return token;
  }

  Future<bool> registerToken(String token) async {
    final notiProvider = await ref.read(notificationsProvider.future);
    return notiProvider.registerDevice(token: token);
  }

  @override
  Widget build(BuildContext context) {
    final notificationsEnabled = ref.watch(notificationsEnabledProvider);
    final notificationsDenied = ref.watch(notificationsDeniedProvider);

    if (!platformSupported) {
      return Container();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.pushNotifications,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              if (isLoading)
                const SizedBox(width: 24, height: 24, child: SpinnerCenter())
              else
                Switch(
                  value: notificationsEnabled,
                  onChanged: toggleNotifications,
                  activeThumbColor: Theme.of(context).colorScheme.onSurface,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            notificationsEnabled
                ? AppLocalizations.of(context)!.receiveNotificationsAboutReplies
                : AppLocalizations.of(context)!.enableNotificationsForReplies,
            style: TextStyle(
              color: Theme.of(context).colorScheme.inverseSurface,
              fontSize: 14,
            ),
          ),
          // Only show the hint message if permissions were explicitly denied
          if (notificationsDenied)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                AppLocalizations.of(context)!.notificationsDeniedInSettings,
                style: TextStyle(
                  color: Colors.orangeAccent, // hard coded color
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
