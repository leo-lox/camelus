import 'package:firebase_messaging/firebase_messaging.dart';

import 'background_notifications_thread.dart';

BackgroundMessageHandler? get firebaseBackgroundHandler =>
    firebaseMessagingBackgroundHandler;
