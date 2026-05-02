import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast_io.dart';
import 'package:sembast_web/sembast_web.dart';

import '../../../domain_layer/entities/direct_message.dart';
import '../../../domain_layer/entities/dm_conversation.dart';
import '../../../domain_layer/repositories/app_db.dart';
import '../../models/direct_message_model.dart';

class DbAppSembastImpl implements AppDb {
  final Completer<void> _initCompleter = Completer<void>();
  Future<void> get _dbRdy => _initCompleter.future;
  late Database _database;

  static const String _kvStoreName = 'app_kv';
  static const String _msgStoreName = 'dm_messages';
  static const String _convStoreName = 'dm_conversations';
  static const String _dbName = 'camelus_app.db';

  // Key-value store
  StoreRef<String, Map<String, Object?>> get _kvStore =>
      stringMapStoreFactory.store(_kvStoreName);

  // DM stores — key for messages: '${ownerPubkey}_${giftWrapId}'
  //             key for conversations: '${ownerPubkey}_${peerPubkey}'
  StoreRef<String, Map<String, Object?>> get _msgStore =>
      stringMapStoreFactory.store(_msgStoreName);

  StoreRef<String, Map<String, Object?>> get _convStore =>
      stringMapStoreFactory.store(_convStoreName);

  static const String _kvValueField = 'value';

  DbAppSembastImpl() {
    _init();
  }

  Future<void> _init() async {
    final factory = kIsWeb ? databaseFactoryWeb : databaseFactoryIo;
    final dbPath = await _resolveDbPath();
    _database = await factory.openDatabase(dbPath);
    _initCompleter.complete();
  }

  Future<String> _resolveDbPath() async {
    if (kIsWeb) {
      return _dbName;
    }

    final docsDir = await getApplicationDocumentsDirectory();
    return p.join(docsDir.path, _dbName);
  }

  // ============ Key-Value ============

  @override
  Future<void> clear() async {
    await _dbRdy;
    await _kvStore.delete(_database);
  }

  @override
  Future<void> delete(String key) async {
    await _dbRdy;
    await _kvStore.record(key).delete(_database);
  }

  @override
  Future<String?> read(String key) async {
    await _dbRdy;
    final record = await _kvStore.record(key).get(_database);
    final value = record?[_kvValueField];
    if (value is String) {
      return value;
    }
    return null;
  }

  @override
  Future<void> save({required String key, required String value}) async {
    await _dbRdy;
    await _kvStore.record(key).put(_database, {_kvValueField: value});
  }

  // ============ DM helpers ============

  String _msgKey(String ownerPubkey, String giftWrapId) =>
      '${ownerPubkey}_$giftWrapId';

  String _convKey(String ownerPubkey, String peerPubkey) =>
      '${ownerPubkey}_$peerPubkey';

  DirectMessage _mapToMessage(Map<String, Object?> map) {
    // Sembast stores values as Object? — cast to the expected types.
    return DirectMessageModel.fromMap(map.map((k, v) => MapEntry(k, v)));
  }

  Map<String, Object?> _messageToMap(
    DirectMessage message,
    String ownerPubkey, {
    String? selfGiftWrapJson,
    String? recipientGiftWrapJson,
  }) {
    final model = DirectMessageModel.fromEntity(message);
    final map = model.toMap(ownerPubkey: ownerPubkey);
    // Cast to sembast-compatible type
    final result = map.map<String, Object?>(
      (k, v) => MapEntry(k, v as Object?),
    );
    if (selfGiftWrapJson != null) {
      result['selfGiftWrapJson'] = selfGiftWrapJson;
    }
    if (recipientGiftWrapJson != null) {
      result['recipientGiftWrapJson'] = recipientGiftWrapJson;
    }
    return result;
  }

  DmConversation _mapToConversation(Map<String, Object?> map) {
    return DmConversation(
      peerPubkey: map['peerPubkey'] as String,
      lastMessageAt: map['lastMessageAt'] as int,
      unreadCount: map['unreadCount'] as int? ?? 0,
      lastMessagePreview: map['lastMessagePreview'] as String? ?? '',
      lastMessageIsOutgoing: map['lastMessageIsOutgoing'] as bool? ?? false,
    );
  }

