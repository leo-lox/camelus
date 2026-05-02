import 'dart:async';

import '../../../domain_layer/entities/direct_message.dart';
import '../../../domain_layer/entities/dm_conversation.dart';
import '../../../domain_layer/repositories/app_db.dart';
import '../../../objectbox.g.dart';
import '../../models/direct_message_model.dart';
import 'db_camelus_init.dart';
import 'schema/db_key_value.dart';
import 'schema/db_nip17_conversation.dart';
import 'schema/db_nip17_message.dart';

class DbAppImpl implements AppDb {
  final Completer _initCompleter = Completer();
  Future get _dbRdy => _initCompleter.future;
  late DbCamelusInit _objectBox;

  DbAppImpl() {
    _init();
  }

  Future _init() async {
    final objectbox = await DbCamelusInit.create();
    _objectBox = objectbox;
    _initCompleter.complete();
  }

  /// Get the ObjectBox store for specialized operations (e.g., DMs)
  Future<Store> get store async {
    await _dbRdy;
    return _objectBox.store;
  }

  // ============ Key-Value ============

  @override
  Future<void> clear() async {
    await _dbRdy;
    _objectBox.store.box().removeAll();
  }

  @override
  Future<void> delete(String key) async {
    await _dbRdy;

    // run transaction to get the id of the key and then delete it
    _objectBox.store.runInTransaction(TxMode.write, () {
      final keyBox = _objectBox.store.box<DbKeyValue>();
      final keyToDelete = keyBox
          .query(DbKeyValue_.key.equals(key))
          .build()
          .findFirst();
      if (keyToDelete != null) {
        keyBox.remove(keyToDelete.dbId);
      }
    });
  }

  @override
  Future<String?> read(String key) async {
    await _dbRdy;
    final keyBox = _objectBox.store.box<DbKeyValue>();
    final keyValue = keyBox
        .query(DbKeyValue_.key.equals(key))
        .build()
        .findFirst();
    return Future.value(keyValue?.value);
  }

  @override
  Future<void> save({required String key, required String value}) async {
    await _dbRdy;

    _objectBox.store.runInTransaction(TxMode.write, () {
      // check if key already exists
      final keyBox = _objectBox.store.box<DbKeyValue>();
      final DbKeyValue? keyValue = keyBox
          .query(DbKeyValue_.key.equals(key))
          .build()
          .findFirst();
      // update
      if (keyValue != null) {
        keyValue.value = value;
        _objectBox.store.box<DbKeyValue>().put(keyValue, mode: PutMode.update);
      } else {
        // insert
        final newKeyValue = DbKeyValue(key: key, value: value);
        _objectBox.store.box<DbKeyValue>().put(
          newKeyValue,
          mode: PutMode.insert,
        );
      }
    });
  }

  // ============ DM helpers ============

  DirectMessageModel _dbMsgToEntity(DbNip17Message db) {
    return DirectMessageModel.fromMap({
      'eventId': db.eventId,
      'senderPubkey': db.senderPubkey,
      'peerPubkey': db.peerPubkey,
      'content': db.content,
      'createdAt': db.createdAt,
      'tags': db.tags,
      'isOutgoing': db.isOutgoing,
      'sendStatus': db.sendStatus,
      'recipientGiftWrapId': db.recipientGiftWrapId,
      'failureReason': db.failureReason,
    });
  }

  DbNip17Message _entityToDbMsg(DirectMessage message, String ownerPubkey) {
    final model = DirectMessageModel.fromEntity(message);
    final map = model.toMap(ownerPubkey: ownerPubkey);
    return DbNip17Message(
      ownerPubkey: ownerPubkey,
      eventId: map['eventId'] as String,
      senderPubkey: map['senderPubkey'] as String,
      peerPubkey: map['peerPubkey'] as String,
      content: map['content'] as String,
      createdAt: map['createdAt'] as int,
      tags: map['tags'] as String,
      replyToEventId: map['replyToEventId'] as String?,
      isOutgoing: map['isOutgoing'] as bool,
      sendStatus: map['sendStatus'] as int,
      recipientGiftWrapId: map['recipientGiftWrapId'] as String?,
      failureReason: map['failureReason'] as String?,
    );
  }

  DmConversation _dbConvToEntity(
    DbNip17Conversation db,
    Box<DbNip17Message> messageBox,
    String ownerPubkey,
  ) {
    final msgQuery = messageBox
        .query(
          DbNip17Message_.ownerPubkey.equals(ownerPubkey) &
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
      lastMessage: lastMessageDb != null ? _dbMsgToEntity(lastMessageDb) : null,
    );
  }

  // ============ DM Messages ============

