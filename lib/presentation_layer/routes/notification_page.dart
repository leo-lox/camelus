import 'package:camelus/l10n/app_localizations.dart';
import 'package:camelus/presentation_layer/routing/route_paths.dart';
import 'package:camelus/presentation_layer/atoms/my_profile_picture.dart';
import 'package:camelus/presentation_layer/atoms/refresh_indicator_no_need.dart';
import 'package:camelus/presentation_layer/components/note_card/note_card.dart';
import 'package:camelus/presentation_layer/components/note_card/skeleton_note.dart';
import 'package:camelus/presentation_layer/providers/get_notes_provider.dart';
import 'package:camelus/presentation_layer/providers/metadata_state_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_list_view/flutter_list_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../providers/notification_settings_provider.dart';
import '../components/note_card/no_more_notes.dart';
import '../components/note_card/nostr_parser.dart';
import '../providers/ndk_provider.dart';
import '../providers/notification_feed_provider.dart';

class NotificationPage extends ConsumerStatefulWidget {
  const NotificationPage({super.key});

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
    final currentUserPubkey = ref.read(ndkProvider).accounts.getPublicKey();

    // If not logged in, show a message to login
    if (currentUserPubkey == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            AppLocalizations.of(context)!.notifications,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                PhosphorIcons.userCircle,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              SizedBox(height: 16),
              Text(
                'Please login to view notifications',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.push('/onboarding'),
                child: Text('Login'),
              ),
            ],
          ),
        ),
      );
    }

    final notificationsState = ref.watch(
      notificationsStateProvider(currentUserPubkey),
    );

    // Combine both lists for display, with new notifications at the top
    final allNotifications = [
      ...notificationsState.newNotifications,
      ...notificationsState.timelineNotifications,
    ];

    // Filter mentions-only notifications
    final mentionNotifications = allNotifications
        .where(
          (notification) => notification.type == NotificationTypeFeed.mention,
        )
        .toList();

    final notificationSettings = ref.watch(notificationSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.notifications,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        elevation: 0,
        actions: [
          if (notificationsState.newNotifications.isNotEmpty)
            IconButton(
              icon: Icon(
                Icons.check_circle_outline,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              onPressed: () {
                // Mark all notifications as read
                ref
                    .read(
                      notificationsStateProvider(currentUserPubkey).notifier,
                    )
                    .integrateNewNotifications();
              },
            ),
          if (!kIsWeb &&
              (defaultTargetPlatform == TargetPlatform.windows ||
                  defaultTargetPlatform == TargetPlatform.linux ||
                  defaultTargetPlatform == TargetPlatform.macOS))
            const SizedBox(width: 154),
        ],
      ),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (notificationSettings.platformSupported &&
              !notificationSettings.notificationsEnabled)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ElevatedButton(
                    onPressed: notificationSettings.isLoading
                        ? null
                        : () => ref
                              .read(notificationSettingsProvider.notifier)
                              .requestPermission(),
                    child: Text(
                      AppLocalizations.of(
                        context,
                      )!.enableNotificationsForReplies,
                    ),
                  ),
                  if (notificationSettings.permissionRequested &&
                      notificationSettings.notificationsDenied)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        AppLocalizations.of(
                          context,
                        )!.notificationsDeniedInSettings,
                        style: TextStyle(
                          color: Colors.orangeAccent,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          TabBar(
            controller: _tabController,
            overlayColor: WidgetStateProperty.all(Colors.transparent),
            splashFactory: NoSplash.splashFactory,
            labelColor: Theme.of(context).colorScheme.onSurface,
            unselectedLabelColor: Theme.of(
              context,
            ).colorScheme.onSurfaceVariant,
            indicatorColor: Theme.of(context).colorScheme.primary,
            tabs: [
              Tab(text: AppLocalizations.of(context)!.all),
              Tab(text: AppLocalizations.of(context)!.mentions),
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
                    context,
                    ref,
                    allNotifications,
                    notificationsState,
                    currentUserPubkey,
                  ),
                ),

                // Mentions tab
                RefreshIndicatorNoNeed(
                  onRefresh: () async {
                    await Future.delayed(Duration.zero);
                  },
                  child: _buildNotificationList(
                    context,
                    ref,
                    mentionNotifications,
                    notificationsState,
                    currentUserPubkey,
                  ),
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
          Icon(
            Icons.notifications_off,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            size: 48,
          ),
          SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.whenSomeoneInteractsWithYourPosts,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationList(
    BuildContext context,
    WidgetRef ref,
    List<NostrNotification> notifications,
    NotificationViewModel state,
    String pubkey,
  ) {
    if (notifications.isEmpty && state.endOfNotifications) {
      return _buildEmptyState(AppLocalizations.of(context)!.noNotifications);
    }

    return FlutterListView(
      delegate: FlutterListViewDelegate((BuildContext context, int index) {
        // Handle the loading indicator at the end
        if (index == notifications.length) {
          if (state.endOfNotifications) {
            return NoMoreNotes(
              text: AppLocalizations.of(context)!.endOfNotifications,
            );
          }
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Center(
              child: SkeletonNote(
                hideBottomAction: true,
                renderCallback: () {
                  ref
                      .read(notificationsStateProvider(pubkey).notifier)
                      .loadMore();
                },
              ),
            ),
          );
        }

        // Get the notification
        final notification = notifications[index];

        // Check if this is a new notification
        final isNew = state.newNotifications.contains(notification);

        return _buildNotificationItem(context, notification, isNew, ref);
      }, childCount: notifications.length + 1),
    );
  }

  Widget _buildNotificationItem(
    BuildContext context,
    NostrNotification notification,
    bool isNew,
    WidgetRef ref,
  ) {
    final reactingUser = ref.watch(
      metadataStateProvider(notification.sourceNote.pubkey),
    );

    // Create a container with a highlight color if it's a new notification
    return Container(
      color: isNew
          ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
          : null,
      child: ListTile(
        leading: _getNotificationIcon(notification),
        title: Row(
          children: [
            if (notification.type == NotificationTypeFeed.reaction)
              UserImage(
                size: 23,
                imageUrl: reactingUser.userMetadata?.picture,
                pubkey: notification.sourceNote.pubkey,
              ),
            const SizedBox(width: 10),
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
                    TextSpan(text: ' '),
                    TextSpan(
                      text: _getNotificationText(notification),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Text(
              timeago.format(
                DateTime.fromMillisecondsSinceEpoch(
                  notification.createdAt * 1000,
                ),
              ), // TODO translate
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
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
    final l10n = AppLocalizations.of(context)!;
    switch (notification.type) {
      case NotificationTypeFeed.reaction:
        return l10n.reactedToYourPost;
      case NotificationTypeFeed.reply:
        return l10n.repliedToYourPost;
      case NotificationTypeFeed.threadReply:
        return l10n.mentionedYouInThread;
      case NotificationTypeFeed.repost:
        return l10n.repostedYourPost;
      case NotificationTypeFeed.mention:
        return l10n.mentionedYou;
      default:
        return l10n.interactedWithYourPost;
    }
  }

  Widget _getNotificationIcon(NostrNotification notification) {
    IconData icon;
    Color iconColor;

    switch (notification.type) {
      case NotificationTypeFeed.reaction:
        if (notification.sourceNote.content == '+') {
          icon = PhosphorIcons.heartBold;
          iconColor = Theme.of(context).colorScheme.error;
        } else {
          return Text(
            notification.sourceNote.content,
            style: TextStyle(fontSize: 20),
          );
        }

      case NotificationTypeFeed.reply:
        icon = PhosphorIcons.arrowBendUpLeft;
        iconColor = Theme.of(context).colorScheme.primary;
        break;

      case NotificationTypeFeed.repost:
        return SvgPicture.asset(
          'assets/icons/retweet.svg',
          height: 18,
          colorFilter: ColorFilter.mode(
            Color.fromARGB(255, 22, 163, 74),
            BlendMode.srcATop,
          ),
        );
      case NotificationTypeFeed.mention:
        icon = PhosphorIcons.at;
        iconColor = Colors.orange;
        break;
      default:
        icon = PhosphorIcons.question;
        iconColor = Theme.of(context).colorScheme.primary;
        break;
    }

    return Icon(icon, size: 23, color: iconColor);
  }

  // Build the content preview based on notification type
  Widget _buildNotificationContent(
    NostrNotification notification,
    WidgetRef ref,
  ) {
    final parsedSourceNote = NostrParser.parseEventSync(
      notification.sourceNote,
    );

    switch (notification.type) {
      case NotificationTypeFeed.reaction:
        //return Container();
        break;
      case NotificationTypeFeed.reply:
        final mentionUser = ref.watch(
          metadataStateProvider(notification.sourceNote.pubkey),
        );
        return NoteCard(
          note: parsedSourceNote,
          myMetadata: mentionUser.userMetadata,
          hideBottomBar: true,
        );

      case NotificationTypeFeed.threadReply:
        final mentionUser = ref.watch(
          metadataStateProvider(notification.sourceNote.pubkey),
        );
        return NoteCard(
          note: parsedSourceNote,
          myMetadata: mentionUser.userMetadata,
          hideBottomBar: true,
        );

      case NotificationTypeFeed.repost:
        break;
      case NotificationTypeFeed.mention:
        final mentionUser = ref.watch(
          metadataStateProvider(notification.sourceNote.pubkey),
        );
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
      final note = ref
          .watch(getNotesProvider)
          .getNote(notification.targetNoteId!);

      return FutureBuilder(
        future: note.first,
        builder: (context, data) {
          if (data.hasData && data.data != null) {
            final noteUserMetadata = ref.watch(
              metadataStateProvider(data.data!.pubkey),
            );
            return NoteCard(
              note: NostrParser.parseEventSync(data.data!),
              myMetadata: noteUserMetadata.userMetadata,
              hideBottomBar: true,
            );
          }
          return SkeletonNote(hideBottomAction: true);
        },
      );
    }

    return Container();
  }

  void _navigateToPost(BuildContext context, NostrNotification notification) {
    final rootId =
        notification.sourceNote.getRootReply?.value ??
        notification.targetNoteId ??
        notification.sourceNote.id;

    context.push(
      RoutePaths.status(
        pubkey: notification.sourceNote.pubkey,
        eventId: rootId,
        scrollIntoView: notification.sourceNote.id,
      ),
    );
  }
}
