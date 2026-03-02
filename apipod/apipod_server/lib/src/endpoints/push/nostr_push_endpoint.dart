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
import 'trend_processor.dart';

const int maxRelaysRegistration = 4;

class NostrPushEndpoint extends Endpoint {
  Serverpod? _pod;
  final TrendProcessor _trendProcessor = TrendProcessor();

  // Cache implementation
  final Map<String, DateTime> _sentCache = {};
  final int _maxCacheSize = 5000;
  final Duration _cacheTtl = Duration(minutes: 5);

  RelayPool? _relayPool;
  bool _isInRelayPoolFunction = false;
  bool _pendingRestart = false; // Track if a restart was requested while busy

  late final FirebaseAdminApp _firebaseAdminApp;
  late final Messaging _firebaseMessaging;

  final List<StreamSubscription> _subscriptions = [];

  Timer? relayPoolRestartTimer;
  Timer? _cacheCleanTimer;

  @override
  void initialize(Server server, String name, String? moduleName) {
    super.initialize(server, name, moduleName);

    final projectId = Platform.environment['FIREBASE_PROJECT_ID'];

    if (projectId == null) {
      throw Exception("no FIREBASE_PROJECT_ID set");
    }

    _firebaseAdminApp = FirebaseAdminApp.initializeApp(
        projectId, Credential.fromApplicationDefaultCredentials());

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

    final projectId = Platform.environment['FIREBASE_PROJECT_ID'];
    _firebaseAdminApp = FirebaseAdminApp.initializeApp(
        projectId!, Credential.fromApplicationDefaultCredentials());
    _firebaseMessaging = Messaging(_firebaseAdminApp);

    final session = await pod.createSession();
    try {
      await migrateExistingSubscriptions(session);
      await _restartRelayPool();
    } finally {
      await session.close();
    }

    // Set up periodic cache cleaning
    _cacheCleanTimer?.cancel();
    _cacheCleanTimer =
        Timer.periodic(Duration(minutes: 1), (_) => _cleanCache());
  }

