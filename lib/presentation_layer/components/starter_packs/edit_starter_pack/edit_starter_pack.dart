import 'package:camelus/presentation_layer/components/starter_packs/edit_starter_pack/edit_starter_pack_summary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'edit_starter_pack_content.dart';
import 'edit_starter_pack_meta.dart';

class EditStarterPack extends ConsumerStatefulWidget {
  const EditStarterPack({
    super.key,
  });

  @override
  ConsumerState<EditStarterPack> createState() => _EditStarterPackState();
}

class _EditStarterPackState extends ConsumerState<EditStarterPack>
    with TickerProviderStateMixin {
  final PageController _horizontalPageController = PageController(
    initialPage: 0,
    keepPage: true,
  );

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: PageView(
      controller: _horizontalPageController,
      children: [
        EditStarterPackMeta(
            starterPackId: "testId",
            onNext: () {
              _horizontalPageController.animateToPage(
                1,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
              );
            }),
        EditStarterPackContent(
          starterPackId: "testId",
          onNext: () {
            _horizontalPageController.animateToPage(
              2,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
            );
          },
        ),
        EditStarterPackSummary(starterPackId: "testId", onNext: () {})
      ],
    ));
  }
}
