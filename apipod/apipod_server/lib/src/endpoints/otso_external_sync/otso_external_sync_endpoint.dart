import 'dart:async';
import 'dart:io';

import 'package:dart_geohash/dart_geohash.dart';
import 'package:http/http.dart' as http;
import 'package:ndk/ndk.dart' hide LogLevel;
import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import 'models/otso_sync_model.dart';
import 'models/otso_sync_wish_model.dart';
import 'models/otso_sync_xml_model.dart';

const stopIceUrl =
    "https://stopice.net/login/?recentmapdata=1&duration=since_yesterday";

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
      final Map<String, List<OtsoSyncModel>> sources = {};

      final stopiceData = await _getData(
        url: stopIceUrl,
        parseMethod: OtsoSyncXmlModel.parse,
      );
      if (stopiceData != null) {
        sources["stopice"] = stopiceData;
      }

      final Map<String, List<OtsoSyncModel>> dataToPublish = {};

      for (final mySourceKey in sources.keys) {
        final dataIds = sources[mySourceKey]!.map((w) => w.id).toList();

        final tableIds = await OtsoExternalSync.db.find(
          session,
          where: (t) =>
              t.itemId.inSet(dataIds.toSet()) & t.source.equals(mySourceKey),
        );

        final tableItemIdSet = tableIds.map((t) => t.itemId).toSet();
        final notInDb = sources[mySourceKey]!
            .where((w) => !tableItemIdSet.contains(w.id))
            .toList();

        final now = DateTime.now();
        try {
          await OtsoExternalSync.db.insert(
              session,
              notInDb
                  .map((n) => OtsoExternalSync(
                        itemId: n.id,
                        syncedAt: now,
                        source: n.source,
                      ))
                  .toList());
        } catch (_) {}

        dataToPublish[mySourceKey] = notInDb;
      }

      List<OtsoSyncModel> flattenedList =
          dataToPublish.values.expand((list) => list).toList();
      await _nostrPublish(flattenedList);
      session.log(
        "Got ${flattenedList.length} new locations. Source breakdown: \n ${dataToPublish.entries.map((entry) => "${entry.key}: ${entry.value.length} ").join(", ")}",
        level: LogLevel.debug,
      );
    });
  }

  Future<void> _nostrPublish(List<OtsoSyncModel> toPublish) async {
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

    final nostrEventsToPublish = toPublish.map((r) {
      final in24h = r.createdAt + (24 * 60 * 60);

      final locationGeoHash =
          GeoHash.fromDecimalDegrees(r.longitude, r.latitude);

      return Nip01Event(
        pubKey: nostrPublicKey,
        kind: 6472,
        createdAt: r.createdAt,
        tags: [
          ["l", "Ice"],
          ["client", "icebreaker"],
          ["expiration", "$in24h"],
          ..._geoHashTags(locationGeoHash.geohash),
        ],
        content: "${_removeHtmlTags(r.body)}",
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

  Future<List<OtsoSyncModel>?> _getData({
    required String url,
    required List<OtsoSyncModel> Function(String body) parseMethod,
  }) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      print(response.statusCode);
      print(response.reasonPhrase);
      return null;
    }

    final body = response.body;

    final parsed = parseMethod(body);

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
