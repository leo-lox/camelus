import 'dart:convert';

import 'package:ndk/ndk.dart';
import 'package:riverpod/riverpod.dart';

import '../../config/dicebear.dart';
import '../../presentation_layer/providers/metadata_provider.dart';
import '../../presentation_layer/providers/ndk_provider.dart';
import '../../presentation_layer/providers/notifications_provider.dart';
import '../../presentation_layer/providers/signer_provider.dart';

/// processes a FCM message
Future<void> processFcmData({
  required Map<String, dynamic> data,
  required ProviderContainer provider,
  bool isBackground = false,
}) async {
  final Map<String, dynamic> encryptedEventJson =
      jsonDecode(data['encryptedEvent']);

  final encryptedWrapEvent = Nip01Event.fromJson(encryptedEventJson);

  final ndk = isBackground
      ? provider.read(ndkProviderLight)
      : provider.read(ndkProvider);

  final unwrappedEvent =
      await ndk.giftWrap.unwrapEvent(wrappedEvent: encryptedWrapEvent);

  final notiProvider = await provider.read(notificationsProvider.future);

  if (unwrappedEvent.kind == 1) {
    final metadata = await provider
        .read(metadataProvider)
        .getMetadataByPubkey(unwrappedEvent.pubKey)
        .first;

    final signer = provider.read(signerProvider);
    final myPubkey = signer!.getPublicKey();

    final lastPtag = unwrappedEvent.pTags.last;
    final likleyDirectReply = myPubkey == lastPtag;

    final threadId =
        unwrappedEvent.getTags('e').where((t) => t[3] == 'root').firstOrNull;

    final payload = {
      "note": jsonEncode(unwrappedEvent.toJson()),
      "likleyDirectReply": likleyDirectReply,
    };

    /// display notification
    await notiProvider.displayLocalAvatarNotification(
      title: metadata.name ??
          metadata.nip05 ??
          "${metadata.pubkey.substring(0, 15)}...",
      body: unwrappedEvent.content.length < 280
          ? unwrappedEvent.content
          : "${unwrappedEvent.content.substring(0, 280)}...",
      avatarUrl: metadata.picture ?? "${Dicebear.baseUrlPng}${metadata.pubkey}",
      pubkey: unwrappedEvent.pubKey,
      payload: jsonEncode(payload),
      type: likleyDirectReply ? "new reply" : "new mention (thread)",
      threadIdentifier: threadId,
    );
  }
}
