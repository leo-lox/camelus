import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:dart_firebase_admin/dart_firebase_admin.dart';
import 'package:dart_firebase_admin/messaging.dart';
import 'package:serverpod/serverpod.dart';
import 'package:http/http.dart' as http;
import 'package:ndk/ndk.dart' as ndk;
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../config/otso_push_config.dart';
import '../../generated/protocol.dart';
import '../push/nostr_utils.dart';
import '../push/relay.dart';
import '../push/relay_pool.dart';
import 'otso_database_operations.dart';
import 'otso_helpers.dart';

const int maxRelaysRegistration = 4;

class OtsoPushEndpoint extends Endpoint {
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
    List<ndk.Nip01EventModel> events,
  ) async {
    List<Map<String, dynamic>> processed = [];
    bool newRelays = false;

    for (final event in events) {
      bool veryOk = await verifyEvent(event);

      final tokenTag = event.tags.firstWhere(
        (tag) => tag[0] == 'challenge' && tag.length > 1,
      );

      if (tokenTag.isEmpty) {
        return false;
      }

      final userFcmToken = tokenTag[1];

      final geoTags = event.tags
          .where((tag) => tag[0] == 'g' && tag.length > 1)
          .map((tag) => tag[1])
          .toSet()
          .toList();

      final relayTags = event.tags
          .where((tag) =>
              tag[0] == 'relay' &&
              tag.length > 1 &&
              tag[1].length > 1 &&
              isSupportedUrl(tag[1]))
          .map((tag) => tag[1])
          .toSet() // Remove duplicates
          .toList();

      if (veryOk && geoTags.isNotEmpty) {
        /// sync with db
        // Fetch existing geoTags from the database for this event
        final existingGeoTagsTable =
            await getAllGeohashesPubkey(session: session, pubkey: event.pubKey);
        final existingGeoTags = existingGeoTagsTable.map((e) => e.geohash);

        // Calculate tags to add and remove
        final tagsToAdd =
            geoTags.where((tag) => !existingGeoTags.contains(tag)).toList();
        final tagsToRemove =
            existingGeoTags.where((tag) => !geoTags.contains(tag)).toList();

        // Add new tags
        if (tagsToAdd.isNotEmpty) {
          await insertGeotags(
            session: session,
            pubkey: event.pubKey,
            geotags: tagsToAdd,
          );
        }

        // Remove outdated tags
        if (tagsToRemove.isNotEmpty) {
          await deleteGeotags(
            session: session,
            pubkey: event.pubKey,
            geotags: tagsToRemove,
          );
        }
      } else {
        await deletePubkeyAnywhere(
          session: session,
          pubkey: event.pubKey,
        );
      }

      final int endIndex = min(relayTags.length, maxRelaysRegistration);
      final relayTagsShort = relayTags.sublist(0, endIndex);

      if (veryOk && relayTags.isNotEmpty) {
        newRelays = await checkIfThereIsANewRelay(session, relayTagsShort);

        final existingRelaysTable = await OtsoPushSubscription.db.find(
          session,
          where: (r) =>
              r.relay.inSet(relayTagsShort.toSet()) &
              r.pubkey.equals(event.pubKey),
        );
        final existingRelays = existingRelaysTable.map((e) => e.relay);

        final relaysToAdd = relayTagsShort
            .where((relay) => !existingRelays.contains(relay))
            .toList();
        final relaysToRemove = existingRelays
            .where((relay) => !existingRelays.contains(relay))
            .toList();

        // Register in database
        for (final relayUrl in relaysToAdd) {
          await OtsoPushSubscription.db.insertRow(
              session,
              OtsoPushSubscription(
                  pubkey: event.pubKey, relay: relayUrl, token: userFcmToken));
        }

        for (final relayUrl in relaysToRemove) {
          await OtsoPushSubscription.db.deleteWhere(session,
              where: (r) =>
                  r.pubkey.equals(event.pubKey) & r.relay.equals(relayUrl));
        }

        /// delete old pubkeys (e.g. on app reset):
        final existingRelaysTableToken = await OtsoPushSubscription.db.find(
          session,
          where: (r) => r.token.equals(userFcmToken),
        );
        final pubkeysToRemove = existingRelaysTableToken
            .where((t) => t.pubkey != event.pubKey)
            .toList();

        for (final pubkeyToRemove in pubkeysToRemove) {
          try {
            await OtsoPushSubscription.db.deleteWhere(session,
                where: (r) => r.pubkey.equals(pubkeyToRemove.pubkey));
          } catch (_) {}
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
    ///todo debu get logging false
    await _withSession(enableLogging: true, (session) async {
      session.log("notify!", level: LogLevel.debug);

      /// get the geotag with most presicion
      String eventGeoTag = OtsoHelpers.findLongestGValue(event.tags);

      session.log("geotag: ${eventGeoTag}", level: LogLevel.debug);

      final pubkeysToNotify =
          await getPubkeysToNotify(geoHash: eventGeoTag, session: session);

      session.log("pubkeystoNotify: ${pubkeysToNotify}", level: LogLevel.debug);

      /// send all devices their gift wrap event
      for (final devicePubkeyToNotify in pubkeysToNotify) {
        final tokens = await getTokensByPubKey(session, devicePubkeyToNotify);
        final tokensAsUrls =
            tokens.where((token) => isValidHttpUrl(token)).toList();
        final firebaseTokens =
            tokens.where((token) => !tokensAsUrls.contains(token)).toList();

        if (tokens.isEmpty) {
          // nothing to notify delete geo sub
          try {
            await OtsoGeoSubscription.db.deleteWhere(
              session,
              where: (r) => r.pubkey.equals(event.pubKey),
            );
          } catch (_) {}

          return;
        }

        _withSession(enableLogging: true, (s) async {
          s.log(
              "fcm msg, all_tokens: ${tokens.toString()}, fcm_tokens: ${firebaseTokens.toString()}");
        });

        final wrappedEvent = await ndk.GiftWrap.wrapEvent(
          recipientPublicKey: devicePubkeyToNotify,
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
              'NTFY New kind ${event.kind} event for $devicePubkeyToNotify with ${stringifiedWrappedEventToPush.length} bytes');
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
                          level: LogLevel.info,
                          'Deleting Token ${tokens[idx]}');
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
              'Firebase New kind ${event.kind} event for $devicePubkeyToNotify with ${stringifiedWrappedEventToPush.length} bytes');
        }
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
        if (!relays.contains(OtsoPushConfig.bootstrapRelay)) {
          // add at least on relay to keep the session alive (first startup)
          relays.add(OtsoPushConfig.bootstrapRelay);
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
              reconnectFilter: OtsoPushConfig.subscriptionFilter,
              reconnectSubId: OtsoPushConfig.subscriptionId,
            ));

        // Set up event handlers
        _subscriptions.add(
          _relayPool!.onOpen.listen((relay) {
            _withSession(enableLogging: true, (s) async {
              s.log(level: LogLevel.info, "onOpen.listen ${relay.url}");
              s.log(
                  level: LogLevel.info,
                  "relayPool relays: ${_relayPool!.myRelays.length}");
            });

            // Subscribe to specific event kinds when a relay connects
            relay.subscribe(
              OtsoPushConfig.subscriptionId,
              OtsoPushConfig.subscriptionFilter,
            );
          }),
        );

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
                "${message}",
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
                      .contains("too many reconnection attempts")) {
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
