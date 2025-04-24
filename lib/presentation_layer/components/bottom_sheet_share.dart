import 'dart:async';

import 'package:camelus/domain_layer/entities/nostr_note.dart';
import 'package:camelus/presentation_layer/providers/metadata_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

Future<void> openBottomSheetShare(
  BuildContext context,
  WidgetRef ref,
  NostrNote note,
) async {
  final metadataP = ref.read(metadataProvider);

  String userId;
  try {
    // Add timeout of 1 second to the metadata fetch operation
    final userMetadata = await metadataP
        .getMetadataByPubkey(note.pubkey)
        .last
        .timeout(const Duration(milliseconds: 500));
    userId = userMetadata.nip05 ?? note.pubkey;
  } on TimeoutException {
    // If timeout occurs, fall back to using just the pubkey
    userId = note.pubkey;
  }

  SharePlus.instance.share(
    ShareParams(
      uri: Uri(
        scheme: 'https',
        host: 'camelus.app',
        path: '/user/$userId/status/${note.id}',
      ),
    ),
  );
}
