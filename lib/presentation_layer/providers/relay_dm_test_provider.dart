import 'dart:developer';

import 'package:flutter_riverpod/legacy.dart';
import 'package:ndk/entities.dart';
import 'package:ndk/ndk.dart';

import '../../domain_layer/entities/key_pair.dart';
import '../../helpers/bip340.dart';
import 'ndk_provider.dart';

/// Result of a relay deletion support test
enum RelayDeletionSupport {
  /// Relay deleted the event successfully
  supported,

  /// Relay did not delete the event
  notSupported,

  /// Relay rejects kind 1059 (gift wrap) events
  relayRejectsGiftWrap,

  /// Relay rejects deletion requests
  relayRejectsDeletion,

  /// Network error during the test
  networkError,

  /// Test timed out
  timeout,

  /// Other error during test
  otherError,

  /// Test is in progress
  testing,

  /// Not tested yet
  unknown,
}

/// Result of a relay privacy test
enum RelayPrivacySupport {
  /// Relay correctly restricts gift wrap access to p-tag recipient only
  private,

  /// Relay leaks gift wraps to anyone who queries
  leaksToEveryone,

  /// Relay rejects kind 1059 (gift wrap) events
  relayRejectsGiftWrap,

  /// Network error during the test
  networkError,

  /// Test timed out
  timeout,

  /// Other error during test
  otherError,

  /// Test is in progress
  testing,

  /// Not tested yet
  unknown,
}

/// Detailed result of a relay deletion test
class RelayDeletionTestResult {
  final RelayDeletionSupport status;
  final String? errorMessage;

  const RelayDeletionTestResult({required this.status, this.errorMessage});

  bool get isFailure =>
      status == RelayDeletionSupport.relayRejectsGiftWrap ||
      status == RelayDeletionSupport.relayRejectsDeletion ||
      status == RelayDeletionSupport.networkError ||
      status == RelayDeletionSupport.timeout ||
      status == RelayDeletionSupport.otherError;
}

/// Detailed result of a relay privacy test
class RelayPrivacyTestResult {
  final RelayPrivacySupport status;
  final String? errorMessage;

  const RelayPrivacyTestResult({required this.status, this.errorMessage});

  bool get isFailure =>
      status == RelayPrivacySupport.leaksToEveryone ||
      status == RelayPrivacySupport.relayRejectsGiftWrap ||
      status == RelayPrivacySupport.networkError ||
      status == RelayPrivacySupport.timeout ||
      status == RelayPrivacySupport.otherError;
}

/// State for relay DM tests
class RelayDmTestState {
  final Map<String, RelayDeletionTestResult> deletionResults;
  final Map<String, RelayPrivacyTestResult> privacyResults;
  final String? currentlyTesting;
  final String? currentTestType;

  const RelayDmTestState({
    this.deletionResults = const {},
    this.privacyResults = const {},
    this.currentlyTesting,
    this.currentTestType,
  });

  RelayDmTestState copyWith({
    Map<String, RelayDeletionTestResult>? deletionResults,
    Map<String, RelayPrivacyTestResult>? privacyResults,
    String? currentlyTesting,
    String? currentTestType,
    bool clearCurrentlyTesting = false,
  }) {
    return RelayDmTestState(
      deletionResults: deletionResults ?? this.deletionResults,
      privacyResults: privacyResults ?? this.privacyResults,
      currentlyTesting: clearCurrentlyTesting
          ? null
          : (currentlyTesting ?? this.currentlyTesting),
      currentTestType: clearCurrentlyTesting
          ? null
          : (currentTestType ?? this.currentTestType),
    );
  }
}

/// Notifier for testing relay DM support (deletion and privacy)
class RelayDmTestNotifier extends StateNotifier<RelayDmTestState> {
  final Ndk ndk;
  final _bip340 = Bip340();

  RelayDmTestNotifier(this.ndk) : super(const RelayDmTestState());

  // ============ RELAY TEST ============

