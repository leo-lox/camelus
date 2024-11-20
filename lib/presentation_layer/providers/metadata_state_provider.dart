import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain_layer/entities/user_metadata.dart';
import '../../domain_layer/usecases/get_user_metadata.dart';
import 'metadata_provider.dart';

// state class
class MetadataState {
  final UserMetadata? userMetadata;
  final bool isLoading;

  MetadataState({
    required this.userMetadata,
    required this.isLoading,
  });

  MetadataState copyWith({UserMetadata? userMetadata, bool? isLoading}) {
    return MetadataState(
      userMetadata: userMetadata ?? this.userMetadata,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// Create the StateNotifier
class MetadataStateNotifier extends StateNotifier<MetadataState> {
  final GetUserMetadata _getUserMetadata;
  final String _pubkey;

  MetadataStateNotifier(
    this._getUserMetadata,
    this._pubkey,
  ) : super(MetadataState(userMetadata: null, isLoading: true)) {
    _initializeMetadataState();
  }

  Future<void> _initializeMetadataState() async {
    final myMetadataStream = _getUserMetadata.getMetadataByPubkey(_pubkey);

    myMetadataStream.listen((data) {
      state = state.copyWith(userMetadata: data, isLoading: false);
    });
  }

  Future<UserMetadata> broadcastMetadata(UserMetadata metadata) {
    return _getUserMetadata.broadcastMetadata(metadata);
  }
}

/// arg is pubkey
final metadataStateProvider =
    StateNotifierProvider.family<MetadataStateNotifier, MetadataState, String>(
  (ref, arg) {
    final metadataP = ref.watch(metadataProvider);
    return MetadataStateNotifier(metadataP, arg);
  },
);
