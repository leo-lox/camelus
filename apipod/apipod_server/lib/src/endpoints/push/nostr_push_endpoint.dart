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
import 'package:web_socket_channel/web_socket_channel.dart';

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

  final List<StreamSubscription> _subscriptions = [];

  Timer? relayPoolRestartTimer;

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
      // Migrate existing subscriptions to include kinds
      await migrateExistingSubscriptions(session);
      await _restartRelayPool();
    } finally {
      await session.close(); // Always close sessions
    }

    // Set up periodic cache cleaning
    Timer.periodic(Duration(minutes: 1), (_) => _cleanCache());
  }

  /// helper method to execute operations with fresh sessions
  /// creates a new session for the given operation
  Future<T> _withSession<T>(Future<T> Function(Session session) operation,
      {final bool enableLogging = false}) async {
    _pod ??= Serverpod.instance;

    final session = await _pod!.createSession(
      enableLogging: enableLogging,
    );
    try {
      return await operation(session);
    } finally {
      await session.close();
    }
  }

  Future<bool> register(
    Session session,
    String token,
    List<ndk.Nip01EventModel> events,
  ) async {
    List<Map<String, dynamic>> processed = [];
    bool newRelays = false;

    for (final eventModel in events) {
      // Convert model to entity for signature verification
      final event = eventModel;
      bool veryOk = await verifyEvent(event);

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

      // Extract kinds from event tags
      final kindsTags = event.tags
          .where((tag) => tag[0] == 'kind' && tag.length > 1)
          .map((tag) => int.tryParse(tag[1]))
          .whereType<int>()
          .toList();

      // Filter kinds to available ones
      final validKinds = kindsTags
          .where((kind) => PushConfig.availableKinds.contains(kind))
          .toList();

      // If no kinds specified, default to all available kinds
      final kindsToRegister =
          validKinds.isEmpty ? PushConfig.availableKinds : validKinds;

      final int endIndex = min(relayTags.length, maxRelaysRegistration);
      final relayTagsShort = relayTags.sublist(0, endIndex);

      if (veryOk && relayTags.isNotEmpty) {
        newRelays = await checkIfThereIsANewRelay(session, relayTagsShort);

        // Register in database with kinds
        for (final relayUrl in relayTagsShort) {
          try {
            // Check if subscription already exists
            final existing = await PushSubscription.db.find(
              session,
              where: (t) =>
                  t.pubKey.equals(event.pubKey) &
                  t.relay.equals(relayUrl) &
                  t.token.equals(tokenTag[1]),
            );

            if (existing.isEmpty) {
              await PushSubscription.db.insertRow(
                session,
                PushSubscription(
                  pubKey: event.pubKey,
                  relay: relayUrl,
                  token: tokenTag[1],
                  kinds: kindsToRegister,
                ),
              );
            } else {
              // Update existing subscription with new kinds
              await PushSubscription.db.updateRow(
                session,
                existing.first.copyWith(kinds: kindsToRegister),
              );
            }
          } catch (e) {
            session.log('Error registering subscription: $e');
          }
        }
      } else {
        session
            .log('Invalid registration: $veryOk, $tokenTag, $relayTagsShort');
      }

      processed.add({
        'pubkey': event.pubKey,
        'added': veryOk && relayTagsShort.isNotEmpty
      });
      session.log(
          'pubkey added: ${event.pubKey}, $tokenTag, $relayTagsShort, kinds: $kindsToRegister');
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

  /// Get the registration state for a public key with signature verification
  /// The event must be signed by the pubKey and contain the pubKey to verify
  Future<Map<String, dynamic>> getRegistrationState(
    Session session,
    String signedEventJson,
  ) async {
    try {
      // Parse the signed event
      final eventMap = jsonDecode(signedEventJson) as Map<String, dynamic>;
      final eventModel = ndk.Nip01EventModel.fromJson(eventMap);

      // Convert model to entity for signature verification
      final event = eventModel;

      // Verify the event signature
      bool veryOk = await verifyEvent(event);
      if (!veryOk) {
        return {
          'success': false,
          'error': 'Invalid signature',
        };
      }

      // Get subscription data for this pubKey
      final subscriptions =
          await getSubscriptionsByPubKey(session, event.pubKey);

      if (subscriptions.isEmpty) {
        return {
          'success': true,
          'pubKey': event.pubKey,
          'subscriptions': [],
        };
      }

      // Format response
      final formattedSubscriptions = subscriptions.entries
          .map((entry) => {
                'relay': entry.key,
                'kinds': entry.value,
              })
          .toList();

      return {
        'success': true,
        'pubKey': event.pubKey,
        'subscriptions': formattedSubscriptions,
        'availableKinds': PushConfig.availableKinds,
      };
    } catch (e) {
      session.log(
        level: LogLevel.error,
        'Error getting registration state: $e',
      );
      return {
        'success': false,
        'error': 'Invalid request: $e',
      };
    }
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
    await _withSession(enableLogging: false, (session) async {
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

      // Get the subscribed kinds for this user and relay
      final subscribedKinds =
          await getKindsByPubKeyAndRelay(session, pubkeyTag[1], relay.url);

      // Check if the event kind is in the user's subscribed kinds
      if (!subscribedKinds.contains(event.kind)) {
        session.log(
            'Event kind ${event.kind} not in subscribed kinds $subscribedKinds for ${pubkeyTag[1]}');
        return;
      }

      final tokens = await getTokensByPubKey(session, pubkeyTag[1]);
      final tokensAsUrls =
          tokens.where((token) => isValidHttpUrl(token)).toList();
      final firebaseTokens =
          tokens.where((token) => !tokensAsUrls.contains(token)).toList();

      if (tokens.isEmpty) {
        return;
      }

      _withSession(enableLogging: true, (s) async {
        s.log(
            "fcm msg, all_tokens: ${tokens.toString()}, fcm_tokens: ${firebaseTokens.toString()}");
      });

      final wrappedEvent = await ndk.GiftWrap.wrapEvent(
        recipientPublicKey: pubkeyTag[1],
        sealEvent: event,
      );

      final wrappedEventModel = ndk.Nip01EventModel.fromEntity(wrappedEvent);

      final stringifiedWrappedEventToPush = wrappedEventModel.toJsonString();

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
                  level: LogLevel.error,
                  'Error posting to NTFY: ${stringifiedWrappedEventToPush.length} chars. $tokenUrl ${response.statusCode} ${response.reasonPhrase}');
              await deleteToken(session, tokenUrl);
            }
          } catch (err) {
            session.log(
                level: LogLevel.error,
                'Error posting to NTFY: ${stringifiedWrappedEventToPush.length} chars. $tokenUrl $err');
            // delete tokens on error
            await deleteToken(session, tokenUrl);
          }
        }
        session.log(
            level: LogLevel.info,
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
              _withSession(enableLogging: true, (s) async {
                if (!resp.success) {
                  s.log(
                      level: LogLevel.error,
                      'Failed: ${resp.error?.code} ${resp.error?.message} ${jsonEncode(message).length} chars');
                  if (resp.error?.code ==
                          'messaging/registration-token-not-registered' ||
                      resp.error?.code == 'messaging/internal-error') {
                    s.log(
                        level: LogLevel.info, 'Deleting Token ${tokens[idx]}');
                    await deleteToken(session, tokens[idx]);
                  }
                }
              });
            });
          }
        } catch (e) {
          session.log(level: LogLevel.error, 'Firebase messaging error: $e');
        }

        session.log(
            level: LogLevel.info,
            'Firebase New kind ${event.kind} event for ${pubkeyTag[1]} with ${stringifiedWrappedEventToPush.length} bytes');
      }
    });
  }

  Future<void> _restartRelayPool() async {
    if (_isInRelayPoolFunction) return;
    _isInRelayPoolFunction = true;

    /// restart pool in 4 hours
    // relayPoolRestartTimer?.cancel();
    // relayPoolRestartTimer = Timer(Duration(hours: 4), () {
    //   _restartRelayPool();
    // });

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
        _relayPool = RelayPool(relays,
            options: RelayOptions(
              reconnectFilter: PushConfig.subscriptionFilter,
              reconnectSubId: PushConfig.subscriptionId,
            ));

        // Set up event handlers using the new stream-based approach
        _relayPool!.onOpen.listen((relay) {
          _withSession(enableLogging: true, (s) async {
            s.log(level: LogLevel.info, "onOpen.listen ${relay.url}");
            s.log(
                level: LogLevel.info,
                "relayPool relays: ${_relayPool!.myRelays.length}");
          });

          // Subscribe to specific event kinds when a relay connects
          relay.subscribe(
            PushConfig.subscriptionId,
            PushConfig.subscriptionFilter,
          );
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
              _withSession(enableLogging: true, (s) async {
                s.log(level: LogLevel.error, 'Error handling event: $e');
              });
            }
          }),
        );

        _subscriptions.add(
          _relayPool!.onError.listen((relayError) async {
            final relay = relayError.relay;
            final error = relayError.error;

            final message = error.message;

            await _withSession(enableLogging: true, (s) async {
              s.log(
                  level: LogLevel.error,
                  ".onError.listen, relay: ${relay.url} error: $error");
              s.log(
                level: LogLevel.error,
                "$message",
                exception: message,
              );
              if (message is WebSocketException) {
                s.log(
                  level: LogLevel.error,
                  "${message.httpStatusCode}, ${message.message}, ",
                  exception: message.message,
                );
              }
              if (message is WebSocketChannelException) {
                s.log(
                  level: LogLevel.error,
                  "myWebSocketChannelException: ${message.inner}, ${message.message}",
                  exception: message.message,
                );
              }

              s.log(
                  level: LogLevel.info,
                  "relayPool relays: ${_relayPool!.myRelays.length}");

              s.log(
                  level: LogLevel.info,
                  "relayPool relays: ${_relayPool!.myRelays.map((e) => e.url)}");
            });

            try {
              if (!isSupportedUrl(relay.url) ||
                  error.toString().contains('Failed host lookup') ||
                  error.message.toString().contains('ECONNREFUSED') ||
                  error.message
                      .toString()
                      .contains('Invalid WebSocket frame: FIN must be set') ||
                  error.message
                      .toString()
                      .contains("The URL's protocol must be one of") ||
                  error.message
                      .toString()
                      .contains("to many reconnection attempts")) {
                _relayPool!.remove(relay.url);

                await _withSession(enableLogging: true, (s) async {
                  s.log("deleting relay: ${relay.url}");
                  await deleteRelay(s, relay.url);
                });
              }
            } catch (e) {
              await _withSession(enableLogging: true, (s) async {
                s.log("contains err: $e");
              });
            }
          }),
        );

        _subscriptions.add(
          _relayPool!.onClose.listen((relayClose) async {
            final relay = relayClose.url;

            await _withSession(enableLogging: true, (s) async {
              s.log(
                  level: LogLevel.warning,
                  "relay closed $relay, ${relayClose.closeReason}");
            });
          }),
        );

        _subscriptions.add(
          _relayPool!.onNotice.listen((relayNotice) async {
            final relay = relayNotice.relay;
            final msg = relayNotice.message;
            await _withSession(enableLogging: true, (s) async {
              s.log(
                  level: LogLevel.warning,
                  "relayNotice from ${relay.url}, msg: $msg");
            });
          }),
        );

        await _withSession(enableLogging: true, (s) async {
          s.log(
              level: LogLevel.info,
              'Restarted pool with ${relays.length} relays');
        });
      });
    } finally {
      _isInRelayPoolFunction = false;
    }
  }
}
