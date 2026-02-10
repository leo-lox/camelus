import 'dart:async';
import 'dart:convert';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:ndk/ndk.dart';
import 'package:uuid/uuid.dart';

/// Service for WebRTC signaling via Nostr
class VoiceSignalingService {
  final Ndk ndk;
  final String serverPubkey;
  final String sessionId;

  VoiceSignalingService({required this.ndk, required this.serverPubkey})
    : sessionId = const Uuid().v4();

  /// Send WebRTC offer to server (kind 30080)
  Future<void> sendOffer(
    RTCSessionDescription offer, {
    String? username,
    String channelId = 'lobby',
  }) async {
    // Create offer payload
    final offerJson = jsonEncode({'type': offer.type, 'sdp': offer.sdp});

    final encrypted = await ndk.accounts
        .getLoggedAccount()!
        .signer
        .encryptNip44(plaintext: offerJson, recipientPubKey: serverPubkey);

    // Create event
    final event = Nip01Event(
      kind: 30080, // WebRTC offer
      tags: [
        ['p', serverPubkey],
        ['session', sessionId],
        if (username != null) ['username', username],
        ['channel', channelId],
      ],
      content: encrypted!,
      createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      pubKey: ndk.accounts.getPublicKey()!,
    );

    // Sign and broadcast
    final signed = await ndk.accounts.sign(event);
    await ndk.broadcast.broadcast(nostrEvent: signed);
  }

  /// Listen for WebRTC answer from server (kind 30081)
  Stream<RTCSessionDescription> listenForAnswer() async* {
    final filter = Filter(
      kinds: const [30081], // WebRTC answer
      pTags: [ndk.accounts.getPublicKey()!],
      tags: {
        'session': [sessionId],
      },
    );

    final subscription = ndk.requests.subscription(filter: filter);

    await for (final event in subscription.stream) {
      try {
        final decrypted = await ndk.accounts
            .getLoggedAccount()!
            .signer
            .decryptNip44(
              ciphertext: event.content,
              senderPubKey: event.pubKey,
            );

        final answerData = jsonDecode(decrypted!) as Map<String, dynamic>;

        // Create session description
        final answer = RTCSessionDescription(
          answerData['sdp'] as String,
          answerData['type'] as String,
        );

        yield answer;
        break; // Only expect one answer
      } catch (e) {
        // Skip invalid answers
        continue;
      }
    }
  }

  /// Send ICE candidate to server (kind 30082)
  Future<void> sendIceCandidate(RTCIceCandidate candidate) async {
    // Create candidate payload
    final candidateJson = jsonEncode({
      'candidate': candidate.candidate,
      'sdpMid': candidate.sdpMid,
      'sdpMLineIndex': candidate.sdpMLineIndex,
    });

    final encrypted = await ndk.accounts
        .getLoggedAccount()!
        .signer
        .encryptNip44(plaintext: candidateJson, recipientPubKey: serverPubkey);

    // Create event
    final event = Nip01Event(
      kind: 30082, // ICE candidate
      tags: [
        ['p', serverPubkey],
        ['session', sessionId],
      ],
      content: encrypted!,
      createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      pubKey: ndk.accounts.getPublicKey()!,
    );

    // Sign and broadcast
    final signed = await ndk.accounts.sign(event);
    await ndk.broadcast.broadcast(nostrEvent: signed);
  }

  /// Listen for ICE candidates from server (kind 30082)
  Stream<RTCIceCandidate> listenForIceCandidates() async* {
    final filter = Filter(
      kinds: const [30082], // ICE candidate
      pTags: [ndk.accounts.getPublicKey()!],
      tags: {
        'session': [sessionId],
      },
    );

    final subscription = ndk.requests.subscription(filter: filter);

    await for (final event in subscription.stream) {
      try {
        final decrypted = await ndk.accounts
            .getLoggedAccount()!
            .signer
            .decryptNip44(
              ciphertext: event.content,
              senderPubKey: event.pubKey,
            );
        final candidateData = jsonDecode(decrypted!) as Map<String, dynamic>;

        // Create ICE candidate
        final candidate = RTCIceCandidate(
          candidateData['candidate'] as String?,
          candidateData['sdpMid'] as String?,
          candidateData['sdpMLineIndex'] as int?,
        );

        yield candidate;
      } catch (e) {
        // Skip invalid candidates
        continue;
      }
    }
  }

  /// Subscribe to channel state updates (kind 30083)
  Stream<Map<String, dynamic>> subscribeToChannelState(String serverId) async* {
    final filter = Filter(
      kinds: const [30083], // Channel state update
      tags: {
        'server': [serverId],
      },
    );

    final subscription = ndk.requests.subscription(filter: filter);

    await for (final event in subscription.stream) {
      try {
        final stateData = jsonDecode(event.content) as Map<String, dynamic>;
        yield stateData;
      } catch (e) {
        // Skip invalid state updates
        continue;
      }
    }
  }
}
