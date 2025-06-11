import 'package:serverpod/serverpod.dart';
import 'dart:math';
import '../../generated/protocol.dart';

class LinkShorterEndpoint extends Endpoint {
  Future<String> shortInvite(
    Session session, {
    required String invitedByNpub,
    required String listName,
    required String listNpub,
  }) async {
    //  check if an invite with these parameters already exists
    final existing = await ShortLinkInviteData.db.findFirstRow(
      session,
      where: (t) =>
          t.invitedByNpub.equals(invitedByNpub) &
          t.listName.equals(listName) &
          t.listNpub.equals(listNpub),
    );

    // return the existing short link
    if (existing != null) {
      return existing.shortLink;
    }

    final shortInvitePrefix = "s";

    //  doesn't exist, create a new one
    String shortLink = _generateShortLink(prefix: shortInvitePrefix);

    //  trying until we get a unique short link
    while (await _shortLinkExists(session, shortLink)) {
      shortLink = _generateShortLink(prefix: shortInvitePrefix);
    }

    final insert = await ShortLinkInviteData.db.insertRow(
      session,
      ShortLinkInviteData(
        shortLink: shortLink,
        createdAt: DateTime.now(),
        invitedByNpub: invitedByNpub,
        listName: listName,
        listNpub: listNpub,
      ),
    );

    return insert.shortLink;
  }

  // Helper method to generate a random short link
  String _generateShortLink({int length = 8, String prefix = ""}) {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    final myValues = String.fromCharCodes(Iterable.generate(
        length, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
    return "$prefix$myValues";
  }

  //  method to check if short link already exists
  Future<bool> _shortLinkExists(Session session, String shortLink) async {
    final existing = await ShortLinkInviteData.db.findFirstRow(
      session,
      where: (t) => t.shortLink.equals(shortLink),
    );
    return existing != null;
  }

  /// get short link and track usage
  Future<ShortLinkInviteData?> getInviteByShortLink(
    Session session, {
    required String shortLink,
  }) async {
    final foundData = await session.caches.local.get(
      "shortLinkInvite-$shortLink",
      CacheMissHandler(
        () async => await ShortLinkInviteData.db.findFirstRow(
          session,
          where: (t) => t.shortLink.equals(shortLink),
        ),
        lifetime: Duration(minutes: 10),
      ),
    );

    // statistics tracking
    if (foundData != null) {
      _trackUsageAsync(session, shortLink);
    }

    if (foundData == null) {
      return null;
    }

    // dont return everything
    return foundData.copyWith(
      usageCount: 0,
      createdAt: null,
      lastUsed: null,
      id: null,
    );
  }

  // async method that doesn't block the main response
  void _trackUsageAsync(Session session, String shortLink) {
    // Don't await this - let it run in background
    Future(() async {
      try {
        await _incrementUsageCount(session, shortLink);
      } catch (e) {
        // log error but don't let it affect the main flow
        session.log('Failed to track usage for $shortLink: $e');
      }
    });
  }

  Future<void> _incrementUsageCount(Session session, String shortLink,
      [int increment = 1]) async {
    try {
      await session.db.transaction((transaction) async {
        // find existing record within the transaction
        final existing = await ShortLinkInviteData.db.findFirstRow(
          session,
          where: (t) => t.shortLink.equals(shortLink),
          transaction: transaction,
        );

        if (existing != null) {
          // Update existing record
          final updated = existing.copyWith(
            usageCount: existing.usageCount + increment,
            lastUsed: DateTime.now(),
          );

          await ShortLinkInviteData.db.updateRow(
            session,
            updated,
            transaction: transaction,
          );
        }
      });
    } catch (e) {
      session.log('Failed to increment usage count for $shortLink: $e',
          level: LogLevel.warning);
    }
  }
}
