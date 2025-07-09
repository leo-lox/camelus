import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_geohash/dart_geohash.dart';
import 'package:http/http.dart' as http;
import 'package:ndk/ndk.dart';
import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';

const source =
    "https://padlet.com/api/10/wishes?wall_hashid=board_YjMXnWQK1VbayND5";

const prodRelays = ['wss://relay.damus.io', 'wss://nos.lol'];
const isProd = true;

const waitBetweenPublish = Duration(seconds: 2);

const syncIntervall = Duration(minutes: 5);

class OtsoExternalSyncEndpoint extends Endpoint {
  Serverpod? _pod;
  Future<void> onServerStart(Serverpod pod) async {
    _pod ??= Serverpod.instance;

    Timer.periodic(syncIntervall, (timer) {
      _sync();
    });
  }

  Future<void> _sync() async {
    await _withSession(enableLogging: true, (session) async {
      session.log("start sync", level: LogLevel.debug);
      final freshData = await _getData();
      if (freshData == null) {
        return -1;
      }

      final dataIds = freshData.map((w) => w.id).toList();

      final tableIds = await OtsoExternalSync.db.find(
        session,
        where: (t) => t.itemId.inSet(dataIds.toSet()),
      );

      final tableItemIdSet = tableIds.map((t) => t.itemId).toSet();
      final notInDb =
          freshData.where((w) => !tableItemIdSet.contains(w.id)).toList();

      final now = DateTime.now();
      try {
        await OtsoExternalSync.db.insert(
            session,
            notInDb
                .map((n) => OtsoExternalSync(itemId: n.id, syncedAt: now))
                .toList());
      } catch (_) {}

      await _nostrPublish(notInDb);
      session.log("got ${notInDb.length} new locations", level: LogLevel.debug);
    });
  }

  Future<void> _nostrPublish(List<Wish> toPublish) async {
    final ndk = Ndk(
      NdkConfig(
        cache: MemCacheManager(),
        eventVerifier: Bip340EventVerifier(),
        bootstrapRelays: isProd ? prodRelays : ["ws://localhost:10547"],
      ),
    );

    final nostrPrivateKey = Platform.environment['OTSO_NOSTR_PRIV_KEY'];
    final nostrPublicKey = Platform.environment['OTSO_NOSTR_PUB_KEY'];

    if (nostrPrivateKey == null || nostrPublicKey == null) {
      throw Exception("missing nostr keys");
    }

    ndk.accounts
        .loginPrivateKey(pubkey: nostrPublicKey, privkey: nostrPrivateKey);

    final nostrEventsToPublish = toPublish.map((w) {
      DateTime postCreatedAt = DateTime.parse(w.createdAt);

      final now = postCreatedAt.millisecondsSinceEpoch ~/ 1000;

      final in24h = now + (24 * 60 * 60);

      final locationGeoHash =
          GeoHash.fromDecimalDegrees(w.longitude, w.latitude);

      return Nip01Event(
        pubKey: nostrPublicKey,
        kind: 6472,
        createdAt: now,
        tags: [
          ["l", "Ice"],
          ["client", "icebreaker"],
          ["expiration", "$in24h"],
          ..._geoHashTags(locationGeoHash.geohash),
        ],
        content: "${_removeHtmlTags(w.body)}",
      );
    });

    for (final note in nostrEventsToPublish) {
      final broadcast = ndk.broadcast.broadcast(nostrEvent: note);
      await broadcast.broadcastDoneFuture;
      // rate limits
      await Future.delayed(waitBetweenPublish);
    }
  }

  String _removeHtmlTags(String input) {
    return input.replaceAll(RegExp(r'<[^>]*>'), '');
  }

  List<List<String>> _geoHashTags(String geohash, {String? prefix}) {
    final List<List<String>> result = [];
    final String firstChar = prefix ?? "g";

    for (int i = geohash.length; i > 0; i--) {
      String substring = geohash.substring(0, i);
      result.add([firstChar, substring]);
    }

    return result;
  }

  Future<List<Wish>?> _getData() async {
    final response = await http.get(Uri.parse(source));
    if (response.statusCode != 200) {
      print(response.statusCode);
      print(response.reasonPhrase);
      return null;
    }

    final body = response.body;

    final parsed = parseWishes(body);

    return parsed;
  }

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
}

class Wish {
  final int id;
  final String locationName;
  final String body;
  final String permalink;
  final String createdAt;
  final double longitude;
  final double latitude;

  Wish({
    required this.id,
    required this.locationName,
    required this.body,
    required this.permalink,
    required this.createdAt,
    required this.latitude,
    required this.longitude,
  });

  factory Wish.fromJson(Map<String, dynamic> json) {
    final attributes = json['attributes'];
    return Wish(
      id: attributes['id'],
      locationName: attributes['location_name'],
      body: attributes['body'],
      permalink: attributes['permalink'],
      createdAt: attributes['created_at'],
      latitude: attributes['location_point']['latitude'],
      longitude: attributes['location_point']['longitude'],
    );
  }

  @override
  String toString() {
    return 'Wish(id: $id, locationName: $locationName, body: $body, permalink: $permalink, createdAt: $createdAt)';
  }
}

List<Wish> parseWishes(String responseBody) {
  final parsed = jsonDecode(responseBody);
  final List<dynamic> data = parsed['data'];
  return data.map((json) => Wish.fromJson(json)).toList();
}
