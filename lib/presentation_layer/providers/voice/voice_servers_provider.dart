import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../domain_layer/entities/voice/voice_server.dart';
import '../../../services/voice/voice_discovery_service.dart';
import '../ndk_provider.dart';

/// Provider for voice discovery service
final voiceDiscoveryServiceProvider = Provider<VoiceDiscoveryService>((ref) {
  final ndk = ref.watch(ndkProvider);
  return VoiceDiscoveryService(ndk);
});

/// Provider for discovering voice servers
/// Pass null for all servers, or a region string for filtered results
final voiceServersProvider = StreamProvider.family<List<VoiceServer>, String?>((
  ref,
  region,
) {
  final discoveryService = ref.watch(voiceDiscoveryServiceProvider);
  return discoveryService.discoverServers(region: region);
});

/// Provider for the currently selected voice server
final selectedVoiceServerProvider = StateProvider<VoiceServer?>((ref) => null);

/// Provider for available regions
final availableRegionsProvider = Provider<List<String>>((ref) {
  return ['eu-west', 'eu-central', 'us-east', 'us-west', 'asia-pacific'];
});

/// Provider for selected region filter
final selectedRegionProvider = StateProvider<String?>((ref) => null);
