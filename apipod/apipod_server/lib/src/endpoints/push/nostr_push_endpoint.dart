import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:apipod_server/src/endpoints/push/relay_pool.dart';
import 'package:dart_firebase_admin/dart_firebase_admin.dart';
import 'package:dart_firebase_admin/messaging.dart';
import 'package:serverpod/serverpod.dart';
import 'package:http/http.dart' as http;

import '../../generated/protocol.dart';
import 'database_operations.dart';
import 'nostr_utils.dart';
import 'relay.dart';

class NostrPushEndpoint extends Endpoint {
  // Cache implementation
  final Map<String, DateTime> _sentCache = {};
  final int _maxCacheSize = 5000;
  final Duration _cacheTtl = Duration(minutes: 5);

  RelayPool? _relayPool;
  bool _isInRelayPoolFunction = false;

  late final FirebaseAdminApp _firebaseAdminApp;
  late final Messaging _firebaseMessaging;

  @override
  void initialize(Server server, String name, String? moduleName) {
    super.initialize(server, name, moduleName);

    final projectId = Platform.environment['FIREBASE_PROJECT_ID'];

    if (projectId == null) {
      throw Exception("no FIREBASE_PROJECT_ID set");
    }

    // long lived instance
    _firebaseAdminApp = FirebaseAdminApp.initializeApp(
        projectId, Credential.fromApplicationDefaultCredentials());

    // admin.useEmulator();

    _firebaseMessaging = Messaging(_firebaseAdminApp);
  }

  // Clean expired cache entries
  void _cleanCache() {
    final now = DateTime.now();
    _sentCache
        .removeWhere((_, timestamp) => now.difference(timestamp) > _cacheTtl);

    // If still too large, remove oldest entries
    if (_sentCache.length > _maxCacheSize) {
      final sortedEntries = _sentCache.entries.toList()
        ..sort((a, b) => a.value.compareTo(b.value));

      for (int i = 0; i < sortedEntries.length - _maxCacheSize; i++) {
        _sentCache.remove(sortedEntries[i].key);
      }
    }
  }

  Future<void> onServerStart(InternalSession session) async {
    await _restartRelayPool(session);

    // Set up periodic cache cleaning
    Timer.periodic(Duration(minutes: 1), (_) => _cleanCache());
  }

  Future<List<Map<String, dynamic>>> register(
    Session session,
    String token,
    List<Map<String, dynamic>> events,
  ) async {
    List<Map<String, dynamic>> processed = [];
    bool newRelays = false;

    for (final event in events) {
      bool veryOk = verifyEvent(event);

      final tokenTag = event['tags'].firstWhere(
          (tag) => tag[0] == 'challenge' && tag.length > 1,
          orElse: () => null);

      final relayTags = event['tags']
          .where((tag) =>
              tag[0] == 'relay' &&
              tag.length > 1 &&
              tag[1].length > 1 &&
              isSupportedUrl(tag[1]))
          .map((tag) => tag[1])
          .toSet() // Remove duplicates
          .toList();

      if (tokenTag != null &&
          tokenTag[1] != null &&
          veryOk &&
          relayTags.isNotEmpty) {
        newRelays = await checkIfThereIsANewRelay(session, relayTags);

        // Register in database
        for (final relayUrl in relayTags) {
          await PushSubscription.db.insertRow(
              session,
              PushSubscription(
                  pubKey: event['pubkey'],
                  relay: relayUrl,
                  token: tokenTag[1]));
        }
      } else {
        session.log('Invalid registration: $veryOk, $tokenTag, $relayTags');
      }

      processed.add({
        'pubkey': event['pubkey'],
        'added': tokenTag != null && veryOk && relayTags.isNotEmpty
      });
    }

    if (newRelays) {
      await _restartRelayPool(session);
    }

    return processed;
  }

  bool isValidUrl(String urlString) {
    try {
      Uri.parse(urlString);
      return true;
    } catch (e) {
      return false;
    }
  }

  bool isSupportedUrl(String url) {
    return !url.contains("brb.io") && // no broken relays
        !url.contains("echo.websocket.org") && // test relay
        !url.contains("127.0") && // no local relays
        !url.contains("umbrel.local") && // no local relays
        !url.contains("192.168.") && // no local relays
        !url.contains(".onion") && // we are not running on Tor
        !url.contains("https://") && // not a websocket
        !url.contains("http://") && // not a websocket
        !url.contains("www://") && // not a websocket
        !url.contains("https//") && // not a websocket
        !url.contains("http//") && // not a websocket
        !url.contains("www//") && // not a websocket
        !url.contains("npub1") && // does not allow custom uris
        !url.contains("was://") && // common misspellings
        !url.contains("ws://umbrel:") && // local domain
        !url.contains("\t") && // tab is not allowed
        !url.contains(" ") && // space is not allowed
        isValidUrl(url);
  }

  bool isValidHttpUrl(String urlString) {
    try {
      final uri = Uri.parse(urlString);
      return uri.scheme == 'http' || uri.scheme == 'https';
    } catch (e) {
      return false;
    }
  }

