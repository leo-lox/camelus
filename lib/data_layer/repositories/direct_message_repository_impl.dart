import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:ndk/ndk.dart';

import '../../domain_layer/entities/direct_message.dart';
import '../../domain_layer/usecases/inbox_outbox.dart';
import '../models/nostr_tag_model.dart';
import '../../domain_layer/entities/dm_conversation.dart';
import '../../domain_layer/repositories/direct_message_repository.dart';
import '../../objectbox.g.dart';
import '../db/object_box_camelus/schema/db_nip17_conversation.dart';
import '../db/object_box_camelus/schema/db_nip17_message.dart';
import '../models/direct_message_model.dart';

/// Implementation of [DirectMessageRepository] using NDK and ObjectBox.
///
/// This handles NIP-17 private direct messages:
/// - Kind 14: Chat message (rumor, unsigned)
/// - Kind 13: Seal (encrypted with NIP-44)
/// - Kind 1059: Gift wrap (final envelope)
class DirectMessageRepositoryImpl implements DirectMessageRepository {
  final Ndk ndk;
  final Future<Store> Function() getStore;
  final String myPubkey;
  final InboxOutbox inboxOutbox;

  // Subscription for real-time messages
  NdkResponse? _dmSubscription;
  final StreamController<DirectMessage> _newMessageController =
      StreamController<DirectMessage>.broadcast();

  // StreamControllers for manual updates
  final StreamController<List<DmConversation>> _conversationsController =
      StreamController<List<DmConversation>>.broadcast();
  final Map<String, StreamController<List<DirectMessage>>>
  _messagesControllers = {};
  final StreamController<int> _unreadCountController =
      StreamController<int>.broadcast();

  /// Tracks per-peer whether we have loaded all history.
  /// The global ndk.fetchedRanges cannot distinguish between peers, so we
  /// maintain our own set. Resets on app restart (acceptable — a single extra
  /// "Load more" tap is the worst case).
  final Set<String> _peersWithBeginningReached = {};

  DirectMessageRepositoryImpl({
    required this.ndk,
    required this.getStore,
    required this.myPubkey,
    required this.inboxOutbox,
  });

  // ============ DM Relay Discovery ============

  /// Get DM inbox relays for a pubkey.
  /// First tries kind 10050 (DM-specific relays), then falls back to NIP-65 inbox relays.
  /// Reads from cache first for speed, refreshes cache in background.
  Future<List<String>> _getDmInboxRelays(String pubkey) async {
    // Try cache first (fast)
    final cachedRelays = await _getDmRelays(pubkey);
    if (cachedRelays.isNotEmpty) {
      log('DM: Using cached relays for $pubkey: $cachedRelays');

      return cachedRelays;
    }

    final nip65Relays = await _getNip65InboxRelays(pubkey, forceRefresh: true);
    if (nip65Relays.isNotEmpty) {
      log('DM: Using NIP-65 inbox relays for $pubkey: $nip65Relays');
      return nip65Relays;
    }

    log('DM: No DM relays found for $pubkey, using default relays');
    return [];
  }

  /// Get DM relays via InboxOutbox (kind 10050).
  Future<List<String>> _getDmRelays(
    String pubkey, {
    bool forceRefresh = false,
  }) async {
    try {
      if (pubkey == myPubkey) {
        return (await inboxOutbox.getDmRelaysSelf(
          forceRefresh: forceRefresh,
        )).relays;
      }

      return (await inboxOutbox.getDmRelays(
        pubkey: pubkey,
        forceRefresh: forceRefresh,
      )).relays;
    } catch (e) {
      log('DM: Error getting DM relays via InboxOutbox for $pubkey: $e');
      return [];
    }
  }

  /// Get NIP-65 inbox relays (read-capable relays) for a pubkey.
  Future<List<String>> _getNip65InboxRelays(
    String pubkey, {
    bool forceRefresh = false,
  }) async {
    try {
      final nip65 = await inboxOutbox.getNip65data(
        pubkey,
        forceRefresh: forceRefresh,
      );
      if (nip65 == null) {
        return [];
      }

      // Get relays marked for reading (inbox)
      return nip65.relays.entries
          .where((entry) => entry.value.isRead)
          .map((entry) => entry.key)
          .toList();
    } catch (e) {
      log('DM: Error fetching NIP-65 for $pubkey: $e');
      return [];
    }
  }

  // ============ Conversations ============

  @override
  Stream<List<DmConversation>> watchConversations() async* {
    // Emit initial data
    yield await _getConversationsFromDb();

    // Listen for updates
    yield* _conversationsController.stream;
  }

  Future<List<DmConversation>> _getConversationsFromDb() async {
    final store = await getStore();
    final convBox = store.box<DbNip17Conversation>();
    final messageBox = store.box<DbNip17Message>();

    // Filter by ownerPubkey to only show conversations for the current user
    final query = convBox
        .query(DbNip17Conversation_.ownerPubkey.equals(myPubkey))
        .order(DbNip17Conversation_.lastMessageAt, flags: Order.descending)
        .build();

    final conversations = query.find();
    query.close();

    return conversations
        .map((db) => _dbConversationToEntity(db, messageBox))
        .toList();
  }

