import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../routing/routes.dart';
import '../../../providers/nip05_provider.dart';
import 'profile_page_2.dart';

/// needed to resolve nip05 identifiers to pubkeys before showing the profile page
class ProfileResolverPage extends StatelessWidget {
  final String identifier;

  const ProfileResolverPage({super.key, required this.identifier});

  Future<String?> _resolvePubkey(BuildContext context) async {
    final decodedPubkey = decodeProfileIdentifierToPubkey(identifier);
    if (decodedPubkey != null) {
      return decodedPubkey;
    }

    final normalizedIdentifier = Uri.decodeComponent(identifier);
    if (!normalizedIdentifier.contains('@')) {
      return null;
    }

    final nip05P = ProviderScope.containerOf(
      context,
      listen: false,
    ).read(nip05provider);
    final nip05Data = await nip05P.get(normalizedIdentifier);

    return nip05Data?.pubkey;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _resolvePubkey(context),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Text('Loading profile...'));
        }

        final pubkey = snapshot.data;
        if (pubkey == null || pubkey.isEmpty) {
          return const Center(child: Text('Profile not found'));
        }

        return ProfilePage2(pubkey: pubkey);
      },
    );
  }
}
