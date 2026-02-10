import 'package:ndk/ndk.dart';
import '../../domain_layer/entities/voice/voice_server.dart';

/// Service for discovering voice servers via Nostr
class VoiceDiscoveryService {
  final Ndk ndk;

  VoiceDiscoveryService(this.ndk);

  /// Query voice servers by region (kind 30078)
  Stream<List<VoiceServer>> discoverServers({String? region}) async* {
    final filter = Filter(
      kinds: const [30078], // Voice server announcement
      tags: region != null ? {'region': [region]} : null,
      limit: 20,
    );

    final response = ndk.requests.query(
      filter: filter,
      timeout: const Duration(seconds: 10),
    );

    final servers = <VoiceServer>[];

    await for (final event in response.stream) {
      try {
        final server = VoiceServer.fromNostrEvent(event);
        servers.add(server);

        // Yield updated list after each new server
        yield List.from(servers)
          ..sort((a, b) => a.load.compareTo(b.load));
      } catch (e) {
        // Skip invalid server announcements
        continue;
      }
    }

    // Final yield
    if (servers.isNotEmpty) {
      yield List.from(servers)
        ..sort((a, b) => a.load.compareTo(b.load));
    }
  }

  /// Get all available servers (no region filter)
  Future<List<VoiceServer>> getAllServers() async {
    final servers = <VoiceServer>[];

    await for (final serverList in discoverServers()) {
      return serverList;
    }

    return servers;
  }

  /// Get servers for a specific region
  Future<List<VoiceServer>> getServersByRegion(String region) async {
    final servers = <VoiceServer>[];

    await for (final serverList in discoverServers(region: region)) {
      return serverList;
    }

    return servers;
  }

  /// Get the best server (lowest load)
  Future<VoiceServer?> getBestServer({String? region}) async {
    final servers = await (region != null
        ? getServersByRegion(region)
        : getAllServers());

    if (servers.isEmpty) return null;

    // Sort by load and return the best one
    servers.sort((a, b) => a.load.compareTo(b.load));
    return servers.first;
  }

  /// Subscribe to server status updates (kind 30079)
  Stream<Map<String, dynamic>> subscribeToServerStatus(String serverId) async* {
    final filter = Filter(
      kinds: const [30079], // Server status
      tags: {'d': [serverId]},
    );

    final subscription = ndk.requests.subscription(filter: filter);

    await for (final event in subscription.stream) {
      final status = <String, dynamic>{};

      for (final tag in event.tags) {
        if (tag.length >= 2) {
          final key = tag[0];
          final value = tag[1];

          switch (key) {
            case 'active_users':
              status['activeUsers'] = int.tryParse(value) ?? 0;
              break;
            case 'active_channels':
              status['activeChannels'] = int.tryParse(value) ?? 0;
              break;
            case 'load':
              status['load'] = double.tryParse(value) ?? 0.0;
              break;
            case 'uptime':
              status['uptime'] = int.tryParse(value) ?? 0;
              break;
          }
        }
      }

      yield status;
    }
  }
}