  Future<void> _notify(
    Session session,
    Map<String, dynamic> event,
    Relay relay,
  ) async {
    final pubkeyTag = event['tags'].firstWhere(
        (tag) => tag[0] == 'p' && tag.length > 1,
        orElse: () => null);

    if (pubkeyTag != null && pubkeyTag[1] != null) {
      final tokens = await getTokensByPubKey(session, pubkeyTag[1]);
      final tokensAsUrls =
          tokens.where((token) => isValidHttpUrl(token)).toList();
      final firebaseTokens =
          tokens.where((token) => !tokensAsUrls.contains(token)).toList();

      if (tokens.isNotEmpty) {
        final wrappedEvent = createWrap(pubkeyTag[1], event);
        final stringifiedWrappedEventToPush = jsonEncode(wrappedEvent);

        // Send to HTTP URLs
        if (tokensAsUrls.isNotEmpty) {
          for (final tokenUrl in tokensAsUrls) {
            try {
              final response = await http
                  .post(
                    Uri.parse(tokenUrl),
                    body: stringifiedWrappedEventToPush,
                  )
                  .timeout(Duration(seconds: 5));

              if (response.statusCode != 200) {
                session.log(
                    'Error posting to NTFY: ${stringifiedWrappedEventToPush.length} chars. $tokenUrl ${response.statusCode} ${response.reasonPhrase}');
                await deleteToken(session, tokenUrl);
              }
            } catch (err) {
              session.log(
                  'Error posting to NTFY: ${stringifiedWrappedEventToPush.length} chars. $tokenUrl $err');
              // Uncomment to delete tokens on error
              // await deleteToken(session, tokenUrl);
            }
          }
          session.log(
              'NTFY New kind ${event['kind']} event for ${pubkeyTag[1]} with ${stringifiedWrappedEventToPush.length} bytes');
        }

        // Send to Firebase
        if (firebaseTokens.isNotEmpty) {
          final message = {
            'encryptedEvent': stringifiedWrappedEventToPush,
          };

          try {
            final response =
                await _firebaseMessaging.sendEachForMulticast(MulticastMessage(
              tokens: firebaseTokens,
              data: message,
            ));

            if (response.failureCount > 0) {
              response.responses.asMap().forEach((idx, resp) {
                if (!resp.success) {
                  session.log(
                      'Failed: ${resp.error?.code} ${resp.error?.message} ${jsonEncode(message).length} chars');
                  if (resp.error?.code ==
                      'messaging/registration-token-not-registered') {
                    session.log('Deleting Token ${tokens[idx]}');
                    deleteToken(session, tokens[idx]);
                  }
                }
              });
            }
          } catch (e) {
            session.log('Firebase messaging error: $e');
          }

          session.log(
              'Firebase New kind ${event['kind']} event for ${pubkeyTag[1]} with ${stringifiedWrappedEventToPush.length} bytes');
        }
      }
    }
  }

  Future<void> _restartRelayPool(Session session) async {
    if (_isInRelayPoolFunction) return;
    _isInRelayPoolFunction = true;

    try {
      final relays = await getAllRelays(session);

      if (_relayPool != null) {
        final hasNewRelay = relays.any((relay) => !_relayPool!.has(relay));
        if (!hasNewRelay) {
          _isInRelayPoolFunction = false;
          return;
        }
      }

      if (_relayPool != null) {
        _relayPool!.close();
      }

      _relayPool = RelayPool(relays, {'reconnect': true});

      _relayPool!.on('open', (relay) {
        relay.subscribe('subid', {
          'kinds': [4, 9735, 1059],
          'limit': 1
        });
      });

      _relayPool!.on('eose', (relay) {
        // End of stored events
      });

      _relayPool!.on('event', (relay, subId, ev) {
        try {
          if (_sentCache.containsKey(ev['id'])) return;
          _sentCache[ev['id']] = DateTime.now();

          _notify(session, ev, relay);
        } catch (e) {
          session.log('Error handling event: $e');
        }
      });

      _relayPool!.on('error', (relay, e) {
        if (!isSupportedUrl(relay.url) ||
            e.toString().contains('Invalid URL') ||
            e.toString().contains('ECONNREFUSED') ||
            e.toString().contains('Invalid WebSocket frame: FIN must be set') ||
            e.toString().contains("The URL's protocol must be one of")) {
          _relayPool!.remove(relay.url);
          deleteRelay(session, relay.url);
        }
      });

      session.log('Restarted pool with ${relays.length} relays');
    } finally {
      _isInRelayPoolFunction = false;
    }
  }

  Map<String, dynamic> createWrap(
      String recipientPubkey, Map<String, dynamic> event,
      [List<List<String>> tags = const []]) {
    final wrapperPrivkey = generateSecretKey();

    final wrapTemplate = {
      'kind': 1059,
      'created_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'tags': tags,
      'content': nip44.encrypt(jsonEncode(event),
          nip44.getConversationKey(wrapperPrivkey, recipientPubkey))
    };

    return finalizeEvent(wrapTemplate, wrapperPrivkey);
  }
}
