import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../../domain_layer/entities/voice/voice_server.dart';
import '../../../domain_layer/entities/voice/voice_room.dart';
import '../../../domain_layer/usecases/voice/voice_discovery.dart';
import '../ndk_provider.dart';

/// Provider for voice discovery use case
final voiceDiscoveryProvider = Provider<VoiceDiscovery>((ref) {
  final ndk = ref.watch(ndkProvider);
  return VoiceDiscovery(ndk);
});

/// State for voice servers list
class VoiceServersState {
  final List<VoiceServer> servers;
  final bool isLoading;
  final String? error;
  final String? regionFilter;
  final String? countryFilter;

  VoiceServersState({
    this.servers = const [],
    this.isLoading = false,
    this.error,
    this.regionFilter,
    this.countryFilter,
  });

  VoiceServersState copyWith({
    List<VoiceServer>? servers,
    bool? isLoading,
    String? error,
    String? regionFilter,
    String? countryFilter,
  }) {
    return VoiceServersState(
      servers: servers ?? this.servers,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      regionFilter: regionFilter ?? this.regionFilter,
      countryFilter: countryFilter ?? this.countryFilter,
    );
  }
}

/// Provider for managing voice servers list
class VoiceServersNotifier extends StateNotifier<VoiceServersState> {
  final VoiceDiscovery _discovery;

  VoiceServersNotifier(this._discovery) : super(VoiceServersState());

  Future<void> loadServers() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final servers = await _discovery.getAvailableServers(
        region: state.regionFilter,
        country: state.countryFilter,
      );
      state = state.copyWith(servers: servers, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  void setRegionFilter(String? region) {
    state = state.copyWith(regionFilter: region);
    loadServers();
  }

  void setCountryFilter(String? country) {
    state = state.copyWith(countryFilter: country);
    loadServers();
  }
}

final voiceServersProvider =
    StateNotifierProvider<VoiceServersNotifier, VoiceServersState>((ref) {
  final discovery = ref.watch(voiceDiscoveryProvider);
  return VoiceServersNotifier(discovery);
});

/// State for voice rooms of a selected server
class VoiceRoomsState {
  final List<VoiceRoom> rooms;
  final bool isLoading;
  final String? error;

  VoiceRoomsState({
    this.rooms = const [],
    this.isLoading = false,
    this.error,
  });

  VoiceRoomsState copyWith({
    List<VoiceRoom>? rooms,
    bool? isLoading,
    String? error,
  }) {
    return VoiceRoomsState(
      rooms: rooms ?? this.rooms,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Provider for managing voice rooms
class VoiceRoomsNotifier extends StateNotifier<VoiceRoomsState> {
  final String serverAddress;
  final http.Client _httpClient;

  VoiceRoomsNotifier(this.serverAddress, this._httpClient)
      : super(VoiceRoomsState());

  Future<void> loadRooms() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _httpClient.get(
        Uri.parse('http://$serverAddress/rooms'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final rooms = data.map((json) => VoiceRoom.fromJson(json)).toList();
        state = state.copyWith(rooms: rooms, isLoading: false);
      } else {
        state = state.copyWith(
          error: 'Failed to load rooms: ${response.statusCode}',
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  @override
  void dispose() {
    _httpClient.close();
    super.dispose();
  }
}

final voiceRoomsProvider = StateNotifierProvider.family<VoiceRoomsNotifier,
    VoiceRoomsState, String>((ref, serverAddress) {
  return VoiceRoomsNotifier(serverAddress, http.Client());
});
