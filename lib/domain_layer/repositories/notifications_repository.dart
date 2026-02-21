import '../../lifecycle/notifications/notification_types.dart';
import '../entities/nostr_note.dart';

abstract class NotificationsRepository {
  Future<bool> registerDevice({
    required String token,
    required NostrNote registrationNote,
  });
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
    required NotificationTypeLocal type,
    String? threadIdentifier,
    String? payload,
  });

  Future<void> deleteNotification(int id);
}