  /// Run both deletion and privacy tests on a relay using a single gift wrap.
  ///
  /// Test logic:
  /// 1. Create gift wrap from A to B
  /// 2. Send to relay, verify accepted
  /// 3. Privacy test: Query as outsider - if found = leak
  /// 4. Deletion test: Send deletion, re-send gift wrap - if accepted = deletion works
  Future<void> testRelayComplete(String relayUrl) async {
    state = state.copyWith(
      currentlyTesting: relayUrl,
      currentTestType: 'privacy',
      privacyResults: {
        ...state.privacyResults,
        relayUrl: const RelayPrivacyTestResult(
          status: RelayPrivacySupport.testing,
        ),
      },
      deletionResults: {
        ...state.deletionResults,
        relayUrl: const RelayDeletionTestResult(
          status: RelayDeletionSupport.testing,
        ),
      },
    );

    try {
      final senderKeys = _bip340.generatePrivateKey();
      final recipientKeys = _bip340.generatePrivateKey();

      log('Combined Test: Testing relay $relayUrl');

      // Create single test gift wrap
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final signedEvent = _createSignedGiftWrap(
        senderKeys: senderKeys,
        recipientPubkey: recipientKeys.publicKey,
        content: 'test_combined_$now',
        createdAt: now,
      );

      log('Combined Test: Created test event ${signedEvent.id}');

      // Step 1: Send test event
      final sendResult = await _broadcastAndGetResponse(signedEvent, relayUrl);
      if (sendResult == null) {
        _updatePrivacyResult(
          relayUrl,
          const RelayPrivacyTestResult(
            status: RelayPrivacySupport.timeout,
            errorMessage: 'Timeout sending test event',
          ),
          clearTesting: false,
        );
        _updateDeletionResult(
          relayUrl,
          const RelayDeletionTestResult(
            status: RelayDeletionSupport.timeout,
            errorMessage: 'Timeout sending test event',
          ),
        );
        return;
      }

      if (!sendResult.broadcastSuccessful) {
        log('Combined Test: Relay rejected gift wrap: ${sendResult.msg}');
        final errorMsg = sendResult.msg.isNotEmpty
            ? sendResult.msg
            : 'Relay rejected kind 1059';
        _updatePrivacyResult(
          relayUrl,
          RelayPrivacyTestResult(
            status: RelayPrivacySupport.relayRejectsGiftWrap,
            errorMessage: errorMsg,
          ),
          clearTesting: false,
        );
        _updateDeletionResult(
          relayUrl,
          RelayDeletionTestResult(
            status: RelayDeletionSupport.relayRejectsGiftWrap,
            errorMessage: errorMsg,
          ),
        );
        return;
      }

      log('Combined Test: Event accepted by relay');
      await Future.delayed(const Duration(milliseconds: 300));

      // Step 2: Privacy test - query as outsider
      state = state.copyWith(currentTestType: 'privacy');
      final eventFound = await _queryEventAsOutsider(signedEvent.id, relayUrl);

      if (eventFound) {
        log('Combined Test: PRIVACY LEAK - event accessible to outsiders');
        _updatePrivacyResult(
          relayUrl,
          const RelayPrivacyTestResult(
            status: RelayPrivacySupport.leaksToEveryone,
            errorMessage: 'Gift wrap accessible without authentication',
          ),
          clearTesting: false,
        );
      } else {
        log('Combined Test: Privacy OK');
        _updatePrivacyResult(
          relayUrl,
          const RelayPrivacyTestResult(status: RelayPrivacySupport.private),
          clearTesting: false,
        );
      }

      // Step 3: Deletion test - send deletion request
      state = state.copyWith(currentTestType: 'deletion');
      final signedDeleteEvent = _createSignedDeletion(
        signerKeys: recipientKeys,
        eventIdToDelete: signedEvent.id,
      );

      final deleteResult = await _broadcastAndGetResponse(
        signedDeleteEvent,
        relayUrl,
      );
      if (deleteResult == null) {
        _updateDeletionResult(
          relayUrl,
          const RelayDeletionTestResult(
            status: RelayDeletionSupport.timeout,
            errorMessage: 'Timeout sending deletion request',
          ),
        );
        return;
      }

      if (!deleteResult.broadcastSuccessful) {
        log('Combined Test: Relay rejected deletion: ${deleteResult.msg}');
        _updateDeletionResult(
          relayUrl,
          RelayDeletionTestResult(
            status: RelayDeletionSupport.relayRejectsDeletion,
            errorMessage: deleteResult.msg.isNotEmpty
                ? deleteResult.msg
                : 'Relay rejected deletion',
          ),
        );
        return;
      }

      log('Combined Test: Deletion request accepted');
      await Future.delayed(const Duration(milliseconds: 500));

      // Step 4: Re-send same event to verify deletion
      final resendResult = await _broadcastAndGetResponse(
        signedEvent,
        relayUrl,
      );
      if (resendResult == null) {
        _updateDeletionResult(
          relayUrl,
          const RelayDeletionTestResult(
            status: RelayDeletionSupport.timeout,
            errorMessage: 'Timeout verifying deletion',
          ),
        );
        return;
      }

      final msg = resendResult.msg.toLowerCase();
      if (!resendResult.broadcastSuccessful &&
          (msg.contains('duplicate') || msg.contains('already have'))) {
        log('Combined Test: Event still exists - deletion NOT supported');
        _updateDeletionResult(
          relayUrl,
          RelayDeletionTestResult(
            status: RelayDeletionSupport.notSupported,
            errorMessage: 'Event still exists: ${resendResult.msg}',
          ),
        );
        return;
      }

      if (resendResult.broadcastSuccessful) {
        log('Combined Test: Event was deleted - deletion SUPPORTED');
        _updateDeletionResult(
          relayUrl,
          const RelayDeletionTestResult(status: RelayDeletionSupport.supported),
        );
        return;
      }

      log('Combined Test: Unclear deletion result: ${resendResult.msg}');
      _updateDeletionResult(
        relayUrl,
        RelayDeletionTestResult(
          status: RelayDeletionSupport.otherError,
          errorMessage: 'Unclear result: ${resendResult.msg}',
        ),
      );
    } catch (e) {
      log('Combined Test: Unexpected error: $e');
      _updatePrivacyResult(
        relayUrl,
        RelayPrivacyTestResult(
          status: RelayPrivacySupport.otherError,
          errorMessage: e.toString(),
        ),
        clearTesting: false,
      );
      _updateDeletionResult(
        relayUrl,
        RelayDeletionTestResult(
          status: RelayDeletionSupport.otherError,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  /// Test all provided relays for both deletion and privacy
  Future<void> testAllRelays(List<String> relayUrls) async {
    for (final url in relayUrls) {
      await testRelayComplete(url);
    }
  }

  // ============ HELPERS ============

  /// Query for an event as an outsider (no authentication)
  Future<bool> _queryEventAsOutsider(String eventId, String relayUrl) async {
    try {
      final filter = Filter(ids: [eventId], kinds: [1059], limit: 1);

      final response = ndk.requests.query(
        filter: filter,
        cacheRead: false,
        cacheWrite: false,
        timeout: const Duration(seconds: 5),
        explicitRelays: [relayUrl],
      );

      await for (final event in response.stream.timeout(
        const Duration(seconds: 8),
      )) {
        if (event.id == eventId) {
          return true; // Event found = privacy leak
        }
      }

      return false; // Event not found = privacy OK
    } catch (e) {
      log('Query error: $e');
      return false; // Assume privacy OK on error
    }
  }

  Nip01Event _createSignedGiftWrap({
    required KeyPair senderKeys,
    required String recipientPubkey,
    required String content,
    required int createdAt,
  }) {
    final event = Nip01Event(
      pubKey: senderKeys.publicKey,
      kind: 1059,
      tags: [
        ['p', recipientPubkey],
      ],
      content: content,
      createdAt: createdAt,
    );

    final signature = _bip340.sign(event.id, senderKeys.privateKey);
    return Nip01Event(
      id: event.id,
      pubKey: senderKeys.publicKey,
      kind: 1059,
      tags: event.tags,
      content: content,
      createdAt: createdAt,
      sig: signature,
    );
  }

  Nip01Event _createSignedDeletion({
    required KeyPair signerKeys,
    required String eventIdToDelete,
  }) {
    final event = Nip01Event(
      pubKey: signerKeys.publicKey,
      kind: 5,
      tags: [
        ['e', eventIdToDelete],
      ],
      content: '',
      createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );

    final signature = _bip340.sign(event.id, signerKeys.privateKey);
    return Nip01Event(
      id: event.id,
      pubKey: signerKeys.publicKey,
      kind: 5,
      tags: event.tags,
      content: '',
      createdAt: event.createdAt,
      sig: signature,
    );
  }

  Future<RelayBroadcastResponse?> _broadcastAndGetResponse(
    Nip01Event event,
    String relayUrl,
  ) async {
    try {
      final broadcastResponse = ndk.broadcast.broadcast(
        nostrEvent: event,
        specificRelays: [relayUrl],
      );

      final responses = await broadcastResponse.broadcastDoneFuture.timeout(
        const Duration(seconds: 10),
      );

      for (final response in responses) {
        if (response.relayUrl == relayUrl) {
          return response;
        }
      }

      return null;
    } catch (e) {
      log('Broadcast error: $e');
      return null;
    }
  }

  RelayDeletionTestResult _updateDeletionResult(
    String relayUrl,
    RelayDeletionTestResult result, {
    bool clearTesting = true,
  }) {
    state = state.copyWith(
      deletionResults: {...state.deletionResults, relayUrl: result},
      clearCurrentlyTesting: clearTesting,
    );
    return result;
  }

  RelayPrivacyTestResult _updatePrivacyResult(
    String relayUrl,
    RelayPrivacyTestResult result, {
    bool clearTesting = true,
  }) {
    state = state.copyWith(
      privacyResults: {...state.privacyResults, relayUrl: result},
      clearCurrentlyTesting: clearTesting,
    );
    return result;
  }

  void clearResults() {
    state = const RelayDmTestState();
  }
}

/// Provider for relay DM testing
final relayDmTestProvider =
    StateNotifierProvider<RelayDmTestNotifier, RelayDmTestState>((ref) {
      final ndk = ref.watch(ndkProvider);
      return RelayDmTestNotifier(ndk);
    });
