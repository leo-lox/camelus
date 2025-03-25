import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../data_layer/data_sources/http_request_data_source.dart';
import '../../data_layer/data_sources/notification_data_source.dart';
import '../../data_layer/repositories/notifications/notifications_repository_impl.dart';
import '../../domain_layer/repositories/notifications_repository.dart';
import '../../domain_layer/usecases/notifications.dart';

final notificationsProvider = FutureProvider<Notifications>((ref) async {
  final notiDs = NotificationDataSource();
  await notiDs.initializeNotifications();

  final http.Client client = http.Client();
  final httpDs = HttpRequestDataSource(client);

  final NotificationsRepository notiRepo = NotificationsRepositoryImpl(
    http: httpDs,
    notiDs: notiDs,
  );
  final Notifications notifications = Notifications(
    notificationsRepository: notiRepo,
  );

  // set NotificationTab callback
  notiDs.onNotificationTap = notifications.onNotificationTap;

  return notifications;
});
