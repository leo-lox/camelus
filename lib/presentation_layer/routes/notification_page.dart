import 'dart:io';

import 'package:camelus/presentation_layer/atoms/my_profile_picture.dart';
import 'package:camelus/presentation_layer/atoms/refresh_indicator_no_need.dart';
import 'package:camelus/presentation_layer/components/note_card/note_card.dart';
import 'package:camelus/presentation_layer/components/note_card/skeleton_note.dart';
import 'package:camelus/presentation_layer/providers/get_notes_provider.dart';
import 'package:camelus/presentation_layer/providers/metadata_state_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_list_view/flutter_list_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../config/palette.dart';

import '../components/enable_notifications.dart';
import '../components/note_card/no_more_notes.dart';
import '../components/note_card/nostr_parser.dart';
import '../providers/notification_feed_provider.dart';

class NotificationPage extends ConsumerStatefulWidget {
  final String pubkey;
  const NotificationPage({
    super.key,
    required this.pubkey,
  });

  @override
  ConsumerState<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends ConsumerState<NotificationPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notificationsState =
        ref.watch(notificationsStateProvider(widget.pubkey));

    // Combine both lists for display, with new notifications at the top
    final allNotifications = [
      ...notificationsState.newNotifications,
      ...notificationsState.timelineNotifications,
    ];

    // Filter mentions-only notifications
    final mentionNotifications = allNotifications
        .where((notification) => notification.type == NotificationType.mention)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title:
            Text('Notifications', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
        elevation: 0,
        actions: [
          if (notificationsState.newNotifications.isNotEmpty)
            IconButton(
              icon: Icon(Icons.check_circle_outline, color: Theme.of(context).colorScheme.onSurface),
              onPressed: () {
                // Mark all notifications as read
                ref
                    .read(notificationsStateProvider(widget.pubkey).notifier)
                    .integrateNewNotifications();
              },
            ),
          if (Platform.isWindows || Platform.isLinux || Platform.isMacOS)
            const SizedBox(width: 154),
        ],
      ),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PushNotificationToggle(),
          TabBar(
            controller: _tabController,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Paletter.getPrimary(context),
            tabs: const [
              Tab(text: "All"),
              Tab(text: "Mentions"),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // All notifications tab
                RefreshIndicatorNoNeed(
                  onRefresh: () async {
                    await Future.delayed(Duration.zero);
                  },
                  child: _buildNotificationList(
                      context, ref, allNotifications, notificationsState),
                ),

                // Mentions tab
                RefreshIndicatorNoNeed(
                  onRefresh: () async {
                    await Future.delayed(Duration.zero);
                  },
                  child: _buildNotificationList(
                      context, ref, mentionNotifications, notificationsState),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off, color: Theme.of(context).colorScheme.onSurfaceVariant, size: 48),
          SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 16),
          ),
          SizedBox(height: 8),
          Text(
            'When someone interacts with your posts,\nyou\'ll see it here',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationList(BuildContext context, WidgetRef ref,
      List<NostrNotification> notifications, NotificationViewModel state) {
    if (notifications.isEmpty && state.endOfNotifications) {
      return _buildEmptyState("no notifications");
    }

    return FlutterListView(
        delegate: FlutterListViewDelegate(
      (BuildContext context, int index) {
        // Handle the loading indicator at the end
        if (index == notifications.length) {
          if (state.endOfNotifications) {
            return NoMoreNotes(
              text: "end of notifications",
            );
          }
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Center(
                child: SkeletonNote(
              hideBottomAction: true,
              renderCallback: () {
                ref
                    .read(notificationsStateProvider(widget.pubkey).notifier)
                    .loadMore();
              },
            )),
          );
        }

        // Get the notification
        final notification = notifications[index];

        // Check if this is a new notification
        final isNew = state.newNotifications.contains(notification);

        return _buildNotificationItem(context, notification, isNew, ref);
      },
      childCount: notifications.length + 1,
    ));
  }

