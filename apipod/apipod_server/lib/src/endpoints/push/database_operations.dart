import 'package:serverpod/serverpod.dart';
import '../../generated/protocol.dart';

Future<bool> checkIfThereIsANewRelay(
    Session session, List<String> relays) async {
  for (final relay in relays) {
    final count = await PushSubscription.db
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
        await PushSubscription.db.insertRow(session,
            PushSubscription(pubKey: pubkey, relay: relay, token: token));
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
  final subscriptions = await PushSubscription.db.find(session);
  return subscriptions.map((s) => s.pubKey).toSet().toList();
}

Future<List<String>> getAllRelays(Session session) async {
  final subscriptions = await PushSubscription.db.find(session);
  return subscriptions.map((s) => s.relay).toSet().toList();
}

Future<List<String>> getTokensByPubKey(Session session, String pubKey) async {
  final subscriptions = await PushSubscription.db
      .find(session, where: (t) => t.pubKey.equals(pubKey));

  return subscriptions.map((s) => s.token).toSet().toList();
}

Future<void> deleteToken(Session session, String token) async {
  await PushSubscription.db
      .deleteWhere(session, where: (t) => t.token.equals(token));
}

Future<void> deleteRelay(Session session, String relay) async {
  await PushSubscription.db
      .deleteWhere(session, where: (t) => t.relay.equals(relay));
}
