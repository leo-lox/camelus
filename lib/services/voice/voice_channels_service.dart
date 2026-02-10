import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain_layer/entities/voice/voice_channel.dart';
import '../../domain_layer/entities/voice/voice_server.dart';

/// Service for fetching channel information from the voice server
class VoiceChannelsService {
  final VoiceServer server;

  VoiceChannelsService(this.server);

  /// Get the channel tree from the server
  Future<List<VoiceChannel>> getChannelTree() async {
    try {
      // Extract host and port from server.host (format: "host:port")
      final hostParts = server.host.split(':');
      final host = hostParts[0];
      final port = hostParts.length > 1 ? hostParts[1] : '8443';

      // Use http (not https) for local testing
      // TODO: Use https in production
      final url = 'http://$host:$port/channels';

      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 5),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        // Parse root channel
        if (data['root'] != null) {
          final root = VoiceChannel.fromJson(data['root'] as Map<String, dynamic>);
          return [root];
        }

        // Fallback: parse channels map
        if (data['channels'] != null) {
          final channelsMap = data['channels'] as Map<String, dynamic>;
          return channelsMap.values
              .map((e) => VoiceChannel.fromJson(e as Map<String, dynamic>))
              .toList();
        }

        return [];
      } else {
        throw Exception('Failed to load channels: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch channel tree: $e');
    }
  }

  /// Get server statistics
  Future<Map<String, dynamic>> getStats() async {
    try {
      final hostParts = server.host.split(':');
      final host = hostParts[0];
      final port = hostParts.length > 1 ? hostParts[1] : '8443';

      final url = 'http://$host:$port/stats';

      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 5),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to load stats: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch stats: $e');
    }
  }
}
