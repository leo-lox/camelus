import 'dart:async';

import 'package:camelus/domain_layer/entities/nostr_note.dart';
import 'package:camelus/presentation_layer/routing/route_paths.dart';
import 'package:camelus/presentation_layer/providers/metadata_provider.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

Future<void> openBottomSheetShare(
  BuildContext context,
  WidgetRef ref,
  NostrNote note,
) async {
  final metadataP = ref.read(metadataProvider);

  String profilePath;
  try {
    // Add timeout of 1 second to the metadata fetch operation
    final userMetadata = await metadataP
        .getMetadataByPubkey(note.pubkey)
        .last
        .timeout(const Duration(milliseconds: 500));
    profilePath = RoutePaths.status(
      pubkey: note.pubkey,
      eventId: note.id,
      nip05: userMetadata.nip05,
    );
  } on TimeoutException {
    // If timeout occurs, fall back to using just the pubkey
    profilePath = RoutePaths.status(pubkey: note.pubkey, eventId: note.id);
  }

  SharePlus.instance.share(
    ShareParams(
      uri: Uri(scheme: 'https', host: 'camelus.app', path: profilePath),
    ),
  );
}
