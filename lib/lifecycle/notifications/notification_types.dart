import 'package:flutter_local_notifications/flutter_local_notifications.dart';

enum NotificationTypeLocal {
  chatMessage(
    channelId: 'chat_messages',
    channelName: 'Chat Messages',
    channelDescription: 'Notifications for direct chat messages',
    importance: Importance.high,
    priority: Priority.defaultPriority,
  ),
  groupMessage(
    channelId: 'group_messages',
    channelName: 'Group Messages',
    channelDescription: 'Notifications for group chat messages',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
  ),
  repost(
    channelId: 'repost',
    channelName: 'Repost',
    channelDescription: 'Notifications for reposts of your notes',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
  ),
  mention(
    channelId: 'repost',
    channelName: 'Repost',
    channelDescription: 'Notifications for reposts of your notes',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
  ),
  reply(
    channelId: 'reply',
    channelName: 'Reply',
    channelDescription: 'Reply to your notes',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
  ),
  reaction(
    channelId: 'reactions',
    channelName: 'Reactions',
    channelDescription: 'Notifications for reactions to posts',
    importance: Importance.low,
    priority: Priority.defaultPriority,
  ),

  other(
    channelId: 'other',
    channelName: 'Other',
    channelDescription: 'Other Nostr Notifications',
    importance: Importance.low,
    priority: Priority.defaultPriority,
  );

  const NotificationTypeLocal({
    required this.channelId,
    required this.channelName,
    required this.channelDescription,
    required this.importance,
    required this.priority,
  });

  final String channelId;
  final String channelName;
  final String channelDescription;
  final Importance importance;
  final Priority priority;
}