  DmConversation _dbConversationToEntity(
    DbNip17Conversation db,
    Box<DbNip17Message> messageBox,
  ) {
    // Filter by both ownerPubkey and peerPubkey
    final msgQuery = messageBox
        .query(
          DbNip17Message_.ownerPubkey.equals(myPubkey) &
              DbNip17Message_.peerPubkey.equals(db.peerPubkey),
        )
        .order(DbNip17Message_.createdAt, flags: Order.descending)
        .build();
    final lastMessageDb = msgQuery.findFirst();
    msgQuery.close();

    return DmConversation(
      peerPubkey: db.peerPubkey,
      lastMessageAt: db.lastMessageAt,
      unreadCount: db.unreadCount,
      lastMessagePreview: db.lastMessagePreview,
      lastMessageIsOutgoing: db.lastMessageIsOutgoing,
      lastMessage: lastMessageDb != null
          ? DirectMessageModel.fromDb(lastMessageDb)
          : null,
    );
  }

  void _notifyConversationsChanged() async {
    final conversations = await _getConversationsFromDb();
    _conversationsController.add(conversations);
    _notifyUnreadCountChanged();
  }

  @override
  Future<DmConversation?> getConversation(String peerPubkey) async {
    final store = await getStore();
    final convBox = store.box<DbNip17Conversation>();
    final messageBox = store.box<DbNip17Message>();

    // Filter by ownerPubkey to only get conversation for the current user
    final query = convBox
        .query(
          DbNip17Conversation_.ownerPubkey.equals(myPubkey) &
              DbNip17Conversation_.peerPubkey.equals(peerPubkey),
        )
        .build();
    final db = query.findFirst();
    query.close();

    if (db == null) return null;

    return _dbConversationToEntity(db, messageBox);
  }

  @override
  Future<void> markConversationAsRead(String peerPubkey) async {
    final store = await getStore();
    final box = store.box<DbNip17Conversation>();

    store.runInTransaction(TxMode.write, () {
      // Filter by ownerPubkey to only update conversation for the current user
      final query = box
          .query(
            DbNip17Conversation_.ownerPubkey.equals(myPubkey) &
                DbNip17Conversation_.peerPubkey.equals(peerPubkey),
          )
          .build();
      final db = query.findFirst();
      query.close();

      if (db != null) {
        db.unreadCount = 0;
        box.put(db);
      }
    });

    _notifyConversationsChanged();
  }

  @override
  Stream<int> watchTotalUnreadCount() async* {
    // Emit initial count
    yield await _getTotalUnreadCount();

    // Listen for updates
    yield* _unreadCountController.stream;
  }

  Future<int> _getTotalUnreadCount() async {
    final store = await getStore();
    final box = store.box<DbNip17Conversation>();

    // Filter by ownerPubkey to only count unread for the current user
    final query = box
        .query(DbNip17Conversation_.ownerPubkey.equals(myPubkey))
        .build();
    final conversations = query.find();
    query.close();

    return conversations.fold<int>(0, (sum, c) => sum + c.unreadCount);
  }

  void _notifyUnreadCountChanged() async {
    final count = await _getTotalUnreadCount();
    _unreadCountController.add(count);
  }

  // ============ Messages ============

  @override
  Stream<List<DirectMessage>> watchMessages(String peerPubkey) async* {
    // Emit initial data
    yield await _getMessagesFromDb(peerPubkey);

    // Get or create controller for this peer
    _messagesControllers[peerPubkey] ??=
        StreamController<List<DirectMessage>>.broadcast();

    // Listen for updates
    yield* _messagesControllers[peerPubkey]!.stream;
  }

  Future<List<DirectMessage>> _getMessagesFromDb(String peerPubkey) async {
    final store = await getStore();
    final box = store.box<DbNip17Message>();

    // Filter by ownerPubkey to only get messages for the current user
    final query = box
        .query(
          DbNip17Message_.ownerPubkey.equals(myPubkey) &
              DbNip17Message_.peerPubkey.equals(peerPubkey),
        )
        .order(DbNip17Message_.createdAt)
        .build();

    final messages = query.find();
    query.close();

    return messages.map((db) => DirectMessageModel.fromDb(db)).toList();
  }

  void _notifyMessagesChanged(String peerPubkey) async {
    final controller = _messagesControllers[peerPubkey];
    if (controller != null) {
      final messages = await _getMessagesFromDb(peerPubkey);
      controller.add(messages);
    }
  }

  /// Push an in-memory update for a single message to the UI without persisting
  /// the transient fields (e.g. relay progress) to the database.
  void _notifyMessageUpdate(String peerPubkey, DirectMessage updatedMsg) async {
    final controller = _messagesControllers[peerPubkey];
    if (controller == null) return;
    final messages = await _getMessagesFromDb(peerPubkey);
    // Replace the matching message with the in-memory (transient) version
    final merged = messages
        .map<DirectMessage>((m) => m.id == updatedMsg.id ? updatedMsg : m)
        .toList();
    controller.add(merged);
  }

  @override
  Future<void> fetchMessages({int? since, int? until}) async {
    // Default: fetch last 30 days if not specified
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final effectiveSince = since ?? (now - (30 * 24 * 60 * 60));
    final effectiveUntil = until ?? now;

    // Get DM inbox relays for current user
    final dmRelays = await _getDmInboxRelays(myPubkey);

    // Base filter for gap detection
    final baseFilter = Filter(kinds: [1059], pTags: [myPubkey]);

    // Check if we have any ranges recorded
    final existingRanges = await ndk.fetchedRanges.getForFilter(baseFilter);

    if (existingRanges.isEmpty) {
      // First fetch - no ranges recorded yet, fetch directly
      log('DM: First fetch - no existing ranges');
      await _fetchRange(
        since: effectiveSince,
        until: effectiveUntil,
        dmRelays: dmRelays,
      );
      return;
    }

    // Find gaps in the requested range
    final gaps = await ndk.fetchedRanges.findGaps(
      filter: baseFilter,
      since: effectiveSince,
      until: effectiveUntil,
    );

    if (gaps.isEmpty) {
      log('DM: No gaps to fetch in range $effectiveSince - $effectiveUntil');
      return;
    }

    log('DM: Found ${gaps.length} gap(s) to fetch');

    // Fetch each gap
    for (final gap in gaps) {
      await _fetchRange(since: gap.since, until: gap.until, dmRelays: dmRelays);
    }
  }