  /// Helper method to execute operations with fresh sessions
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
          .toSet()
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
    return !url.contains("brb.io") &&
        !url.contains("echo.websocket.org") &&
        !url.contains("127.0") &&
        !url.contains("umbrel.local") &&
        !url.contains("192.168.") &&
        !url.contains(".onion") &&
        !url.contains("https://") &&
        !url.contains("http://") &&
        !url.contains("www://") &&
        !url.contains("https//") &&
        !url.contains("http//") &&
        !url.contains("www//") &&
        !url.contains("npub1") &&
        !url.contains("was://") &&
        !url.contains("ws://umbrel:") &&
        !url.contains("\t") &&
        !url.contains(" ") &&
        isValidUrl(url);
  }

  /// Get the registration state for a public key with signature verification
  Future<Map<String, dynamic>> getRegistrationState(
    Session session,
    String signedEventJson,
  ) async {
    try {
      final eventMap = jsonDecode(signedEventJson) as Map<String, dynamic>;
      final eventModel = ndk.Nip01EventModel.fromJson(eventMap);
      final event = eventModel;

      bool veryOk = await verifyEvent(event);
      if (!veryOk) {
        return {
          'success': false,
          'error': 'Invalid signature',
        };
      }

      final subscriptions =
          await getSubscriptionsByPubKey(session, event.pubKey);

      if (subscriptions.isEmpty) {
        return {
          'success': true,
          'pubKey': event.pubKey,
          'subscriptions': [],
        };
      }

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
      // Get the last added pubkey (usually the direct reply)
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
      final subscribedKinds = await getKindsByPubKey(session, pubkeyTag[1]);

      // Check if the event kind is in the user's subscribed kinds
      if (!subscribedKinds.contains(event.kind)) {
        session.log(
            'Event kind ${event.kind} not in subscribed kinds $subscribedKinds for ${pubkeyTag[1]}',
            level: LogLevel.debug);
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

      await _withSession(enableLogging: true, (s) async {
        s.log(
            "fcm msg, all_tokens: ${tokens.toString()}, pubkey: ${pubkeyTag[1]}, relay: ${relay.url}, event kind: ${event.kind}, event id: ${event.id}",
            level: LogLevel.debug);
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
          final response = await _firebaseMessaging.sendEachForMulticast(
            MulticastMessage(
              tokens: firebaseTokens,
              data: message,

              // Keep iOS data-only so the app can parse encryptedEvent
              // and create its own local notification in background.
              // notification: null,
              // apns: ApnsConfig(
              //   headers: {
              //     'apns-priority':
              //         '10', // 10 is for immediate, 5 is for background
              //     'apns-push-type': 'alert', // background
              //   },
              //   payload: ApnsPayload(
              //     aps: Aps(
              //       contentAvailable: true,
              //     ),
              //   ),
              // ),
            ),
          );

          if (response.failureCount > 0) {
            // Use indexed for loop and await each deletion
            for (int idx = 0; idx < response.responses.length; idx++) {
              final resp = response.responses[idx];
              if (!resp.success) {
                session.log(
                    level: LogLevel.error,
                    'Failed: ${resp.error?.code} ${resp.error?.message} ${jsonEncode(message).length} chars');
                if (resp.error?.code ==
                        'messaging/registration-token-not-registered' ||
                    resp.error?.code == 'messaging/internal-error') {
                  // Use the correct token from firebaseTokens and the current session
                  session.log(
                      level: LogLevel.info,
                      'Deleting Token ${firebaseTokens[idx]}');
                  await deleteToken(session, firebaseTokens[idx]);
                }
              }
            }
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

  Future<void> _processTrendEvent(ndk.Nip01Event event, Relay relay) async {
    if (event.kind != 1) {
      return;
    }

    await _withSession(enableLogging: false, (session) async {
      await _trendProcessor.processKind1Event(
        session: session,
        event: event,
      );
    });
  }

  Future<void> _restartRelayPool() async {
    if (_isInRelayPoolFunction) {
      // Mark that a restart is pending so we retry after the current one finishes
      _pendingRestart = true;
      return;
    }
    _isInRelayPoolFunction = true;
    _pendingRestart = false;

    for (final sub in _subscriptions) {
      await sub.cancel();
    }
    _subscriptions.clear();

    try {
      await _withSession((session) async {
        final relays = await getAllRelays(session);
        if (!relays.contains(PushConfig.bootstrapRelay)) {
          relays.add(PushConfig.bootstrapRelay);
        }

        if (_relayPool != null) {
          final hasNewRelay = relays.any((relay) => !_relayPool!.has(relay));
          if (!hasNewRelay) {
            return;
          }
        }

        if (_relayPool != null) {
          _relayPool!.close();
        }

        _relayPool = RelayPool(relays,
            options: RelayOptions(
              reconnectFilter: PushConfig.subscriptionFilter,
              reconnectSubId: PushConfig.subscriptionId,
            ));

        _relayPool!.onOpen.listen((relay) {
          _withSession(enableLogging: true, (s) async {
            s.log(level: LogLevel.info, "onOpen.listen ${relay.url}");
            s.log(
                level: LogLevel.info,
                "relayPool relays: ${_relayPool!.myRelays.length}");
          });

          relay.subscribe(
            PushConfig.subscriptionId,
            PushConfig.subscriptionFilter,
          );
        });

        _subscriptions.add(
          _relayPool!.onEvent.listen((relayEvent) async {
            try {
              final event = relayEvent.event;

              // Skip if we've already processed this event
              if (_sentCache.containsKey(event.id)) return;
              _sentCache[event.id] = DateTime.now();

              // Await _notify so errors are caught and backpressure is respected
              await _notify(event, relayEvent.relay);
              await _processTrendEvent(event, relayEvent.relay);
            } catch (e) {
              await _withSession(enableLogging: true, (s) async {
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

      // If a restart was requested while we were busy, do it now
      if (_pendingRestart) {
        await _restartRelayPool();
      }
    }
  }
}
