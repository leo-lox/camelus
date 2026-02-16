import 'package:serverpod/serverpod.dart';
import '../../generated/protocol.dart';
import '../../config/push_config.dart';

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
        await PushSubscription.db.insertRow(
            session,
            PushSubscription(
                pubKey: pubkey,
                relay: relay,
                token: token,
                kinds: PushConfig.availableKinds));
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

// Get subscription kinds for a pubKey and relay
Future<List<int>> getKindsByPubKeyAndRelay(
    Session session, String pubKey, String relay) async {
  final subscriptions = await PushSubscription.db.find(
    session,
    where: (t) => t.pubKey.equals(pubKey) & t.relay.equals(relay),
  );

  if (subscriptions.isEmpty) {
    return [];
  }

  // Return the kinds from the first subscription (there should only be one per pubKey+relay combo)
  return subscriptions.first.kinds ?? PushConfig.availableKinds;
}

// Get all subscriptions with their kinds for a pubKey
Future<Map<String, List<int>>> getSubscriptionsByPubKey(
    Session session, String pubKey) async {
  final subscriptions = await PushSubscription.db
      .find(session, where: (t) => t.pubKey.equals(pubKey));

  final result = <String, List<int>>{};
  for (final sub in subscriptions) {
    result[sub.relay] = sub.kinds ?? PushConfig.availableKinds;
  }

  return result;
}

// Update kinds for a subscription
Future<void> updateSubscriptionKinds(
    Session session, String pubKey, String relay, List<int> kinds) async {
  await PushSubscription.db.updateWhere(
    session,
    where: (t) => t.pubKey.equals(pubKey) & t.relay.equals(relay),
    columnValues: (col) => [col.kinds(kinds)],
  );
}

// Migrate existing subscriptions to include all kinds
Future<void> migrateExistingSubscriptions(Session session) async {
  final subscriptions = await PushSubscription.db.find(session);

  for (final sub in subscriptions) {
    if (sub.kinds == null || sub.kinds!.isEmpty) {
      final updated = sub.copyWith(kinds: PushConfig.availableKinds);
      await PushSubscription.db.updateRow(session, updated);
    }
  }
}

Future<void> deleteToken(Session session, String token) async {
  await PushSubscription.db
      .deleteWhere(session, where: (t) => t.token.equals(token));
}

Future<void> deleteRelay(Session session, String relay) async {
  await PushSubscription.db
      .deleteWhere(session, where: (t) => t.relay.equals(relay));
}
