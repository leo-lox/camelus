import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain_layer/entities/user_metadata.dart';
import 'metadata_provider.dart';

// state class
class MetadataState {
  final UserMetadata? userMetadata;
  final bool isLoading;

  MetadataState({required this.userMetadata, required this.isLoading});

  MetadataState copyWith({UserMetadata? userMetadata, bool? isLoading}) {
    return MetadataState(
      userMetadata: userMetadata ?? this.userMetadata,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// Create the Notifier
class MetadataStateNotifier extends Notifier<MetadataState> {
  late final String _pubkey;

  MetadataStateNotifier(String pubkey) : _pubkey = pubkey;

  @override
  MetadataState build() {
    _initializeMetadataState();

    return MetadataState(userMetadata: null, isLoading: true);
  }

  Future<void> _initializeMetadataState() async {
    final getUserMetadata = ref.watch(metadataProvider);
    final myMetadataStream = getUserMetadata.getMetadataByPubkey(_pubkey);

    myMetadataStream.listen((data) {
      state = state.copyWith(userMetadata: data, isLoading: false);
    });
  }

  Future<UserMetadata> broadcastMetadata(UserMetadata metadata) {
    final getUserMetadata = ref.read(metadataProvider);
    return getUserMetadata.broadcastMetadata(metadata);
  }

  void setMetadata(UserMetadata newMetadata) {
    state = state.copyWith(userMetadata: newMetadata);
  }
}

/// arg is pubkey
final metadataStateProvider =
    NotifierProvider.family<MetadataStateNotifier, MetadataState, String>(
      MetadataStateNotifier.new,
    );