  Map<String, Object?> _conversationToMap(
    DmConversation conversation,
    String ownerPubkey,
  ) {
    return {
      'ownerPubkey': ownerPubkey,
      'peerPubkey': conversation.peerPubkey,
      'lastMessageAt': conversation.lastMessageAt,
      'unreadCount': conversation.unreadCount,
      'lastMessagePreview': conversation.lastMessagePreview,
      'lastMessageIsOutgoing': conversation.lastMessageIsOutgoing,
    };
  }

  // ============ DM Messages ============

  @override
  Future<void> dmPutMessage({
    required String ownerPubkey,
    required DirectMessage message,
  }) async {
    await _dbRdy;
    final key = _msgKey(ownerPubkey, message.id);
    final existing = await _msgStore.record(key).get(_database);
    final map = _messageToMap(message, ownerPubkey);
    // Preserve any previously stored gift-wrap JSON
    if (existing != null) {
      map['selfGiftWrapJson'] ??= existing['selfGiftWrapJson'];
      map['recipientGiftWrapJson'] ??= existing['recipientGiftWrapJson'];
    }
    await _msgStore.record(key).put(_database, map);
  }

  @override
  Future<DirectMessage?> dmGetMessage({
    required String ownerPubkey,
    required String giftWrapId,
  }) async {
    await _dbRdy;
    final record = await _msgStore
        .record(_msgKey(ownerPubkey, giftWrapId))
        .get(_database);
    return record != null ? _mapToMessage(record) : null;
  }

  @override
  Future<List<DirectMessage>> dmGetMessagesByPeer({
    required String ownerPubkey,
    required String peerPubkey,
  }) async {
    await _dbRdy;
    final finder = Finder(
      filter: Filter.and([
        Filter.equals('ownerPubkey', ownerPubkey),
        Filter.equals('peerPubkey', peerPubkey),
      ]),
      sortOrders: [SortOrder('createdAt')],
    );
    final records = await _msgStore.find(_database, finder: finder);
    return records.map((r) => _mapToMessage(r.value)).toList();
  }

  @override
  Future<DirectMessage?> dmGetOldestMessage({
    required String ownerPubkey,
  }) async {
    await _dbRdy;
    final finder = Finder(
      filter: Filter.equals('ownerPubkey', ownerPubkey),
      sortOrders: [SortOrder('createdAt')],
      limit: 1,
    );
    final records = await _msgStore.find(_database, finder: finder);
    return records.isNotEmpty ? _mapToMessage(records.first.value) : null;
  }

  @override
  Future<DirectMessage?> dmGetOldestMessageByPeer({
    required String ownerPubkey,
    required String peerPubkey,
  }) async {
    await _dbRdy;
    final finder = Finder(
      filter: Filter.and([
        Filter.equals('ownerPubkey', ownerPubkey),
        Filter.equals('peerPubkey', peerPubkey),
      ]),
      sortOrders: [SortOrder('createdAt')],
      limit: 1,
    );
    final records = await _msgStore.find(_database, finder: finder);
    return records.isNotEmpty ? _mapToMessage(records.first.value) : null;
  }

  @override
  Future<DirectMessage?> dmGetLatestMessageByPeer({
    required String ownerPubkey,
    required String peerPubkey,
  }) async {
    await _dbRdy;
    final finder = Finder(
      filter: Filter.and([
        Filter.equals('ownerPubkey', ownerPubkey),
        Filter.equals('peerPubkey', peerPubkey),
      ]),
      sortOrders: [SortOrder('createdAt', false)],
      limit: 1,
    );
    final records = await _msgStore.find(_database, finder: finder);
    return records.isNotEmpty ? _mapToMessage(records.first.value) : null;
  }

  @override
  Future<void> dmDeleteMessage({
    required String ownerPubkey,
    required String giftWrapId,
  }) async {
    await _dbRdy;
    await _msgStore.record(_msgKey(ownerPubkey, giftWrapId)).delete(_database);
  }

  @override
  Future<Set<String>> dmGetPeersWithOutgoingMessages({
    required String ownerPubkey,
    required List<String> peerPubkeys,
  }) async {
    if (peerPubkeys.isEmpty) return {};
    await _dbRdy;
    final finder = Finder(
      filter: Filter.and([
        Filter.equals('ownerPubkey', ownerPubkey),
        Filter.equals('isOutgoing', true),
        Filter.inList('peerPubkey', peerPubkeys),
      ]),
    );
    final records = await _msgStore.find(_database, finder: finder);
    return records.map((r) => r.value['peerPubkey'] as String).toSet();
  }

