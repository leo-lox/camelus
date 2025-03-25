abstract class NotificationsRepository {
  Future<List<Map<String, dynamic>>> registerDevice();
  Future<void> displayNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  });
}