  /// Internal method to fetch a specific time range
  Future<void> _fetchRange({
    required int since,
    required int until,
    required List<String> dmRelays,
  }) async {
    final filter = Filter(
      kinds: [1059], // Gift wrap
      pTags: [myPubkey],
      since: since,
      until: until,
    );

    log('DM: Fetching range $since - $until');

    final response = ndk.requests.query(
      filter: filter,
      cacheRead: false,
      cacheWrite: false,
      timeout: const Duration(seconds: 30),
      explicitRelays: dmRelays.isNotEmpty ? dmRelays : null,
    );

    int receivedCount = 0;
    int processedCount = 0;
    await for (final giftWrap in response.stream) {
      receivedCount++;
      final result = await _processGiftWrap(giftWrap, isRealTime: false);
      if (result != null) {
        processedCount++;
      }
    }

    log(
      'DM: Range fetch completed - received=$receivedCount, processed=$processedCount',
    );

    // Record the fetched range
    final dmRelaysForRange = dmRelays.isNotEmpty ? dmRelays : ['default'];
    for (final relay in dmRelaysForRange) {
      await ndk.fetchedRanges.addRange(
        filter: filter,
        relayUrl: relay,
        since: since,
        until: until,
      );
    }
  }

  @override
  Future<bool> loadOlderMessages(String peerPubkey) async {
    // Get the oldest message timestamp from local DB for the current user
    final store = await getStore();
    final box = store.box<DbNip17Message>();

    // Filter by ownerPubkey to only get messages for the current user
    final query = box
        .query(DbNip17Message_.ownerPubkey.equals(myPubkey))
        .order(DbNip17Message_.createdAt)
        .build();
    final oldestMessage = query.findFirst();
    query.close();

    if (oldestMessage == null) {
      // No messages yet, do a regular fetch
      await fetchMessages();
      return true;
    }

    // Fetch messages older than the oldest one we have
    // Go back 30 more days
    final oldestTimestamp = oldestMessage.createdAt;
    final fetchUntil = oldestTimestamp - 1; // Just before the oldest
    final fetchSince = oldestTimestamp - (30 * 24 * 60 * 60); // 30 days before

    log(
      'DM: Loading older messages before $oldestTimestamp (since=$fetchSince until=$fetchUntil)',
    );

    final previousCount = box.count();
    await fetchMessages(since: fetchSince, until: fetchUntil);
    final newCount = box.count();

    final foundNew = newCount > previousCount;
    log(
      'DM: Load older completed - found ${newCount - previousCount} new messages',
    );

    // If no new messages found, record that we've fetched from the beginning
    if (!foundNew) {
      final filter = Filter(kinds: [1059], pTags: [myPubkey]);
      final dmRelays = await _getDmInboxRelays(myPubkey);
      final relaysForRange = dmRelays.isNotEmpty ? dmRelays : ['default'];

      for (final relay in relaysForRange) {
        await ndk.fetchedRanges.addRange(
          filter: filter,
          relayUrl: relay,
          since: 0, // Mark as fetched from the beginning
          until: fetchUntil,
        );
      }
      log('DM: Recorded range from 0 (beginning) to $fetchUntil');
      // Mark this specific peer as having reached the beginning so that
      // hasReachedBeginning() returns a per-peer accurate result instead of
      // relying on the global ndk.fetchedRanges which covers all peers.
      _peersWithBeginningReached.add(peerPubkey);
    }

    return foundNew;
  }

  @override
  Future<int?> getOldestMessageTimestamp(String peerPubkey) async {
    final store = await getStore();
    final box = store.box<DbNip17Message>();

    // Filter by ownerPubkey to only get messages for the current user
    final query = box
        .query(
          DbNip17Message_.ownerPubkey.equals(myPubkey) &
              DbNip17Message_.peerPubkey.equals(peerPubkey),
        )
        .order(DbNip17Message_.createdAt)
        .build();
    final oldestMessage = query.findFirst();
    query.close();

    return oldestMessage?.createdAt;
  }

  @override
  Future<bool> hasReachedBeginning(String peerPubkey) async {
    final reached = _peersWithBeginningReached.contains(peerPubkey);
    log('DM: hasReachedBeginning($peerPubkey): $reached');
    return reached;
  }

  @override
  Stream<DirectMessage> subscribeToNewMessages() {
    _startSubscription();
    return _newMessageController.stream;
  }

