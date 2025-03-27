import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';

import '../../domain_layer/entities/nostr_note.dart';

import '../../domain_layer/entities/nostr_tag.dart';
import '../../helpers/helpers.dart';
import '../../helpers/nprofile_helper.dart';
import 'db_app_provider.dart';
import 'get_notes_provider.dart';

// Provider for managing notification state
final notificationsStateProvider = NotifierProvider.autoDispose
    .family<NotificationsState, NotificationViewModel, String>(
  NotificationsState.new,
);

class NotificationsState
    extends AutoDisposeFamilyNotifier<NotificationViewModel, String> {
  static const String SUBSCRIPTION_ID = "notifications-sub";
  static const String NOTIFICATION_CUTOFF_KEY = "notifications-cutoff";

  Future<void> _resetStateDispose() async {
    final notesP = ref.watch(getNotesProvider);
    await notesP.closeSubscription(SUBSCRIPTION_ID);
    state = NotificationViewModel(
      timelineNotifications: [],
      newNotifications: [],
    );
  }

  @override
  NotificationViewModel build(String arg) {
    // Clean up when provider is disposed
    ref.onDispose(() {
      _resetStateDispose();
    });

    final userPubkey = arg;

    _setupSubscription(userPubkey);

    return NotificationViewModel(
      timelineNotifications: [],
      newNotifications: [],
    );
  }

  // Integrate new notifications into the timeline
  void integrateNewNotifications() {
    _addTimelineNotifications(state.newNotifications);

    state = state.copyWith(
      newNotifications: [],
    );
  }

  // Set up subscription for real-time notifications
  Future<void> _setupSubscription(String userPubkey) async {
    int cutoff = await _getCutoffTime();
    final notesP = ref.watch(getNotesProvider);

    final sub = notesP.genericNostrSubscription(
      since: cutoff,
      subscriptionId: SUBSCRIPTION_ID,
      kinds: [1, 7, 6], // Text notes, reactions, reposts
      pTags: [userPubkey], // Notes mentioning the user
    );

    sub
        .bufferTime(const Duration(seconds: 1))
        .where((events) => events.isNotEmpty)
        .listen(_processNewNotifications);
  }

  // Process incoming notifications
  Future<void> _processNewNotifications(List<NostrNote> notes) async {
    final userPubkey = arg;

    // Filter notes that are interactions with the user's content
    // and convert them to notification objects
    final notifications = _convertToNotifications(notes, userPubkey);

    if (notifications.isNotEmpty) {
      _addNewNotifications(notifications);
    }
  }

  // Helper to convert notes to notification objects
  List<NostrNotification> _convertToNotifications(
      List<NostrNote> notes, String userPubkey) {
    return notes.map((note) {
      NotificationType type;
      String? targetNoteId;

      final List<String> foundPubkeysContent = [];
      final exp = RegExp(
        r'nostr:(nprofile|npub)[a-zA-Z0-9]+',
        caseSensitive: false,
      );
      final List<String> foundProfiles =
          exp.allMatches(note.content).map((match) => match.group(0)!).toList();

      for (var profile in foundProfiles) {
        profile = profile.replaceFirst('nostr:', '');
        final String pubkey;
        if (profile.startsWith('nprofile')) {
          final decoded = NprofileHelper().bech32toMap(profile);
          pubkey = decoded['pubkey'] ?? '';
          foundPubkeysContent.add(pubkey);
        } else if (profile.startsWith('npub')) {
          final decoded = Helpers().decodeBech32(profile);
          pubkey = decoded[0] ?? '';
          foundPubkeysContent.add(pubkey);
        }
      }

      if (note.kind == 7) {
        type = NotificationType.reaction;
        targetNoteId = note.tags
            .firstWhere(
              (tag) => tag.type == 'e',
            )
            .value;
      } else if (note.kind == 6) {
        type = NotificationType.repost;
        targetNoteId = note.tags
            .firstWhere(
              (tag) => tag.type == 'e',
            )
            .value;
      } else if (foundPubkeysContent.contains(userPubkey)) {
        type = NotificationType.mention;
      } else if (note.getTagPubkeys.last.value == userPubkey) {
        /// find note id of reply
        for (final tag in note.tags) {
          if (tag.type == 'e' && tag.marker == 'reply') {
            targetNoteId = tag.value;
            break;
          }
        }
        type = NotificationType.reply;
      } else if (note.getTagPubkeys
          .where((t) => t.value == userPubkey)
          .isNotEmpty) {
        type = NotificationType.threadReply;
      } else {
        log(note.toString());
        type = NotificationType.unknown;
      }

      return NostrNotification(
        id: note.id,
        createdAt: note.created_at,
        type: type,
        sourceNote: note,
        targetNoteId: targetNoteId,
      );
    }).toList();
  }

  // Get the cutoff time for notifications
  Future<int> _getCutoffTime() async {
    final appDbP = ref.read(dbAppProvider);
    final lastFetch = await appDbP.read(NOTIFICATION_CUTOFF_KEY);
    return lastFetch != null
        ? int.parse(lastFetch)
        : DateTime.now().millisecondsSinceEpoch ~/ 1000;
  }

  // Save the current time as cutoff
  Future<void> _saveCutoffTime() async {
    final appDbP = ref.read(dbAppProvider);
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await appDbP.save(key: NOTIFICATION_CUTOFF_KEY, value: now.toString());
  }

  // Load more older notifications
  Future<void> loadMore() async {
    int cutoff = await _getCutoffTime();
    await _saveCutoffTime();

    if (state.timelineNotifications.isNotEmpty) {
      cutoff = state.timelineNotifications.last.createdAt - 1;
    }

    final userPubkey = arg;

    final notesP = ref.watch(getNotesProvider);
    final notesStream = notesP.genericNostrQuery(
      requestId: "notifications-query",
      kinds: [1, 7, 6], // Text notes, reactions, reposts
      pTags: [userPubkey],
      limit: 10,
      until: cutoff,
    );

    // process notes
    notesStream
        .bufferTime(const Duration(milliseconds: 100))
        .where((events) => events.isNotEmpty)
        .listen((data) {
      final notifications = _convertToNotifications(data, userPubkey);
      _addTimelineNotifications(notifications);
    });

    final notes = await notesStream.toList();
    if (notes.isEmpty) {
      state = state.copyWith(endOfNotifications: true);
      return;
    }
  }

  // Add notifications to the timeline
  void _addTimelineNotifications(List<NostrNotification> notifications) {
    notifications = notifications.where((notification) {
      return !state.timelineNotifications
          .any((element) => element.id == notification.id);
    }).toList();

    state = state.copyWith(
        timelineNotifications: [
      ...state.timelineNotifications,
      ...notifications
    ]..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
  }

  // Add new notifications
  void _addNewNotifications(List<NostrNotification> notifications) {
    state = state.copyWith(
        newNotifications: [...state.newNotifications, ...notifications]
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
  }
}

// In notification_view_model.dart
class NotificationViewModel {
  final List<NostrNotification> timelineNotifications;
  final List<NostrNotification> newNotifications;
  final bool endOfNotifications;

  NotificationViewModel({
    required this.timelineNotifications,
    required this.newNotifications,
    this.endOfNotifications = false,
  });

  NotificationViewModel copyWith({
    List<NostrNotification>? timelineNotifications,
    List<NostrNotification>? newNotifications,
    bool? endOfNotifications,
  }) {
    return NotificationViewModel(
      timelineNotifications:
          timelineNotifications ?? this.timelineNotifications,
      newNotifications: newNotifications ?? this.newNotifications,
      endOfNotifications: endOfNotifications ?? this.endOfNotifications,
    );
  }
}

enum NotificationType { reaction, reply, threadReply, repost, mention, unknown }

class NostrNotification {
  final String id;
  final int createdAt;
  final NotificationType type;
  final NostrNote sourceNote;
  final String? targetNoteId; // ID of user's note that was interacted with

  NostrNotification({
    required this.id,
    required this.createdAt,
    required this.type,
    required this.sourceNote,
    this.targetNoteId,
  });
}