  @override
  Future<void> dmPutMessage({
    required String ownerPubkey,
    required DirectMessage message,
  }) async {
    await _dbRdy;
    final box = _objectBox.store.box<DbNip17Message>();
    _objectBox.store.runInTransaction(TxMode.write, () {
      final existing = box
          .query(
            DbNip17Message_.ownerPubkey.equals(ownerPubkey) &
                DbNip17Message_.eventId.equals(message.id),
          )
          .build()
          .findFirst();
      final dbMsg = _entityToDbMsg(message, ownerPubkey);
      if (existing != null) {
        dbMsg.dbId = existing.dbId;
        // Preserve persisted gift-wrap JSON
        dbMsg.selfGiftWrapJson = existing.selfGiftWrapJson;
        dbMsg.recipientGiftWrapJson = existing.recipientGiftWrapJson;
      }
      box.put(dbMsg);
    });
  }

  @override
  Future<DirectMessage?> dmGetMessage({
    required String ownerPubkey,
    required String giftWrapId,
  }) async {
    await _dbRdy;
    final box = _objectBox.store.box<DbNip17Message>();
    final db = box
        .query(
          DbNip17Message_.ownerPubkey.equals(ownerPubkey) &
              DbNip17Message_.eventId.equals(giftWrapId),
        )
        .build()
        .findFirst();
    return db != null ? _dbMsgToEntity(db) : null;
  }

  @override
  Future<List<DirectMessage>> dmGetMessagesByPeer({
    required String ownerPubkey,
    required String peerPubkey,
  }) async {
    await _dbRdy;
    final box = _objectBox.store.box<DbNip17Message>();
    final query = box
        .query(
          DbNip17Message_.ownerPubkey.equals(ownerPubkey) &
              DbNip17Message_.peerPubkey.equals(peerPubkey),
        )
        .order(DbNip17Message_.createdAt)
        .build();
    final results = query.find();
    query.close();
    return results.map(_dbMsgToEntity).toList();
  }

  @override
  Future<DirectMessage?> dmGetOldestMessage({
    required String ownerPubkey,
  }) async {
    await _dbRdy;
    final box = _objectBox.store.box<DbNip17Message>();
    final query = box
        .query(DbNip17Message_.ownerPubkey.equals(ownerPubkey))
        .order(DbNip17Message_.createdAt)
        .build();
    final db = query.findFirst();
    query.close();
    return db != null ? _dbMsgToEntity(db) : null;
  }

  @override
  Future<DirectMessage?> dmGetOldestMessageByPeer({
    required String ownerPubkey,
    required String peerPubkey,
  }) async {
    await _dbRdy;
    final box = _objectBox.store.box<DbNip17Message>();
    final query = box
        .query(
          DbNip17Message_.ownerPubkey.equals(ownerPubkey) &
              DbNip17Message_.peerPubkey.equals(peerPubkey),
        )
        .order(DbNip17Message_.createdAt)
        .build();
    final db = query.findFirst();
    query.close();
    return db != null ? _dbMsgToEntity(db) : null;
  }

  @override
  Future<DirectMessage?> dmGetLatestMessageByPeer({
    required String ownerPubkey,
    required String peerPubkey,
  }) async {
    await _dbRdy;
    final box = _objectBox.store.box<DbNip17Message>();
    final query = box
        .query(
          DbNip17Message_.ownerPubkey.equals(ownerPubkey) &
              DbNip17Message_.peerPubkey.equals(peerPubkey),
        )
        .order(DbNip17Message_.createdAt, flags: Order.descending)
        .build();
    final db = query.findFirst();
    query.close();
    return db != null ? _dbMsgToEntity(db) : null;
  }

  @override
  Future<void> dmDeleteMessage({
    required String ownerPubkey,
    required String giftWrapId,
  }) async {
    await _dbRdy;
    final box = _objectBox.store.box<DbNip17Message>();
    _objectBox.store.runInTransaction(TxMode.write, () {
      final db = box
          .query(
            DbNip17Message_.ownerPubkey.equals(ownerPubkey) &
                DbNip17Message_.eventId.equals(giftWrapId),
          )
          .build()
          .findFirst();
      if (db != null) box.remove(db.dbId);
    });
  }

  @override
  Future<Set<String>> dmGetPeersWithOutgoingMessages({
    required String ownerPubkey,
    required List<String> peerPubkeys,
  }) async {
    if (peerPubkeys.isEmpty) return {};
    await _dbRdy;
    final box = _objectBox.store.box<DbNip17Message>();
    final query = box
        .query(
          DbNip17Message_.ownerPubkey.equals(ownerPubkey) &
              DbNip17Message_.isOutgoing.equals(true) &
              DbNip17Message_.peerPubkey.oneOf(peerPubkeys),
        )
        .build();
    final messages = query.find();
    query.close();
    return messages.map((m) => m.peerPubkey).toSet();
  }

  @override
  Future<int> dmCountMessages({required String ownerPubkey}) async {
    await _dbRdy;
    final box = _objectBox.store.box<DbNip17Message>();
    return box
        .query(DbNip17Message_.ownerPubkey.equals(ownerPubkey))
        .build()
        .count();
  }