  @override
  Future<int> dmCountMessages({required String ownerPubkey}) async {
    await _dbRdy;
    return _msgStore.count(
      _database,
      filter: Filter.equals('ownerPubkey', ownerPubkey),
    );
  }

  @override
  Future<void> dmPersistGiftWraps({
    required String ownerPubkey,
    required String messageId,
    required String selfGiftWrapJson,
    String? recipientGiftWrapJson,
  }) async {
    await _dbRdy;
    final key = _msgKey(ownerPubkey, messageId);
    final existing = await _msgStore.record(key).get(_database);
    if (existing != null) {
      final updated = Map<String, Object?>.from(existing);
      updated['selfGiftWrapJson'] = selfGiftWrapJson;
      if (recipientGiftWrapJson != null) {
        updated['recipientGiftWrapJson'] = recipientGiftWrapJson;
      }
      await _msgStore.record(key).put(_database, updated);
    }
  }

  @override
  Future<String?> dmGetGiftWrapJson({
    required String ownerPubkey,
    required String messageId,
    required bool isSelf,
  }) async {
    await _dbRdy;
    final record = await _msgStore
        .record(_msgKey(ownerPubkey, messageId))
        .get(_database);
    if (record == null) return null;
    final field = isSelf ? 'selfGiftWrapJson' : 'recipientGiftWrapJson';
    return record[field] as String?;
  }

  // ============ DM Conversations ============

  Future<DmConversation?> _getConversationWithLastMessage(
    String ownerPubkey,
    Map<String, Object?> convMap,
  ) async {
    final peerPubkey = convMap['peerPubkey'] as String;
    final base = _mapToConversation(convMap);
    final lastMessage = await dmGetLatestMessageByPeer(
      ownerPubkey: ownerPubkey,
      peerPubkey: peerPubkey,
    );
    return DmConversation(
      peerPubkey: base.peerPubkey,
      lastMessageAt: base.lastMessageAt,
      unreadCount: base.unreadCount,
      lastMessagePreview: base.lastMessagePreview,
      lastMessageIsOutgoing: base.lastMessageIsOutgoing,
      lastMessage: lastMessage,
    );
  }

  @override
  Future<List<DmConversation>> dmGetConversations({
    required String ownerPubkey,
  }) async {
    await _dbRdy;
    final finder = Finder(
      filter: Filter.equals('ownerPubkey', ownerPubkey),
      sortOrders: [SortOrder('lastMessageAt', false)],
    );
    final records = await _convStore.find(_database, finder: finder);
    final conversations = await Future.wait(
      records.map((r) => _getConversationWithLastMessage(ownerPubkey, r.value)),
    );
    return conversations.whereType<DmConversation>().toList();
  }

  @override
  Future<DmConversation?> dmGetConversation({
    required String ownerPubkey,
    required String peerPubkey,
  }) async {
    await _dbRdy;
    final record = await _convStore
        .record(_convKey(ownerPubkey, peerPubkey))
        .get(_database);
    if (record == null) return null;
    return _getConversationWithLastMessage(ownerPubkey, record);
  }

  @override
  Future<void> dmPutConversation({
    required String ownerPubkey,
    required DmConversation conversation,
  }) async {
    await _dbRdy;
    final key = _convKey(ownerPubkey, conversation.peerPubkey);
    final map = _conversationToMap(conversation, ownerPubkey);
    await _convStore.record(key).put(_database, map);
  }

  @override
  Future<void> dmMarkConversationRead({
    required String ownerPubkey,
    required String peerPubkey,
  }) async {
    await _dbRdy;
    final key = _convKey(ownerPubkey, peerPubkey);
    final existing = await _convStore.record(key).get(_database);
    if (existing != null) {
      final updated = Map<String, Object?>.from(existing);
      updated['unreadCount'] = 0;
      await _convStore.record(key).put(_database, updated);
    }
  }

  @override
  Future<int> dmGetTotalUnreadCount({required String ownerPubkey}) async {
    await _dbRdy;
    final finder = Finder(filter: Filter.equals('ownerPubkey', ownerPubkey));
    final records = await _convStore.find(_database, finder: finder);
    return records.fold<int>(
      0,
      (sum, r) => sum + (r.value['unreadCount'] as int? ?? 0),
    );
  }

  @override
  Future<void> dmDeleteConversation({
    required String ownerPubkey,
    required String peerPubkey,
  }) async {
    await _dbRdy;
    await _convStore
        .record(_convKey(ownerPubkey, peerPubkey))
        .delete(_database);
  }
}
