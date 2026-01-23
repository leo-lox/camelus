import 'dart:convert';

import 'package:ndk/entities.dart';

import '../../domain_layer/entities/direct_message.dart';
import '../../domain_layer/entities/nostr_tag.dart';
import '../db/object_box_camelus/schema/db_nip17_message.dart';
import 'nostr_tag_model.dart';

/// Data model for DirectMessage with conversion methods.
class DirectMessageModel extends DirectMessage {
  DirectMessageModel({
    required super.id,
    required super.senderPubkey,
    required super.peerPubkey,
    required super.content,
    required super.createdAt,
    required super.isOutgoing,
    super.tags,
    super.sendStatus,
  });

  /// Create from ObjectBox database entity
  factory DirectMessageModel.fromDb(DbNip17Message db) {
    List<NostrTag> parsedTags = [];
    if (db.tags.isNotEmpty) {
      try {
        final List<dynamic> tagsJson = jsonDecode(db.tags);
        parsedTags = tagsJson
            .map((tag) => NostrTagModel.fromJson(tag as List<dynamic>))
            .toList();
      } catch (_) {
        // Ignore parsing errors, keep empty tags
      }
    }

    return DirectMessageModel(
      id: db.eventId,
      senderPubkey: db.senderPubkey,
      peerPubkey: db.peerPubkey,
      content: db.content,
      createdAt: db.createdAt,
      isOutgoing: db.isOutgoing,
      tags: parsedTags,
      sendStatus: db.sendStatus == 0
          ? MessageSendStatus.pending
          : MessageSendStatus.sent,
    );
  }

  /// Create from an unwrapped NIP-17 rumor event (kind 14) after gift wrap decryption.
  ///
  /// [rumor] - The decrypted rumor event (kind 14)
  /// [giftWrapId] - The ID of the original gift wrap (kind 1059) for caching
  /// [myPubkey] - Current user's pubkey to determine if outgoing
  factory DirectMessageModel.fromUnwrappedRumor({
    required Nip01Event rumor,
    required String giftWrapId,
    required String myPubkey,
  }) {
    // Determine peer pubkey - for outgoing messages it's the recipient (p tag),
    // for incoming messages it's the sender
    final isOutgoing = rumor.pubKey == myPubkey;
    String peerPubkey;

    if (isOutgoing) {
      // We sent this message, peer is the first p tag (recipient)
      final pTags = rumor.pTags;
      peerPubkey = pTags.isNotEmpty ? pTags.first : '';
    } else {
      // We received this message, peer is the sender
      peerPubkey = rumor.pubKey;
    }

    // Parse tags
    final sanitizedTags = rumor.tags.where((tag) => tag.isNotEmpty).toList();
    final parsedTags = sanitizedTags
        .map((tag) => NostrTagModel.fromJson(tag))
        .toList();

    return DirectMessageModel(
      id: giftWrapId,
      senderPubkey: rumor.pubKey,
      peerPubkey: peerPubkey,
      content: rumor.content,
      createdAt: rumor.createdAt,
      isOutgoing: isOutgoing,
      tags: parsedTags,
    );
  }

  /// Convert to ObjectBox database entity
  DbNip17Message toDb() {
    String tagsJson = '';
    if (tags.isNotEmpty) {
      final tagsList = tags.map((tag) => tag.toList()).toList();
      tagsJson = jsonEncode(tagsList);
    }

    return DbNip17Message(
      eventId: id,
      senderPubkey: senderPubkey,
      peerPubkey: peerPubkey,
      content: content,
      createdAt: createdAt,
      tags: tagsJson,
      replyToEventId: replyToEventId,
      isOutgoing: isOutgoing,
      sendStatus: sendStatus == MessageSendStatus.pending ? 0 : 1,
    );
  }

  /// Create from domain entity
  factory DirectMessageModel.fromEntity(DirectMessage message) {
    return DirectMessageModel(
      id: message.id,
      senderPubkey: message.senderPubkey,
      peerPubkey: message.peerPubkey,
      content: message.content,
      createdAt: message.createdAt,
      isOutgoing: message.isOutgoing,
      tags: message.tags,
      sendStatus: message.sendStatus,
    );
  }
}
