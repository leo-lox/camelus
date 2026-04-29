import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain_layer/entities/list_identifier.dart';
import '../../../../domain_layer/entities/nostr_list.dart';
import '../../../components/lists/edit_list/edit_list.dart';
import '../../../providers/ndk_provider.dart';

class StarterPackEditPage extends ConsumerWidget {
  final String pubkey;
  final String name;
  final bool isNew;

  const StarterPackEditPage({
    super.key,
    required this.pubkey,
    required this.name,
    required this.isNew,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ndk = ref.watch(ndkProvider);
    final myPubkey = ndk.accounts.getPublicKey();

    if (myPubkey != pubkey) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: const Center(
          child: Text('Not authorized', style: TextStyle(fontSize: 18)),
        ),
      );
    }

    return EditList(
      listIdentifier: ListIdentifier(name: name, kind: NostrList.starterPack),
      isNewList: isNew,
    );
  }
}
