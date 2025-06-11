import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:apipod_server/src/endpoints/push/relay_pool.dart';
import 'package:dart_firebase_admin/dart_firebase_admin.dart';
import 'package:dart_firebase_admin/messaging.dart';
import 'package:serverpod/serverpod.dart';
import 'package:http/http.dart' as http;
import 'package:ndk/ndk.dart' as ndk;

import '../../config/push_config.dart';
import '../../generated/protocol.dart';
import 'database_operations.dart';
import 'nostr_utils.dart';
import 'relay.dart';

const int maxRelaysRegistration = 4;

class NostrPushEndpoint extends Endpoint {
  Serverpod? _pod; // pod reference

  // Cache implementation
  final Map<String, DateTime> _sentCache = {};
  final int _maxCacheSize = 5000;
  final Duration _cacheTtl = Duration(minutes: 5);

  RelayPool? _relayPool;
  bool _isInRelayPoolFunction = false;

  late final FirebaseAdminApp _firebaseAdminApp;
  late final Messaging _firebaseMessaging;

  List<StreamSubscription> _subscriptions = [];

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

  Future<void> onServerStart(Serverpod pod) async {
    _pod = pod;

    // bg session needs on init
    final projectId = Platform.environment['FIREBASE_PROJECT_ID'];
    _firebaseAdminApp = FirebaseAdminApp.initializeApp(
        projectId!, Credential.fromApplicationDefaultCredentials());
    _firebaseMessaging = Messaging(_firebaseAdminApp);

    final session = await pod.createSession();
    try {
      await _restartRelayPool();
    } finally {
      await session.close(); // Always close sessions
    }

    // Set up periodic cache cleaning
    Timer.periodic(Duration(minutes: 1), (_) => _cleanCache());
  }

  /// helper method to execute operations with fresh sessions
  /// creates a new session for the given operation
  Future<T> _withSession<T>(
      Future<T> Function(Session session) operation) async {
    if (_pod == null) throw Exception('Pod not initialized');

    final session = await _pod!.createSession();
    try {
      return await operation(session);
    } finally {
      await session.close();
    }
  }

  Future<bool> register(
    Session session,
    String token,
    List<ndk.Nip01Event> events,
  ) async {
    List<Map<String, dynamic>> processed = [];
    bool newRelays = false;

    for (final event in events) {
      bool veryOk = verifyEvent(event);

      final tokenTag = event.tags.firstWhere(
        (tag) => tag[0] == 'challenge' && tag.length > 1,
      );

      final relayTags = event.tags
          .where((tag) =>
              tag[0] == 'relay' &&
              tag.length > 1 &&
              tag[1].length > 1 &&
              isSupportedUrl(tag[1]))
          .map((tag) => tag[1])
          .toSet() // Remove duplicates
          .toList();

      final int endIndex = min(relayTags.length, maxRelaysRegistration);
      final relayTagsShort = relayTags.sublist(0, endIndex);

      if (veryOk && relayTags.isNotEmpty) {
        newRelays = await checkIfThereIsANewRelay(session, relayTagsShort);

        // Register in database
        for (final relayUrl in relayTagsShort) {
          await PushSubscription.db.insertRow(
              session,
              PushSubscription(
                  pubKey: event.pubKey, relay: relayUrl, token: tokenTag[1]));
        }
      } else {
        session
            .log('Invalid registration: $veryOk, $tokenTag, $relayTagsShort');
      }

      processed.add({
        'pubkey': event.pubKey,
        'added': veryOk && relayTagsShort.isNotEmpty
      });
      session.log('pubkey added: ${event.pubKey}, $tokenTag, $relayTagsShort');
    }

    if (newRelays) {
      await _restartRelayPool();
    }

    return true;
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
    ndk.Nip01Event event,
    Relay relay,
  ) async {
    await _withSession((session) async {
      /// get the last added pubkey (usually the direct reply)
      List<String> pubkeyTag;
      try {
        pubkeyTag = event.tags.lastWhere(
          (tag) => tag[0] == 'p' && tag.length > 1,
        );
      } catch (e) {
        return;
      }

      if (event.pTags.length > PushConfig.maxPubkeyPerEvent) {
        // hellthread prevention
        return;
      }

      final tokens = await getTokensByPubKey(session, pubkeyTag[1]);
      final tokensAsUrls =
          tokens.where((token) => isValidHttpUrl(token)).toList();
      final firebaseTokens =
          tokens.where((token) => !tokensAsUrls.contains(token)).toList();

      if (tokens.isNotEmpty) {
        final wrappedEvent = await ndk.GiftWrap.wrapEvent(
          recipientPublicKey: pubkeyTag[1],
          sealEvent: event,
        );

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
              // delete tokens on error
              await deleteToken(session, tokenUrl);
            }
          }
          session.log(
              'NTFY New kind ${event.kind} event for ${pubkeyTag[1]} with ${stringifiedWrappedEventToPush.length} bytes');
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
              response.responses.asMap().forEach((idx, resp) async {
                if (!resp.success) {
                  session.log(
                      'Failed: ${resp.error?.code} ${resp.error?.message} ${jsonEncode(message).length} chars');
                  if (resp.error?.code ==
                      'messaging/registration-token-not-registered') {
                    session.log('Deleting Token ${tokens[idx]}');
                    await deleteToken(session, tokens[idx]);
                  }
                }
              });
            }
          } catch (e) {
            session.log('Firebase messaging error: $e');
          }

