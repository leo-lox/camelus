abstract class NotificationsRepository {
  Future<List<Map<String, dynamic>>> registerDevice();
  Future<void> displayGenericNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  });

  Future<void> displayAvatarNotification({
    required int id,
    required String title,
    required String body,
    required String avatarUrl,
    required String pubkey,

    /// e.g. New Message
    required String type,
    String? threadIdentifier,
    String? payload,
  });
}
