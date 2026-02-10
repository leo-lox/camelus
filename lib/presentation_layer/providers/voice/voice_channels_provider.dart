import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../domain_layer/entities/voice/voice_channel.dart';
import '../../../services/voice/voice_channels_service.dart';
import 'voice_servers_provider.dart';

/// Provider for voice channels service
final voiceChannelsServiceProvider = Provider<VoiceChannelsService?>((ref) {
  final server = ref.watch(selectedVoiceServerProvider);
  if (server == null) return null;
  return VoiceChannelsService(server);
});

/// Provider for channel tree
final channelTreeProvider = FutureProvider<List<VoiceChannel>>((ref) async {
  final service = ref.watch(voiceChannelsServiceProvider);
  if (service == null) {
    throw Exception('No server selected');
  }
  return service.getChannelTree();
});

/// Provider for current channel (the one user is in)
final currentChannelProvider = StateProvider<VoiceChannel?>((ref) => null);

/// Provider for users in a specific channel
final channelUsersProvider = Provider.family<List<String>, String?>((ref, channelId) {
  if (channelId == null) return [];

  final channelsAsync = ref.watch(channelTreeProvider);

  return channelsAsync.when(
    data: (channels) {
      // Find channel by ID (recursive search)
      VoiceChannel? findChannel(List<VoiceChannel> channels, String id) {
        for (final channel in channels) {
          if (channel.id == id) return channel;
          final found = findChannel(channel.children, id);
          if (found != null) return found;
        }
        return null;
      }

      final channel = findChannel(channels, channelId);
      return channel?.userPubkeys ?? [];
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Provider for server stats
final serverStatsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final service = ref.watch(voiceChannelsServiceProvider);
  if (service == null) {
    throw Exception('No server selected');
  }
  return service.getStats();
});
