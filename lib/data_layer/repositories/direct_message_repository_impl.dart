import 'dart:async';
import 'dart:developer';

import 'package:ndk/ndk.dart';

import '../../domain_layer/entities/direct_message.dart';
import '../models/nostr_tag_model.dart';
import '../../domain_layer/entities/dm_conversation.dart';
import '../../domain_layer/repositories/direct_message_repository.dart';
import '../../objectbox.g.dart';
import '../db/object_box_camelus/schema/db_nip17_conversation.dart';
import '../db/object_box_camelus/schema/db_nip17_message.dart';
import '../models/direct_message_model.dart';
import '../../config/nostr_kinds.dart';

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

  DirectMessageRepositoryImpl({
    required this.ndk,
    required this.getStore,
    required this.myPubkey,
  });

  // ============ DM Relay Discovery ============

  /// Get DM inbox relays for a pubkey.
  /// First tries kind 10050 (DM-specific relays), then falls back to NIP-65 inbox relays.
  /// Reads from cache first for speed, refreshes cache in background.
  Future<List<String>> _getDmInboxRelays(String pubkey) async {
    // Try cache first (fast)
    final cachedRelays = await _getDmInboxRelaysFromCache(pubkey);
    if (cachedRelays.isNotEmpty) {
      log('DM: Using cached relays for $pubkey: $cachedRelays');
      // Refresh cache in background for next time
      _refreshDmRelaysInBackground(pubkey);
      return cachedRelays;
    }

    // Cache miss: fetch from network
    log('DM: Cache miss, fetching relays for $pubkey');
    await ndk.relays.seedRelaysConnected;

    final dmRelays = await _fetchKind10050Relays(pubkey);
    if (dmRelays.isNotEmpty) {
      log('DM: Using kind 10050 relays for $pubkey: $dmRelays');
      return dmRelays;
    }

    final nip65Relays = await _getNip65InboxRelays(pubkey);
    if (nip65Relays.isNotEmpty) {
      log('DM: Using NIP-65 inbox relays for $pubkey: $nip65Relays');
      return nip65Relays;
    }

    log('DM: No DM relays found for $pubkey, using default relays');
    return [];
  }

  /// Get DM relays from cache only (no network).
  Future<List<String>> _getDmInboxRelaysFromCache(String pubkey) async {
    // Try kind 10050 from cache
    final events = await ndk.config.cache.loadEvents(
      kinds: [kDmRelayListKind],
      pubKeys: [pubkey],
      limit: 1,
    );
    if (events.isNotEmpty) {
      final relays = <String>[];
      for (final tag in events.first.tags) {
        if (tag.isNotEmpty && tag[0] == 'relay' && tag.length > 1) {
          relays.add(tag[1]);
        }
      }
      if (relays.isNotEmpty) return relays;
    }

    // Try NIP-65 from cache
    final userRelayList = await ndk.config.cache.loadUserRelayList(pubkey);
    if (userRelayList != null) {
      return userRelayList.readUrls.toList();
    }

    return [];
  }

  /// Refresh DM relays cache in background (fire and forget).
  void _refreshDmRelaysInBackground(String pubkey) {
    Future(() async {
      try {
        await ndk.relays.seedRelaysConnected;
        await _fetchKind10050Relays(pubkey);
        await _getNip65InboxRelays(pubkey);
      } catch (_) {}
    });
  }

  /// Fetch kind 10050 (DM relay list) for a pubkey.
  /// Queries on the user's NIP-65 write relays.
  /// Returns empty list if not found.
  Future<List<String>> _fetchKind10050Relays(String pubkey) async {
    try {
      // First get NIP-65 write relays to query kind 10050
      final userRelayList = await ndk.userRelayLists.getSingleUserRelayList(
        pubkey,
      );

      log(
        'DM: userRelayList for $pubkey: ${userRelayList != null ? "found" : "null"}',
      );

      final writeRelays =
          userRelayList?.relays.entries
              .where((entry) => entry.value.isWrite)
              .map((entry) => entry.key)
              .toList() ??
          [];

      log('DM: writeRelays for kind 10050 query: $writeRelays');

      final filter = Filter(
        kinds: [kDmRelayListKind],
        authors: [pubkey],
        limit: 1,
      );

      final response = ndk.requests.query(
        filter: filter,
        timeout: const Duration(seconds: 10),
        explicitRelays: writeRelays.isNotEmpty ? writeRelays : null,
      );

      Nip01Event? latestEvent;
      await for (final event in response.stream) {
        if (latestEvent == null || event.createdAt > latestEvent.createdAt) {
          latestEvent = event;
        }
      }

      if (latestEvent == null) {
        log('DM: No kind 10050 event found for $pubkey');
        return [];
      }

      // Parse relay URLs from tags: [["relay", "wss://relay.example.com"], ...]
      final relays = <String>[];
      for (final tag in latestEvent.tags) {
        if (tag.isNotEmpty && tag[0] == 'relay' && tag.length > 1) {
          relays.add(tag[1]);
        }
      }

      log('DM: Found kind 10050 relays: $relays');
      return relays;
    } catch (e) {
      log('DM: Error fetching kind 10050 for $pubkey: $e');
      return [];
    }
  }

  /// Get NIP-65 inbox relays (read-capable relays) for a pubkey.
  Future<List<String>> _getNip65InboxRelays(String pubkey) async {
    try {
      final userRelayList = await ndk.userRelayLists.getSingleUserRelayList(
        pubkey,
      );
      if (userRelayList == null) {
        return [];
      }

      // Get relays marked for reading (inbox)
      return userRelayList.readUrls.toList();
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
    final box = store.box<DbNip17Conversation>();

    final query = box
        .query()
        .order(DbNip17Conversation_.lastMessageAt, flags: Order.descending)
        .build();

    final conversations = query.find();
    query.close();

    return conversations.map((db) {
      return DmConversation(
        peerPubkey: db.peerPubkey,
        lastMessageAt: db.lastMessageAt,
        unreadCount: db.unreadCount,
        lastMessagePreview: db.lastMessagePreview,
        lastMessageIsOutgoing: db.lastMessageIsOutgoing,
      );
    }).toList();
  }

  void _notifyConversationsChanged() async {
    final conversations = await _getConversationsFromDb();
    _conversationsController.add(conversations);
    _notifyUnreadCountChanged();
  }

  @override
  Future<DmConversation?> getConversation(String peerPubkey) async {
    final store = await getStore();
    final box = store.box<DbNip17Conversation>();

    final query = box
        .query(DbNip17Conversation_.peerPubkey.equals(peerPubkey))
        .build();
    final db = query.findFirst();
    query.close();

    if (db == null) return null;

    return DmConversation(
      peerPubkey: db.peerPubkey,
      lastMessageAt: db.lastMessageAt,
      unreadCount: db.unreadCount,
      lastMessagePreview: db.lastMessagePreview,
      lastMessageIsOutgoing: db.lastMessageIsOutgoing,
    );
  }

  @override
  Future<void> markConversationAsRead(String peerPubkey) async {
    final store = await getStore();
    final box = store.box<DbNip17Conversation>();

    store.runInTransaction(TxMode.write, () {
      final query = box
          .query(DbNip17Conversation_.peerPubkey.equals(peerPubkey))
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

    final query = box.query().build();
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

    final query = box
        .query(DbNip17Message_.peerPubkey.equals(peerPubkey))
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
  Future<bool> loadOlderMessages() async {
    // Get the oldest message timestamp from local DB
    final store = await getStore();
    final box = store.box<DbNip17Message>();

    final query = box.query().order(DbNip17Message_.createdAt).build();
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
    }

    return foundNew;
  }

  @override
  Future<int?> getOldestMessageTimestamp(String peerPubkey) async {
    final store = await getStore();
    final box = store.box<DbNip17Message>();

    final query = box
        .query(DbNip17Message_.peerPubkey.equals(peerPubkey))
        .order(DbNip17Message_.createdAt)
        .build();
    final oldestMessage = query.findFirst();
    query.close();

    return oldestMessage?.createdAt;
  }

  @override
  Future<bool> hasReachedBeginning(String peerPubkey) async {
    final filter = Filter(kinds: [1059], pTags: [myPubkey]);

    // Get all fetched ranges for this filter (Map<relayUrl, RelayFetchedRanges>)
    final rangesMap = await ndk.fetchedRanges.getForFilter(filter);

    // Check if any relay has reached the oldest (oldest == 0)
    final hasReachedOldest = rangesMap.values.any((r) => r.reachedOldest);

    log(
      'DM: hasReachedBeginning($peerPubkey): $hasReachedOldest (relays=${rangesMap.length})',
    );

    return hasReachedOldest;
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

    _dmSubscription!.stream.listen((giftWrap) async {
      log('DM: Subscription received gift wrap id=${giftWrap.id}');
      final message = await _processGiftWrap(giftWrap, isRealTime: true);
      if (message != null) {
        log('DM: New message processed from ${message.senderPubkey}');
        _newMessageController.add(message);
      }
    });
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
      await _updateConversation(localMessage, incrementUnread: false);
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

      // 6. Broadcast gift wraps
      const dmTimeout = Duration(minutes: 1);
      final recipientBroadcast = ndk.broadcast.broadcast(
        nostrEvent: recipientGiftWrap,
        specificRelays: recipientRelays.isNotEmpty ? recipientRelays : null,
        timeout: dmTimeout,
      );

      final selfBroadcast = isSelfMessage
          ? null
          : ndk.broadcast.broadcast(
              nostrEvent: selfGiftWrap,
              specificRelays: myRelays.isNotEmpty ? myRelays : null,
              timeout: dmTimeout,
            );

      // 7. Wait for relay confirmations
      final recipientResponses = await recipientBroadcast.broadcastDoneFuture;
      final recipientConfirmed = recipientResponses.any(
        (r) => r.broadcastSuccessful,
      );

      final selfConfirmed =
          selfBroadcast == null ||
          (await selfBroadcast.broadcastDoneFuture).any(
            (r) => r.broadcastSuccessful,
          );

      final relayConfirmed = recipientConfirmed && selfConfirmed;

      // 8. Update message status based on relay confirmation
      final finalMessage = localMessage.copyWith(
        sendStatus: relayConfirmed
            ? MessageSendStatus.sent
            : MessageSendStatus.failed,
      );

      await cacheDecryptedMessage(finalMessage);
      _notifyMessagesChanged(recipientPubkey);

      log(
        'DM: Message ${relayConfirmed ? 'sent successfully' : 'failed - no relay confirmation'}',
      );

      return finalMessage;
    } catch (e) {
      log('DM: Error sending message: $e');
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

    // 2. Load gift wraps from NDK cache
    // The self gift wrap ID is the same as the message ID
    final selfGiftWrap = await ndk.config.cache.loadEvent(messageId);
    if (selfGiftWrap == null) {
      log('DM: Cannot resend - gift wrap not found in cache for $messageId');
      return false;
    }

    final isSelfMessage = message.peerPubkey == myPubkey;
    Nip01Event? recipientGiftWrap;
    if (!isSelfMessage && message.recipientGiftWrapId != null) {
      recipientGiftWrap = await ndk.config.cache.loadEvent(
        message.recipientGiftWrapId!,
      );
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

      // 5. Broadcast gift wraps
      // For self-messages or when we only have recipient gift wrap, use selfGiftWrap
      const dmTimeout = Duration(minutes: 1);
      final giftWrapForRecipient = recipientGiftWrap ?? selfGiftWrap;

      final recipientBroadcast = ndk.broadcast.broadcast(
        nostrEvent: giftWrapForRecipient,
        specificRelays: recipientRelays.isNotEmpty ? recipientRelays : null,
        timeout: dmTimeout,
      );

      final selfBroadcast = isSelfMessage
          ? null
          : ndk.broadcast.broadcast(
              nostrEvent: selfGiftWrap,
              specificRelays: myRelays.isNotEmpty ? myRelays : null,
              timeout: dmTimeout,
            );

      // 6. Wait for relay confirmations
      final recipientResponses = await recipientBroadcast.broadcastDoneFuture;
      final recipientConfirmed = recipientResponses.any(
        (r) => r.broadcastSuccessful,
      );

      final selfConfirmed =
          selfBroadcast == null ||
          (await selfBroadcast.broadcastDoneFuture).any(
            (r) => r.broadcastSuccessful,
          );

      final relayConfirmed = recipientConfirmed && selfConfirmed;

      // 7. Update message status based on relay confirmation
      final finalMessage = message.copyWith(
        sendStatus: relayConfirmed
            ? MessageSendStatus.sent
            : MessageSendStatus.failed,
      );

      await cacheDecryptedMessage(finalMessage);
      _notifyMessagesChanged(message.peerPubkey);

      log(
        'DM: Resend ${relayConfirmed ? 'successful' : 'failed - no relay confirmation'}',
      );

      return relayConfirmed;
    } catch (e) {
      log('DM: Error resending message $messageId: $e');

      // Update status to failed
      final failedMessage = message.copyWith(
        sendStatus: MessageSendStatus.failed,
      );
      await cacheDecryptedMessage(failedMessage);
      _notifyMessagesChanged(message.peerPubkey);

      return false;
    }
  }

  // ============ Cache ============

  @override
  Future<DirectMessage?> getCachedMessage(String giftWrapId) async {
    final store = await getStore();
    final box = store.box<DbNip17Message>();

    final query = box.query(DbNip17Message_.eventId.equals(giftWrapId)).build();
    final db = query.findFirst();
    query.close();

    if (db == null) return null;

    return DirectMessageModel.fromDb(db);
  }

  @override
  Future<void> cacheDecryptedMessage(DirectMessage message) async {
    final store = await getStore();
    final box = store.box<DbNip17Message>();

    // Check if already exists
    final query = box.query(DbNip17Message_.eventId.equals(message.id)).build();
    final existing = query.findFirst();
    query.close();

    final model = DirectMessageModel.fromEntity(message);
    final dbMessage = model.toDb();

    if (existing != null) {
      // Update existing message (preserve dbId for ObjectBox)
      dbMessage.dbId = existing.dbId;
    }

    box.put(dbMessage);
  }

  /// Update or create conversation record
  Future<void> _updateConversation(
    DirectMessage message, {
    required bool incrementUnread,
  }) async {
    final store = await getStore();
    final box = store.box<DbNip17Conversation>();

    store.runInTransaction(TxMode.write, () {
      final query = box
          .query(DbNip17Conversation_.peerPubkey.equals(message.peerPubkey))
          .build();
      var conversation = query.findFirst();
      query.close();

      if (conversation == null) {
        conversation = DbNip17Conversation(
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

      // NIP-59: "relays SHOULD delete kind 1059 events whose p-tag matches
      // the signer of NIP-09 deletions". Since the gift wrap's p-tag is our
      // pubkey (we're the recipient), we can request deletion.
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

      // Broadcast to DM relays
      final dmRelays = await _getDmInboxRelays(myPubkey);
      final broadcastResponse = ndk.broadcast.broadcast(
        nostrEvent: signedEvent,
        specificRelays: dmRelays.isNotEmpty ? dmRelays : null,
      );

      // Wait for broadcast to complete
      await broadcastResponse.broadcastDoneFuture;
      log('DM: Broadcasted delete request for message $messageId');

      // Wait for relays to process the deletion
      await Future.delayed(const Duration(milliseconds: 500));

      // Verify deletion empirically by querying for the message
      final stillExists = await _verifyMessageDeleted(
        messageId,
        dmRelays.isNotEmpty ? dmRelays : null,
      );

      if (stillExists) {
        log(
          'DM: Message $messageId still exists on some relays - deletion may not be supported',
        );
        // Still remove from local cache, but inform the user
      }

      // Delete from local cache
      final store = await getStore();
      final box = store.box<DbNip17Message>();

      final query = box
          .query(DbNip17Message_.eventId.equals(messageId))
          .build();
      final dbMessage = query.findFirst();
      query.close();

      if (dbMessage != null) {
        box.remove(dbMessage.dbId);
        log('DM: Removed message from local cache');
      }

      // Update conversation (recalculate last message)
      await _recalculateConversation(message.peerPubkey);

      // Notify listeners
      _notifyMessagesChanged(message.peerPubkey);
      _notifyConversationsChanged();

      // Return true if message was deleted from at least some relays
      return !stillExists;
    } catch (e) {
      log('DM: Error deleting message $messageId: $e');
      return false;
    }
  }

  /// Verify if a message was actually deleted from relays.
  /// Returns true if the message still exists on any relay.
  Future<bool> _verifyMessageDeleted(
    String messageId,
    List<String>? relays,
  ) async {
    try {
      final filter = Filter(
        ids: [messageId],
        kinds: [1059], // Gift wrap
        limit: 1,
      );

      final response = ndk.requests.query(
        filter: filter,
        cacheRead: false,
        cacheWrite: false,
        timeout: const Duration(seconds: 5),
        explicitRelays: relays,
      );

      // Check if any event is returned
      await for (final event in response.stream) {
        if (event.id == messageId) {
          log('DM: Message $messageId still found on relay');
          return true; // Message still exists
        }
      }

      log('DM: Message $messageId verified deleted from relays');
      return false; // Message was deleted
    } catch (e) {
      log('DM: Error verifying deletion: $e');
      // On error, assume deletion might have worked
      return false;
    }
  }

  /// Recalculate conversation metadata after message deletion
  Future<void> _recalculateConversation(String peerPubkey) async {
    final store = await getStore();
    final messageBox = store.box<DbNip17Message>();
    final conversationBox = store.box<DbNip17Conversation>();

    // Get the latest message for this peer
    final query = messageBox
        .query(DbNip17Message_.peerPubkey.equals(peerPubkey))
        .order(DbNip17Message_.createdAt, flags: Order.descending)
        .build();
    final latestMessage = query.findFirst();
    query.close();

    // Get the conversation
    final convQuery = conversationBox
        .query(DbNip17Conversation_.peerPubkey.equals(peerPubkey))
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

    // Query for outgoing messages for the given peers
    // We use a single query with OR conditions for efficiency
    final query = box
        .query(
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