          session.log(
              'Firebase New kind ${event.kind} event for ${pubkeyTag[1]} with ${stringifiedWrappedEventToPush.length} bytes');
        }
      }
    });
  }

  Future<void> _restartRelayPool() async {
    if (_isInRelayPoolFunction) return;
    _isInRelayPoolFunction = true;

    for (final sub in _subscriptions) {
      await sub.cancel();
    }
    _subscriptions.clear();

    try {
      await _withSession((session) async {
        final relays = await getAllRelays(session);
        if (!relays.contains(PushConfig.bootstrapRelay)) {
          // add at least on relay to keep the session alive (first startup)
          relays.add(PushConfig.bootstrapRelay);
        }

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

        // Create a new relay pool with the fetched relay URLs
        _relayPool = RelayPool(relays);

        // Set up event handlers using the new stream-based approach
        _relayPool!.onOpen.listen((relay) {
          session.log("onOpen.listen ${relay.url}");
          // Subscribe to specific event kinds when a relay connects
          relay.subscribe(PushConfig.subscriptionId, {
            'kinds': [1],
            'limit': 1
          });
        });

        _subscriptions.add(
          _relayPool!.onEvent.listen((relayEvent) {
            // session.log(
            //     "onEvent.listen, relay: ${relayEvent.relay.url} eventId: ${relayEvent.event.id}");
            try {
              final event = relayEvent.event;

              // Skip if we've already processed this event
              if (_sentCache.containsKey(event.id)) return;
              _sentCache[event.id] = DateTime.now();

              _notify(event, relayEvent.relay);
            } catch (e) {
              session.log('Error handling event: $e');
            }
          }),
        );

        _subscriptions.add(
          _relayPool!.onError.listen((relayError) async {
            session.log(".onError.listen, relay: ${relayError.relay}");
            final relay = relayError.relay;
            final error = relayError.error.toString();

            if (!isSupportedUrl(relay.url) ||
                error.contains('Invalid URL') ||
                error.contains('ECONNREFUSED') ||
                error.contains('Invalid WebSocket frame: FIN must be set') ||
                error.contains("The URL's protocol must be one of")) {
              _relayPool!.remove(relay.url);

              await _withSession((s) async {
                await deleteRelay(s, relay.url);
              });
            }
          }),
        );

        session.log('Restarted pool with ${relays.length} relays');
      });
    } finally {
      _isInRelayPoolFunction = false;
    }
  }
}
