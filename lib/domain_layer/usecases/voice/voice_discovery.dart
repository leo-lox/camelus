import 'dart:async';
import 'dart:convert';

import 'package:ndk/ndk.dart';

import '../../entities/voice/voice_server.dart';
import '../../entities/voice/voice_room.dart';

/// Use case for discovering voice servers via Nostr
class VoiceDiscovery {
  final Ndk _ndk;
  
  // Nostr event kinds for voice communication
  static const int voiceServerKind = 38001;
  static const int voiceRoomKind = 38002;

  VoiceDiscovery(this._ndk);

  /// Discovers voice servers from Nostr relays
  Stream<VoiceServer> discoverServers({
    String? region,
    String? country,
  }) async* {
    final filter = Nip01Filter(
      kinds: [voiceServerKind],
      limit: 100,
    );

    final subscription = _ndk.requests.subscription(
      filters: [filter],
      cacheRead: true,
      cacheWrite: true,
    );

    await for (final event in subscription.stream) {
      try {
        final server = _parseServerFromEvent(event);
        
        // Apply filters if specified
        if (region != null && server.region != region) continue;
        if (country != null && server.country != country) continue;

        yield server;
      } catch (e) {
        // Skip invalid events
        continue;
      }
    }
  }

  /// Gets rooms for a specific server
  Stream<VoiceRoom> getServerRooms(String serverName) async* {
    final filter = Nip01Filter(
      kinds: [voiceRoomKind],
      limit: 100,
    );

    final subscription = _ndk.requests.subscription(
      filters: [filter],
      cacheRead: true,
      cacheWrite: true,
    );

    await for (final event in subscription.stream) {
      try {
        // Check if this room belongs to the server
        final serverTag = event.tags.firstWhere(
          (tag) => tag.length >= 2 && tag[0] == 'server',
          orElse: () => [],
        );
        
        if (serverTag.isNotEmpty && serverTag[1] == serverName) {
          yield _parseRoomFromEvent(event);
        }
      } catch (e) {
        // Skip invalid events
        continue;
      }
    }
  }

  VoiceServer _parseServerFromEvent(Nip01Event event) {
    final content = jsonDecode(event.content) as Map<String, dynamic>;
    
    return VoiceServer(
      id: event.pubkey,
      name: content['name'] ?? '',
      description: content['description'] ?? '',
      host: content['host'] ?? '',
      port: content['port'] ?? 7880,
      region: content['region'] ?? '',
      country: content['country'] ?? '',
      maxUsers: content['maxUsers'] ?? 100,
      lastSeen: DateTime.fromMillisecondsSinceEpoch(event.createdAt * 1000),
    );
  }

  VoiceRoom _parseRoomFromEvent(Nip01Event event) {
    final content = jsonDecode(event.content) as Map<String, dynamic>;
    
    List<VoiceUser> users = [];
    if (content['users'] != null) {
      users = (content['users'] as List)
          .map((u) => VoiceUser.fromJson(u))
          .toList();
    }
    
    return VoiceRoom(
      id: content['id'] ?? '',
      name: content['name'] ?? '',
      description: content['description'] ?? '',
      maxUsers: content['maxUsers'] ?? 50,
      userCount: content['userCount'] ?? 0,
      isPublic: content['isPublic'] ?? true,
      users: users,
    );
  }

  /// Gets a list of all available servers (one-time fetch)
  Future<List<VoiceServer>> getAvailableServers({
    String? region,
    String? country,
  }) async {
    final servers = <String, VoiceServer>{};
    
    // Add timeout to prevent hanging and limit results
    final subscription = discoverServers(region: region, country: country)
        .timeout(
          const Duration(seconds: 10),
          onTimeout: (sink) => sink.close(),
        )
        .take(100); // Limit to 100 servers max
    
    await for (final server in subscription) {
      servers[server.id] = server;
    }
    
    return servers.values.toList()
      ..sort((a, b) => b.lastSeen.compareTo(a.lastSeen));
  }
}
