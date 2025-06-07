import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../config/palette.dart';
import '../../../../domain_layer/entities/nostr_list.dart';
import '../../../atoms/long_button.dart';
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
              StarterPackCard(
                pack: NostrStarterPack(
                    name: "test",
                    title: "testTitle",
                    pubKey:
                        "da1678cd43b0afed5c5566b878a0a5faae97b16635b47d58b9179a75de500801",
                    createdAt: 0,
                    elements: [
                      NostrListElement(
                        tag: "d",
                        value: "a",
                        private: false,
                      ),
                      NostrListElement(
                        tag: "p",
                        value:
                            "da1678cd43b0afed5c5566b878a0a5faae97b16635b47d58b9179a75de500801",
                        private: false,
                      ),
                      NostrListElement(
                        tag: "p",
                        value:
                            "c7779fdc1e5d2bbf5edd5f68785bfc4299b3c77d8046957cc79bc4d25ad9d330",
                        private: false,
                      ),
                      NostrListElement(
                        tag: "p",
                        value:
                            "0f22c06eac1002684efcc68f568540e8342d1609d508bcd4312c038e6194f8b6",
                        private: false,
                      ),
                      NostrListElement(
                        tag: "p",
                        value:
                            "50d94fc2d8580c682b071a542f8b1e31a200b0508bab95a33bef0855df281d63",
                        private: false,
                      ),
                    ]),
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
