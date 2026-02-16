import 'package:firebase_messaging/firebase_messaging.dart';

import 'background_notifications_handler_stub.dart'
    if (dart.library.io) 'background_notifications_handler_io.dart'
    if (dart.library.js_interop) 'background_notifications_handler_web.dart'
    as impl;

BackgroundMessageHandler? get firebaseBackgroundHandler =>
    impl.firebaseBackgroundHandler;