  Widget _buildNotificationItem(BuildContext context,
      NostrNotification notification, bool isNew, WidgetRef ref) {
    final reactingUser =
        ref.watch(metadataStateProvider(notification.sourceNote.pubkey));

    // Create a container with a highlight color if it's a new notification
    return Container(
      color: isNew ? Paletter.getPrimary(context).withValues(alpha: 0.1) : null,
      child: ListTile(
        leading: _getNotificationIcon(notification),
        title: Row(
          children: [
            if (notification.type == NotificationType.reaction)
              UserImage(
                size: 23,
                imageUrl: reactingUser.userMetadata?.picture,
                pubkey: notification.sourceNote.pubkey,
              ),
            const SizedBox(
              width: 10,
            ),
            Expanded(
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: reactingUser.userMetadata?.name ?? '',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    TextSpan(
                      text: ' ',
                    ),
                    TextSpan(
                      text: _getNotificationText(notification),
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                    ),
                  ],
                ),
              ),
            ),
            Text(
              timeago.format(DateTime.fromMillisecondsSinceEpoch(
                  notification.createdAt * 1000)),
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12),
            ),
          ],
        ),
        subtitle: _buildNotificationContent(notification, ref),
        onTap: () {
          // Navigate to the relevant post when tapped
          _navigateToPost(context, notification);
        },
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  // Get appropriate text based on notification type
  String _getNotificationText(NostrNotification notification) {
    switch (notification.type) {
      case NotificationType.reaction:
        return "reacted to your post";
      case NotificationType.reply:
        return "replied to your post";
      case NotificationType.threadReply:
        return "mentiend you in a thread";
      case NotificationType.repost:
        return "reposted your post";
      case NotificationType.mention:
        return "mentioned you";
      default:
        return "interacted with your post";
    }
  }

  Widget _getNotificationIcon(NostrNotification notification) {
    IconData icon;
    Color iconColor;

    switch (notification.type) {
      case NotificationType.reaction:
        if (notification.sourceNote.content == '+') {
          icon = PhosphorIcons.heart(PhosphorIconsStyle.bold);
          iconColor = Theme.of(context).colorScheme.error;
        } else {
          return Text(
            notification.sourceNote.content,
            style: TextStyle(fontSize: 20),
          );
        }

      case NotificationType.reply:
        icon = PhosphorIcons.arrowBendUpLeft();
        iconColor = Paletter.getPrimary(context);
        break;

      case NotificationType.repost:
        return SvgPicture.asset(
          'assets/icons/retweet.svg',
          height: 18,
          colorFilter: ColorFilter.mode(
            Paletter.getRepostActive(context),
            BlendMode.srcATop,
          ),
        );
      case NotificationType.mention:
        icon = PhosphorIcons.at();
        iconColor = Colors.orange;
        break;
      default:
        icon = PhosphorIcons.question();
        iconColor = Paletter.getPrimary(context);
        break;
    }

    return Icon(icon, size: 23, color: iconColor);
  }

  // Build the content preview based on notification type
  Widget _buildNotificationContent(
      NostrNotification notification, WidgetRef ref) {
    final parsedSourceNote =
        NostrParser.parseEventSync(notification.sourceNote);

    switch (notification.type) {
      case NotificationType.reaction:
        //return Container();
        break;
      case NotificationType.reply:
        final mentionUser =
            ref.watch(metadataStateProvider(notification.sourceNote.pubkey));
        return NoteCard(
          note: parsedSourceNote,
          myMetadata: mentionUser.userMetadata,
          hideBottomBar: true,
        );

      case NotificationType.threadReply:
        final mentionUser =
            ref.watch(metadataStateProvider(notification.sourceNote.pubkey));
        return NoteCard(
          note: parsedSourceNote,
          myMetadata: mentionUser.userMetadata,
          hideBottomBar: true,
        );

      case NotificationType.repost:
        break;
      case NotificationType.mention:
        final mentionUser =
            ref.watch(metadataStateProvider(notification.sourceNote.pubkey));
        return NoteCard(
          note: parsedSourceNote,
          myMetadata: mentionUser.userMetadata,
          hideBottomBar: true,
        );
      default:
        return Container();
    }
    if (notification.targetNoteId != null &&
        notification.targetNoteId!.isNotEmpty) {
      final note =
          ref.watch(getNotesProvider).getNote(notification.targetNoteId!);

      return FutureBuilder(
          future: note.first,
          builder: (context, data) {
            if (data.hasData && data.data != null) {
              final noteUserMetadata =
                  ref.watch(metadataStateProvider(data.data!.pubkey));
              return NoteCard(
                note: NostrParser.parseEventSync(data.data!),
                myMetadata: noteUserMetadata.userMetadata,
                hideBottomBar: true,
              );
            }
            return SkeletonNote(
              hideBottomAction: true,
            );
          });
    }

    return Container();
  }

  void _navigateToPost(BuildContext context, NostrNotification notification) {
    Navigator.pushNamed(context, "/nostr/event", arguments: <String, String?>{
      "root": notification.sourceNote.getRootReply?.value ??
          notification.targetNoteId ??
          notification.sourceNote.id,
      "scrollIntoView": notification.sourceNote.id
    });
  }
}