  @override
  Future<void> dmPersistGiftWraps({
    required String ownerPubkey,
    required String messageId,
    required String selfGiftWrapJson,
    String? recipientGiftWrapJson,
  }) async {
    await _dbRdy;
    final box = _objectBox.store.box<DbNip17Message>();
    _objectBox.store.runInTransaction(TxMode.write, () {
      final db = box
          .query(
            DbNip17Message_.ownerPubkey.equals(ownerPubkey) &
                DbNip17Message_.eventId.equals(messageId),
          )
          .build()
          .findFirst();
      if (db != null) {
        db.selfGiftWrapJson = selfGiftWrapJson;
        db.recipientGiftWrapJson = recipientGiftWrapJson;
        box.put(db);
      }
    });
  }

  @override
  Future<String?> dmGetGiftWrapJson({
    required String ownerPubkey,
    required String messageId,
    required bool isSelf,
  }) async {
    await _dbRdy;
    final box = _objectBox.store.box<DbNip17Message>();
    final db = box
        .query(
          DbNip17Message_.ownerPubkey.equals(ownerPubkey) &
              DbNip17Message_.eventId.equals(messageId),
        )
        .build()
        .findFirst();
    if (db == null) return null;
    return isSelf ? db.selfGiftWrapJson : db.recipientGiftWrapJson;
  }

  // ============ DM Conversations ============

  @override
  Future<List<DmConversation>> dmGetConversations({
    required String ownerPubkey,
  }) async {
    await _dbRdy;
    final convBox = _objectBox.store.box<DbNip17Conversation>();
    final msgBox = _objectBox.store.box<DbNip17Message>();
    final query = convBox
        .query(DbNip17Conversation_.ownerPubkey.equals(ownerPubkey))
        .order(DbNip17Conversation_.lastMessageAt, flags: Order.descending)
        .build();
    final results = query.find();
    query.close();
    return results
        .map((db) => _dbConvToEntity(db, msgBox, ownerPubkey))
        .toList();
  }

  @override
  Future<DmConversation?> dmGetConversation({
    required String ownerPubkey,
    required String peerPubkey,
  }) async {
    await _dbRdy;
    final convBox = _objectBox.store.box<DbNip17Conversation>();
    final msgBox = _objectBox.store.box<DbNip17Message>();
    final db = convBox
        .query(
          DbNip17Conversation_.ownerPubkey.equals(ownerPubkey) &
              DbNip17Conversation_.peerPubkey.equals(peerPubkey),
        )
        .build()
        .findFirst();
    return db != null ? _dbConvToEntity(db, msgBox, ownerPubkey) : null;
  }

  @override
  Future<void> dmPutConversation({
    required String ownerPubkey,
    required DmConversation conversation,
  }) async {
    await _dbRdy;
    final box = _objectBox.store.box<DbNip17Conversation>();
    _objectBox.store.runInTransaction(TxMode.write, () {
      final existing = box
          .query(
            DbNip17Conversation_.ownerPubkey.equals(ownerPubkey) &
                DbNip17Conversation_.peerPubkey.equals(conversation.peerPubkey),
          )
          .build()
          .findFirst();
      final db = existing ?? DbNip17Conversation(ownerPubkey: ownerPubkey);
      db.peerPubkey = conversation.peerPubkey;
      db.lastMessageAt = conversation.lastMessageAt;
      db.unreadCount = conversation.unreadCount;
      db.lastMessagePreview = conversation.lastMessagePreview;
      db.lastMessageIsOutgoing = conversation.lastMessageIsOutgoing;
      box.put(db);
    });
  }

  @override
  Future<void> dmMarkConversationRead({
    required String ownerPubkey,
    required String peerPubkey,
  }) async {
    await _dbRdy;
    final box = _objectBox.store.box<DbNip17Conversation>();
    _objectBox.store.runInTransaction(TxMode.write, () {
      final db = box
          .query(
            DbNip17Conversation_.ownerPubkey.equals(ownerPubkey) &
                DbNip17Conversation_.peerPubkey.equals(peerPubkey),
          )
          .build()
          .findFirst();
      if (db != null) {
        db.unreadCount = 0;
        box.put(db);
      }
    });
  }

  @override
  Future<int> dmGetTotalUnreadCount({required String ownerPubkey}) async {
    await _dbRdy;
    final box = _objectBox.store.box<DbNip17Conversation>();
    final conversations = box
        .query(DbNip17Conversation_.ownerPubkey.equals(ownerPubkey))
        .build()
        .find();
    return conversations.fold<int>(0, (sum, c) => sum + c.unreadCount);
  }

  @override
  Future<void> dmDeleteConversation({
    required String ownerPubkey,
    required String peerPubkey,
  }) async {
    await _dbRdy;
    final box = _objectBox.store.box<DbNip17Conversation>();
    _objectBox.store.runInTransaction(TxMode.write, () {
      final db = box
          .query(
            DbNip17Conversation_.ownerPubkey.equals(ownerPubkey) &
                DbNip17Conversation_.peerPubkey.equals(peerPubkey),
          )
          .build()
          .findFirst();
      if (db != null) box.remove(db.dbId);
    });
  }
}
