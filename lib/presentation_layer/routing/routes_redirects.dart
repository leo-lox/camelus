import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'route_paths.dart';
import '../providers/metadata_provider.dart';
import 'routes.dart';

Future<String?> _redirectProfileToCanonicalNip05(
  BuildContext context,
  GoRouterState state,
) async {
  final rawIdentifier = state.pathParameters['profileIdentifier'];
  if (rawIdentifier == null || rawIdentifier.isEmpty) {
    return null;
  }

  final canonicalIdentifier = await _resolveCanonicalNip05Identifier(
    context,
    rawIdentifier,
  );

  if (canonicalIdentifier == null) {
    return null;
  }

  final currentIdentifier = Uri.encodeComponent(
    Uri.decodeComponent(rawIdentifier),
  );
  if (canonicalIdentifier == currentIdentifier) {
    return null;
  }

  final eventId = state.pathParameters['eventId'];
  if (eventId != null && eventId.isNotEmpty) {
    final scrollIntoView = state.uri.queryParameters['scrollIntoView'];
    return RoutePaths.statusByIdentifier(
      profileIdentifier: canonicalIdentifier,
      eventId: eventId,
      scrollIntoView: scrollIntoView,
    );
  }

  final path = state.uri.path;
  if (path.endsWith('/edit')) {
    return '/profile/$canonicalIdentifier/edit';
  }

  return '/profile/$canonicalIdentifier';
}

Future<String?> _resolveCanonicalNip05Identifier(
  BuildContext context,
  String rawIdentifier,
) async {
  final identifier = Uri.decodeComponent(rawIdentifier).trim();
  if (identifier.contains('@')) {
    return null;
  }

  final pubkey = decodeProfileIdentifierToPubkey(identifier);
  if (pubkey == null || pubkey.isEmpty) {
    return null;
  }

  try {
    final metadataUsecase = ProviderScope.containerOf(
      context,
      listen: false,
    ).read(metadataProvider);
    final metadata = await metadataUsecase
        .getMetadataByPubkey(pubkey)
        .last
        .timeout(const Duration(milliseconds: 1200));

    final nip05 = metadata.nip05?.trim();
    if (nip05 == null || nip05.isEmpty || !nip05.contains('@')) {
      return null;
    }

    return Uri.encodeComponent(nip05);
  } catch (_) {
    return null;
  }
}
