import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../config/palette.dart';
import '../../../../domain_layer/entities/nostr_list.dart';
import '../../../atoms/long_button.dart';
import '../../../providers/ndk_provider.dart';
import '../starter_pack_card.dart';
import 'edit_starter_pack_provider.dart';

class EditStarterPackSummary extends ConsumerStatefulWidget {
  final String starterPackId;
  final Function onNext;
  const EditStarterPackSummary({
    super.key,
    required this.starterPackId,
    required this.onNext,
  });
  @override
  ConsumerState<EditStarterPackSummary> createState() =>
      _EditStarterPackSummaryState();
}

class _EditStarterPackSummaryState
    extends ConsumerState<EditStarterPackSummary> {
  @override
  Widget build(BuildContext context) {
    final starterPackData =
        ref.watch(editStarterPackProvider(widget.starterPackId));

    final ndk = ref.watch(ndkProvider);

    int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    final myNostrPack = NostrStarterPack(
      name: starterPackData.name,
      title: starterPackData.title,
      description: starterPackData.description,
      pubKey: ndk.accounts.getPublicKey()!,
      createdAt: now,
      image: starterPackData.imageUrl,
      elements: starterPackData.selectedUsers.map((e) {
        return NostrListElement(tag: "p", value: e.pubkey, private: false);
      }).toList(),
    );

    return Scaffold(
      backgroundColor: Palette.background,
      body: Column(
        children: [
          Column(
            children: [],
          ),
          Expanded(
              child: ListView(
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height / 7,
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  children: [
                    Text(
                      "your starter pack",
                      style: TextStyle(
                        fontSize: 30,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              Padding(
                padding: EdgeInsetsGeometry.symmetric(horizontal: 8),
                child: StarterPackCard(
                  pack: myNostrPack,
                ),
              ),
            ],
          )),
          Container(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: SafeArea(
              top: false,
              child: SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: longButton(
                      name: "publish starter pack",
                      inverted: true,
                      disabled: starterPackData.selectedUsers.isEmpty,
                      onPressed: () {
                        widget.onNext();
                      })),
            ),
          ),
        ],
      ),
    );
  }
}
