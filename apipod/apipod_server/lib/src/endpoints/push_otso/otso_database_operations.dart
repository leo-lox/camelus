import 'package:serverpod/serverpod.dart';
import '../../generated/protocol.dart';

Future<bool> checkIfThereIsANewRelay(
    Session session, List<String> relays) async {
  for (final relay in relays) {
    final count = await OtsoPushSubscription.db
        .count(session, where: (t) => t.relay.equals(relay));

    if (count == 0) {
      return true;
    }
  }

  return false;
}

Future<void> registerInDatabaseTuples(
    Session session, List<List<String>> tuples) async {
  for (final tuple in tuples) {
    if (tuple.length == 3) {
      final pubkey = tuple[0];
      final relay = tuple[1];
      final token = tuple[2];

      try {
        await OtsoPushSubscription.db.insertRow(session,
            OtsoPushSubscription(pubKey: pubkey, relay: relay, token: token));
      } catch (e) {
        // Handle unique constraint violation
        if (e.toString().contains('unique constraint')) {
          session.log('Subscription already exists: $pubkey, $relay, $token');
        } else {
          rethrow;
        }
      }
    }
  }
}

Future<List<String>> getAllKeys(Session session) async {
  final subscriptions = await OtsoPushSubscription.db.find(session);
  return subscriptions.map((s) => s.pubKey).toSet().toList();
}

Future<List<String>> getAllRelays(Session session) async {
  final subscriptions = await OtsoPushSubscription.db.find(session);
  return subscriptions.map((s) => s.relay).toSet().toList();
}

Future<List<String>> getTokensByPubKey(Session session, String pubKey) async {
  final subscriptions = await OtsoPushSubscription.db
      .find(session, where: (t) => t.pubKey.equals(pubKey));

  return subscriptions.map((s) => s.token).toSet().toList();
}

Future<void> deleteToken(Session session, String token) async {
  await OtsoPushSubscription.db
      .deleteWhere(session, where: (t) => t.token.equals(token));
}

Future<void> deleteRelay(Session session, String relay) async {
  await OtsoPushSubscription.db
      .deleteWhere(session, where: (t) => t.relay.equals(relay));
}

Future<List<String>> getPubkeysToNotify({
  required Session session,
  required String geoHash,
}) async {
  final query =
      await OtsoGeoSubscription.db.find(session, where: (subscription) {
    return subscription.geohash.like('$geoHash%');
  });
  return query.map((q) => q.pubKey).toSet().toList();
}

Future<List<OtsoGeoSubscription>> getAllGeohashesPubkey({
  required Session session,
  required String pubkey,
}) async {
  final query = await OtsoGeoSubscription.db.find(
    session,
    where: (p0) => p0.pubKey.equals(pubkey),
  );
  return query;
}

Future<List<OtsoGeoSubscription>> insertGeotags({
  required Session session,
  required String pubkey,
  required List<String> geotags,
}) async {
  final insert = await OtsoGeoSubscription.db.insert(
    session,
    geotags.map((g) {
      return OtsoGeoSubscription(geohash: g, pubKey: pubkey);
    }).toList(),
  );
  return insert;
}

Future<List<OtsoGeoSubscription>> deleteGeotags({
  required Session session,
  required String pubkey,
  required List<String> geotags,
}) async {
  final del = await OtsoGeoSubscription.db.deleteWhere(
    session,
    where: (r) => r.pubKey.equals(pubkey) & r.geohash.inSet(geotags.toSet()),
  );
  return del;
}

Future<List<OtsoGeoSubscription>> deleteGeoHashSubscription(
    {required Session session, required String geoHash}) async {
  return await OtsoGeoSubscription.db
      .deleteWhere(session, where: (t) => t.geohash.equals(geoHash));
}

Future deletePubkeyAnywhere(
    {required Session session, required String pubkey}) async {
  final transaction = await session.db.transaction((transaction) async {
    await OtsoGeoSubscription.db.deleteWhere(
      session,
      where: (r) => r.pubKey.equals(pubkey),
      transaction: transaction,
    );
    await OtsoPushSubscription.db.deleteWhere(
      session,
      where: (r) => r.pubKey.equals(pubkey),
      transaction: transaction,
    );
  });
  return transaction;
}