  void _startSubscription() async {
    if (_dmSubscription != null) return;

    // Get DM inbox relays for current user
    final dmRelays = await _getDmInboxRelays(myPubkey);

    // Note: Gift wrap timestamps are randomized (NIP-17), so we don't use 'since'
    // to avoid filtering out new messages with past timestamps
    final filter = Filter(
      kinds: [1059], // Gift wrap
      pTags: [myPubkey],
      limit: 0, // Real-time subscription
    );

    log(
      'DM: Starting subscription on relays=${dmRelays.isNotEmpty ? dmRelays : "default"}',
    );

    _dmSubscription = ndk.requests.subscription(
      filter: filter,
      cacheRead: false,
      cacheWrite: false,
      explicitRelays: dmRelays.isNotEmpty ? dmRelays : null,
    );

    _dmSubscription!.stream.listen(
      (giftWrap) async {
        log('DM: Subscription received gift wrap id=${giftWrap.id}');
        final message = await _processGiftWrap(giftWrap, isRealTime: true);
        if (message != null) {
          log('DM: New message processed from ${message.senderPubkey}');
          _newMessageController.add(message);
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        // Log but do NOT let a stream error kill the subscription.
        // Without this handler the default cancelOnError behaviour would
        // stop all subsequent incoming messages for the session.
        log('DM: Subscription stream error (continuing): $error');
      },
    );
  }

  /// Process a gift wrap event, decrypt it, and cache the result.
  /// Returns the decrypted message if successful.
  Future<DirectMessage?> _processGiftWrap(
    Nip01Event giftWrap, {
    required bool isRealTime,
  }) async {
    try {
      // Check if already processed
      final cached = await getCachedMessage(giftWrap.id);
      if (cached != null) {
        return cached;
      }

      // Decrypt the gift wrap (unwraps both gift wrap and seal layers)
      final rumor = await ndk.giftWrap.fromGiftWrap(giftWrap: giftWrap);

      // Only process kind 14 (chat messages)
      if (rumor.kind != 14) {
        log('DM: Ignoring non-chat rumor kind=${rumor.kind}');
        return null;
      }

      // Convert to our model
      final message = DirectMessageModel.fromUnwrappedRumor(
        rumor: rumor,
        giftWrapId: giftWrap.id,
        myPubkey: myPubkey,
      );

      // Cache the decrypted message
      await cacheDecryptedMessage(message);

      // Update conversation
      await _updateConversation(
        message,
        incrementUnread: isRealTime && !message.isOutgoing,
      );

      // Notify listeners
      _notifyMessagesChanged(message.peerPubkey);
      _notifyConversationsChanged();

      return message;
    } catch (e) {
      log('DM: Error processing gift wrap ${giftWrap.id}: $e');
      return null;
    }
  }

  // ============ Sending ============

  @override
  Future<DirectMessage> sendMessage({
    required String recipientPubkey,
    required String content,
    String? replyToEventId,
  }) async {
    // Build tags for the rumor (kind 14)
    final tags = <List<String>>[
      ['p', recipientPubkey],
    ];

    if (replyToEventId != null) {
      tags.add(['e', replyToEventId, '', 'reply']);
    }

    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    // Track whether the message was staged to local DB (so the catch block can
    // mark it as failed instead of leaving it stuck as pending).
    DirectMessageModel? stagedMessage;

    try {
      // 1. Create the rumor (unsigned kind 14 event)
      final rumor = await ndk.giftWrap.createRumor(
        content: content,
        kind: 14, // Chat message
        tags: tags,
      );

      log('DM: Created rumor id=${rumor.id}');

      // 2. Create gift wraps for both recipient and ourselves
      // Per NIP-17: sender must send to both recipient's inbox AND their own inbox
      // Special case: if sending to self ("Note to Self"), only create one gift wrap
      final isSelfMessage = recipientPubkey == myPubkey;

      final recipientGiftWrap = await ndk.giftWrap.toGiftWrap(
        rumor: rumor,
        recipientPubkey: recipientPubkey,
      );

      // Only create separate self gift wrap if not sending to self
      final selfGiftWrap = isSelfMessage
          ? recipientGiftWrap
          : await ndk.giftWrap.toGiftWrap(
              rumor: rumor,
              recipientPubkey: myPubkey,
            );

      // 3. Save gift wraps to NDK cache for potential resend
      await ndk.config.cache.saveEvent(selfGiftWrap);
      if (!isSelfMessage) {
        await ndk.config.cache.saveEvent(recipientGiftWrap);
      }

      // 4. Cache locally IMMEDIATELY with pending status so it appears in UI
      final localMessage = DirectMessageModel(
        id: selfGiftWrap.id,
        senderPubkey: myPubkey,
        peerPubkey: recipientPubkey,
        content: content,
        createdAt: now,
        isOutgoing: true,
        tags: tags.map((t) => NostrTagModel.fromJson(t)).toList(),
        sendStatus: MessageSendStatus.pending,
        recipientGiftWrapId: isSelfMessage ? null : recipientGiftWrap.id,
      );

      await cacheDecryptedMessage(localMessage);
      stagedMessage = localMessage;
      await _updateConversation(localMessage, incrementUnread: false);

      // Persist serialised gift wrap JSON so resend works after app restart
      // (NDK in-memory cache does not survive restarts).
      await _persistGiftWrapsToDb(
        messageId: selfGiftWrap.id,
        selfGiftWrapJson: jsonEncode(
          Nip01EventModel.fromEntity(selfGiftWrap).toJson(),
        ),
        recipientGiftWrapJson: isSelfMessage
            ? null
            : jsonEncode(
                Nip01EventModel.fromEntity(recipientGiftWrap).toJson(),
              ),
      );

      _notifyMessagesChanged(recipientPubkey);
      _notifyConversationsChanged();

      log('DM: Message cached as pending, now broadcasting...');

      // 5. Get DM relays (network operation)
      final recipientRelays = await _getDmInboxRelays(recipientPubkey);
      final myRelays = isSelfMessage
          ? recipientRelays
          : await _getDmInboxRelays(myPubkey);

      log(
        'DM: Broadcasting to recipient relays: ${recipientRelays.isNotEmpty ? recipientRelays : "default"}',
      );
      if (!isSelfMessage) {
        log(
          'DM: Broadcasting to my relays: ${myRelays.isNotEmpty ? myRelays : "default"}',
        );
      }

      // 6. Broadcast gift wraps — self first, then recipient after a short delay
      // to avoid triggering rate limits on relays that are strict.
      const dmTimeout = Duration(minutes: 1);

      // Compute known relay totals upfront (0 = NDK will choose defaults)
      final selfRelayCount = isSelfMessage ? 0 : myRelays.length;
      final recipientRelayCount = recipientRelays.length;
      final knownTotal = selfRelayCount + recipientRelayCount;

      // Push "0/N" progress immediately so the UI shows the total right away
      if (knownTotal > 0) {
        _notifyMessageUpdate(
          recipientPubkey,
          localMessage.copyWith(relaysSent: 0, relaysTotal: knownTotal),
        );
      }

      // Broadcast self gift wrap first
      NdkBroadcastResponse? selfBroadcast;
      if (!isSelfMessage) {
        selfBroadcast = ndk.broadcast.broadcast(
          nostrEvent: selfGiftWrap,
          specificRelays: myRelays.isNotEmpty ? myRelays : null,
          timeout: dmTimeout,
        );
        // Rate-limiting delay between the two broadcast calls
        await Future.delayed(const Duration(milliseconds: 1500));
      }

      // Then broadcast to recipient
      final recipientBroadcast = ndk.broadcast.broadcast(
        nostrEvent: recipientGiftWrap,
        specificRelays: recipientRelays.isNotEmpty ? recipientRelays : null,
        timeout: dmTimeout,
      );

      // 7. Listen to both broadcast streams for live relay-count progress.
      // Counts are tracked with plain ints; access is safe because Dart's
      // event loop is single-threaded — callbacks never run concurrently.
      int selfConfirmedCount = 0;
      int recipientConfirmedCount = 0;
      // Running total inferred from stream emissions (covers unknown-total case)
      int streamSelfTotal = selfRelayCount;
      int streamRecipientTotal = recipientRelayCount;

      void pushProgress() {
        final total = streamSelfTotal + streamRecipientTotal;
        if (total == 0) return; // still unknown, skip update
        _notifyMessageUpdate(
          recipientPubkey,
          localMessage.copyWith(
            relaysSent: selfConfirmedCount + recipientConfirmedCount,
            relaysTotal: total,
          ),
        );
      }

      selfBroadcast?.broadcastDone.listen(
        (responses) {
          selfConfirmedCount = responses
              .where((r) => r.broadcastSuccessful)
              .length;
          // Update total from actual relay count once relays respond
          if (responses.length > streamSelfTotal) {
            streamSelfTotal = responses.length;
          }
          pushProgress();
        },
        onError: (_) {}, // individual relay errors must not cancel the listener
      );

      recipientBroadcast.broadcastDone.listen((responses) {
        recipientConfirmedCount = responses
            .where((r) => r.broadcastSuccessful)
            .length;
        if (responses.length > streamRecipientTotal) {
          streamRecipientTotal = responses.length;
        }
        pushProgress();
      }, onError: (_) {});

      // 8. Await final responses
      final recipientResponses = await recipientBroadcast.broadcastDoneFuture;
      final recipientConfirmed = recipientResponses.any(
        (r) => r.broadcastSuccessful,
      );

      // Self-broadcast failure means our own backup copy wasn't stored, but the
      // peer still received the message — do NOT mark as failed in that case.
      if (selfBroadcast != null) {
        final selfResponses = await selfBroadcast.broadcastDoneFuture;
        final selfConfirmed = selfResponses.any((r) => r.broadcastSuccessful);
        if (!selfConfirmed) {
          log(
            'DM: Warning - self-backup broadcast failed (peer may have received message)',
          );
        }
      }

      // Build a human-readable reason when the message was not delivered.
      String? failureReason;
      if (!recipientConfirmed) {
        if (recipientRelays.isEmpty && recipientResponses.isEmpty) {
          failureReason =
              'No DM relay found for recipient (tried default relays)';
        } else {
          final reasons = recipientResponses
              .where((r) => !r.broadcastSuccessful && r.msg.isNotEmpty)
              .map((r) => '${r.relayUrl}: ${r.msg}')
              .toList();
          failureReason = reasons.isNotEmpty
              ? reasons.join('\n')
              : 'No relay confirmed delivery';
        }
        log('DM: Send failed. Reason: $failureReason');
      }

      // 9. Persist final status (relay count fields are transient, not stored)
      final finalMessage = localMessage.copyWith(
        sendStatus: recipientConfirmed
            ? MessageSendStatus.sent
            : MessageSendStatus.failed,
        failureReason: failureReason,
        clearFailureReason: recipientConfirmed,
      );

      await cacheDecryptedMessage(finalMessage);
      _notifyMessagesChanged(recipientPubkey);
      _notifyConversationsChanged();

      log(
        'DM: Message ${recipientConfirmed ? 'sent successfully' : 'failed - no relay confirmation'}',
      );

      return finalMessage;
    } catch (e) {
      log('DM: Error sending message: $e');
      // If the message was already staged (cached as pending), update it to
      // failed so it doesn't get stuck in the pending state forever.
      if (stagedMessage != null) {
        final failedMessage = stagedMessage.copyWith(
          sendStatus: MessageSendStatus.failed,
          failureReason: e.toString(),
        );
        await cacheDecryptedMessage(failedMessage);
        _notifyMessagesChanged(recipientPubkey);
        _notifyConversationsChanged();
        return failedMessage;
      }
      rethrow;
    }
  }

  @override
  Future<bool> resendMessage(String messageId) async {
    // 1. Get the cached message
    final message = await getCachedMessage(messageId);
    if (message == null) {
      log('DM: Cannot resend - message $messageId not found');
      return false;
    }

    if (!message.isOutgoing) {
      log('DM: Cannot resend - message is not outgoing');
      return false;
    }

    // 2. Load gift wraps — try NDK in-memory cache first, fall back to DB.
    // The self gift wrap ID is the same as the message ID.
    Nip01Event? selfGiftWrap = await ndk.config.cache.loadEvent(messageId);
    if (selfGiftWrap == null) {
      log('DM: NDK cache miss for $messageId, trying DB-persisted gift wrap');
      selfGiftWrap = await _loadGiftWrapFromDb(messageId, isSelf: true);
    }
    if (selfGiftWrap == null) {
      log(
        'DM: Cannot resend - gift wrap not found in cache or DB for $messageId',
      );
      return false;
    }

    final isSelfMessage = message.peerPubkey == myPubkey;
    Nip01Event? recipientGiftWrap;
    if (!isSelfMessage && message.recipientGiftWrapId != null) {
      recipientGiftWrap = await ndk.config.cache.loadEvent(
        message.recipientGiftWrapId!,
      );
      if (recipientGiftWrap == null) {
        recipientGiftWrap = await _loadGiftWrapFromDb(messageId, isSelf: false);
      }
    }

    try {
      // 3. Update status to pending
      final pendingMessage = message.copyWith(
        sendStatus: MessageSendStatus.pending,
      );
      await cacheDecryptedMessage(pendingMessage);
      _notifyMessagesChanged(message.peerPubkey);

      log('DM: Resending message $messageId...');

      // 4. Get DM relays
      final recipientRelays = await _getDmInboxRelays(message.peerPubkey);
      final myRelays = isSelfMessage
          ? recipientRelays
          : await _getDmInboxRelays(myPubkey);

      log(
        'DM: Resending to recipient relays: ${recipientRelays.isNotEmpty ? recipientRelays : "default"}',
      );

      // 5. Broadcast gift wraps — self first, then recipient after a short delay
      const dmTimeout = Duration(minutes: 1);
      final giftWrapForRecipient = recipientGiftWrap ?? selfGiftWrap;

      final selfRelayCount = isSelfMessage ? 0 : myRelays.length;
      final recipientRelayCount = recipientRelays.length;
      final knownTotal = selfRelayCount + recipientRelayCount;

      // Push "0/N" progress immediately
      if (knownTotal > 0) {
        _notifyMessageUpdate(
          message.peerPubkey,
          pendingMessage.copyWith(relaysSent: 0, relaysTotal: knownTotal),
        );
      }

      // Self broadcast first
      NdkBroadcastResponse? selfBroadcast;
      if (!isSelfMessage) {
        selfBroadcast = ndk.broadcast.broadcast(
          nostrEvent: selfGiftWrap,
          specificRelays: myRelays.isNotEmpty ? myRelays : null,
          timeout: dmTimeout,
        );
        await Future.delayed(const Duration(milliseconds: 1500));
      }

      final recipientBroadcast = ndk.broadcast.broadcast(
        nostrEvent: giftWrapForRecipient,
        specificRelays: recipientRelays.isNotEmpty ? recipientRelays : null,
        timeout: dmTimeout,
      );

      // Live relay-count progress listeners
      int selfConfirmedCount = 0;
      int recipientConfirmedCount = 0;
      int streamSelfTotal = selfRelayCount;
      int streamRecipientTotal = recipientRelayCount;

      void pushProgress() {
        final total = streamSelfTotal + streamRecipientTotal;
        if (total == 0) return;
        _notifyMessageUpdate(
          message.peerPubkey,
          pendingMessage.copyWith(
            relaysSent: selfConfirmedCount + recipientConfirmedCount,
            relaysTotal: total,
          ),
        );
      }

      selfBroadcast?.broadcastDone.listen((responses) {
        selfConfirmedCount = responses
            .where((r) => r.broadcastSuccessful)
            .length;
        if (responses.length > streamSelfTotal) {
          streamSelfTotal = responses.length;
        }
        pushProgress();
      }, onError: (_) {});

      recipientBroadcast.broadcastDone.listen((responses) {
        recipientConfirmedCount = responses
            .where((r) => r.broadcastSuccessful)
            .length;
        if (responses.length > streamRecipientTotal) {
          streamRecipientTotal = responses.length;
        }
        pushProgress();
      }, onError: (_) {});

      // 6. Wait for relay confirmations
      final recipientResponses = await recipientBroadcast.broadcastDoneFuture;
      final recipientConfirmed = recipientResponses.any(
        (r) => r.broadcastSuccessful,
      );

      // Self-broadcast failure means backup wasn't stored but peer may have
      // received the message — do NOT mark as failed in that case.
      if (selfBroadcast != null) {
        final selfResponses = await selfBroadcast.broadcastDoneFuture;
        final selfConfirmed = selfResponses.any((r) => r.broadcastSuccessful);
        if (!selfConfirmed) {
          log('DM: Warning - self-backup resend broadcast failed');
        }
      }

      // Build a human-readable reason when the resend was not delivered.
      String? failureReason;
      if (!recipientConfirmed) {
        final reasons = recipientResponses
            .where((r) => !r.broadcastSuccessful && r.msg.isNotEmpty)
            .map((r) => '${r.relayUrl}: ${r.msg}')
            .toList();
        failureReason = reasons.isNotEmpty
            ? reasons.join('\n')
            : 'No relay confirmed delivery';
        log('DM: Resend failed. Reason: $failureReason');
      }

      // 7. Update message status based on recipient relay confirmation only
      final finalMessage = message.copyWith(
        sendStatus: recipientConfirmed
            ? MessageSendStatus.sent
            : MessageSendStatus.failed,
        failureReason: failureReason,
        clearFailureReason: recipientConfirmed,
      );

      await cacheDecryptedMessage(finalMessage);
      _notifyMessagesChanged(message.peerPubkey);
      _notifyConversationsChanged();

      log(
        'DM: Resend ${recipientConfirmed ? 'successful' : 'failed - no relay confirmation'}',
      );

      return recipientConfirmed;
    } catch (e) {
      log('DM: Error resending message $messageId: $e');

      // Update status to failed with the exception as reason
      final failedMessage = message.copyWith(
        sendStatus: MessageSendStatus.failed,
        failureReason: e.toString(),
      );
      await cacheDecryptedMessage(failedMessage);
      _notifyMessagesChanged(message.peerPubkey);
      _notifyConversationsChanged();

      return false;
    }
  }

  // ============ Cache ============

  @override
  Future<DirectMessage?> getCachedMessage(String giftWrapId) async {
    final store = await getStore();
    final box = store.box<DbNip17Message>();

    // Filter by ownerPubkey to only get messages for the current user
    final query = box
        .query(
          DbNip17Message_.ownerPubkey.equals(myPubkey) &
              DbNip17Message_.eventId.equals(giftWrapId),
        )
        .build();
    final db = query.findFirst();
    query.close();

    if (db == null) return null;

    return DirectMessageModel.fromDb(db);
  }

  @override
  Future<void> cacheDecryptedMessage(DirectMessage message) async {
    final store = await getStore();
    final box = store.box<DbNip17Message>();

    // Check if already exists for this user
    final query = box
        .query(
          DbNip17Message_.ownerPubkey.equals(myPubkey) &
              DbNip17Message_.eventId.equals(message.id),
        )
        .build();
    final existing = query.findFirst();
    query.close();

    final model = DirectMessageModel.fromEntity(message);
    final dbMessage = model.toDb(ownerPubkey: myPubkey);

    if (existing != null) {
      // Update existing message (preserve dbId and persisted gift wrap JSON)
      dbMessage.dbId = existing.dbId;
      dbMessage.selfGiftWrapJson = existing.selfGiftWrapJson;
      dbMessage.recipientGiftWrapJson = existing.recipientGiftWrapJson;
    }

    box.put(dbMessage);
  }

  /// Store serialised gift wrap events in the DB record so that [resendMessage]
  /// can recover them after an app restart (NDK cache is in-memory only).
  Future<void> _persistGiftWrapsToDb({
    required String messageId,
    required String selfGiftWrapJson,
    String? recipientGiftWrapJson,
  }) async {
    final store = await getStore();
    final box = store.box<DbNip17Message>();
    final query = box
        .query(
          DbNip17Message_.ownerPubkey.equals(myPubkey) &
              DbNip17Message_.eventId.equals(messageId),
        )
        .build();
    final existing = query.findFirst();
    query.close();
    if (existing != null) {
      existing.selfGiftWrapJson = selfGiftWrapJson;
      existing.recipientGiftWrapJson = recipientGiftWrapJson;
      box.put(existing);
    }
  }

  /// Load a persisted gift wrap from the DB as a fallback when the NDK
  /// in-memory cache has been cleared (e.g. after app restart).
  Future<Nip01Event?> _loadGiftWrapFromDb(
    String messageId, {
    required bool isSelf,
  }) async {
    final store = await getStore();
    final box = store.box<DbNip17Message>();
    final query = box
        .query(
          DbNip17Message_.ownerPubkey.equals(myPubkey) &
              DbNip17Message_.eventId.equals(messageId),
        )
        .build();
    final existing = query.findFirst();
    query.close();
    if (existing == null) return null;
    final json = isSelf
        ? existing.selfGiftWrapJson
        : existing.recipientGiftWrapJson;
    if (json == null) return null;
    try {
      return Nip01EventModel.fromJson(jsonDecode(json) as Map<String, dynamic>);
    } catch (e) {
      log(
        'DM: Error parsing stored gift wrap JSON (isSelf=$isSelf) for $messageId: $e',
      );
      return null;
    }
  }

  /// Update or create conversation record
  Future<void> _updateConversation(
    DirectMessage message, {
    required bool incrementUnread,
  }) async {
    final store = await getStore();
    final box = store.box<DbNip17Conversation>();

    store.runInTransaction(TxMode.write, () {
      // Filter by ownerPubkey to only update conversation for the current user
      final query = box
          .query(
            DbNip17Conversation_.ownerPubkey.equals(myPubkey) &
                DbNip17Conversation_.peerPubkey.equals(message.peerPubkey),
          )
          .build();
      var conversation = query.findFirst();
      query.close();

      if (conversation == null) {
        conversation = DbNip17Conversation(
          ownerPubkey: myPubkey,
          peerPubkey: message.peerPubkey,
          lastMessageAt: message.createdAt,
          unreadCount: incrementUnread ? 1 : 0,
          lastMessagePreview: _truncatePreview(message.content),
          lastMessageIsOutgoing: message.isOutgoing,
        );
      } else {
        // Only update if this message is newer
        if (message.createdAt >= conversation.lastMessageAt) {
          conversation.lastMessageAt = message.createdAt;
          conversation.lastMessagePreview = _truncatePreview(message.content);
          conversation.lastMessageIsOutgoing = message.isOutgoing;
        }
        if (incrementUnread) {
          conversation.unreadCount++;
        }
      }

      box.put(conversation);
    });
  }

  String _truncatePreview(String content, {int maxLength = 100}) {
    if (content.length <= maxLength) return content;
    return '${content.substring(0, maxLength)}...';
  }

  // ============ Deletion ============

  @override
  Future<bool> deleteMessage(String messageId) async {
    try {
      // Get the message to find peer pubkey for conversation update
      final message = await getCachedMessage(messageId);
      if (message == null) {
        log('DM: Cannot delete - message $messageId not found in cache');
        return false;
      }

      final peerPubkey = message.peerPubkey;

      // 1. Delete from local cache FIRST (immediate, no flicker)
      final store = await getStore();
      final box = store.box<DbNip17Message>();

      final query = box
          .query(
            DbNip17Message_.ownerPubkey.equals(myPubkey) &
                DbNip17Message_.eventId.equals(messageId),
          )
          .build();
      final dbMessage = query.findFirst();
      query.close();

      if (dbMessage != null) {
        box.remove(dbMessage.dbId);
        log('DM: Removed message from local cache');
      }

      // 2. Update conversation and notify listeners immediately
      await _recalculateConversation(peerPubkey);
      _notifyMessagesChanged(peerPubkey);
      _notifyConversationsChanged();

      // 3. Broadcast kind 5 deletion to relays (fire and forget)
      _broadcastDeletion(messageId);

      return true;
    } catch (e) {
      log('DM: Error deleting message $messageId: $e');
      return false;
    }
  }

  /// Broadcast kind 5 deletion event to relays (fire and forget)
  void _broadcastDeletion(String messageId) async {
    try {
      final deleteEvent = Nip01Event(
        pubKey: myPubkey,
        kind: 5,
        tags: [
          ['e', messageId],
        ],
        content: '',
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      );

      final signedEvent = await ndk.accounts.sign(deleteEvent);

      final dmRelays = await _getDmInboxRelays(myPubkey);
      ndk.broadcast.broadcast(
        nostrEvent: signedEvent,
        specificRelays: dmRelays.isNotEmpty ? dmRelays : null,
      );

      log('DM: Broadcasted delete request for message $messageId');
    } catch (e) {
      log('DM: Error broadcasting deletion for $messageId: $e');
    }
  }

  /// Recalculate conversation metadata after message deletion
  Future<void> _recalculateConversation(String peerPubkey) async {
    final store = await getStore();
    final messageBox = store.box<DbNip17Message>();
    final conversationBox = store.box<DbNip17Conversation>();

    // Get the latest message for this peer (filtered by ownerPubkey)
    final query = messageBox
        .query(
          DbNip17Message_.ownerPubkey.equals(myPubkey) &
              DbNip17Message_.peerPubkey.equals(peerPubkey),
        )
        .order(DbNip17Message_.createdAt, flags: Order.descending)
        .build();
    final latestMessage = query.findFirst();
    query.close();

    // Get the conversation (filtered by ownerPubkey)
    final convQuery = conversationBox
        .query(
          DbNip17Conversation_.ownerPubkey.equals(myPubkey) &
              DbNip17Conversation_.peerPubkey.equals(peerPubkey),
        )
        .build();
    final conversation = convQuery.findFirst();
    convQuery.close();

    if (conversation == null) return;

    if (latestMessage == null) {
      // No more messages - delete the conversation
      conversationBox.remove(conversation.dbId);
    } else {
      // Update with latest message
      conversation.lastMessageAt = latestMessage.createdAt;
      conversation.lastMessagePreview = _truncatePreview(latestMessage.content);
      conversation.lastMessageIsOutgoing = latestMessage.isOutgoing;
      conversationBox.put(conversation);
    }
  }

  // ============ Categorization ============

  @override
  Future<Set<String>> getPeersWithOutgoingMessages(
    List<String> peerPubkeys,
  ) async {
    if (peerPubkeys.isEmpty) return {};

    final store = await getStore();
    final box = store.box<DbNip17Message>();

    final result = <String>{};

    // Query for outgoing messages for the given peers (filtered by ownerPubkey)
    // We use a single query with OR conditions for efficiency
    final query = box
        .query(
          DbNip17Message_.ownerPubkey.equals(myPubkey) &
              DbNip17Message_.isOutgoing.equals(true) &
              DbNip17Message_.peerPubkey.oneOf(peerPubkeys),
        )
        .build();

    final messages = query.find();
    query.close();

    // Collect unique peer pubkeys
    for (final msg in messages) {
      result.add(msg.peerPubkey);
    }

    return result;
  }

  // ============ Cleanup ============

  @override
  Future<void> closeSubscriptions() async {
    if (_dmSubscription != null) {
      await ndk.requests.closeSubscription(_dmSubscription!.requestId);
      _dmSubscription = null;
    }
  }

  void dispose() {
    closeSubscriptions();
    _newMessageController.close();
    _conversationsController.close();
    _unreadCountController.close();
    for (final controller in _messagesControllers.values) {
      controller.close();
    }
  }
}
