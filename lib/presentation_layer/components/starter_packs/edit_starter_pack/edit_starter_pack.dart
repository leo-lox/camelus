import 'package:camelus/presentation_layer/components/starter_packs/edit_starter_pack/edit_starter_pack_summary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../helpers/helpers.dart';
import 'edit_starter_pack_content.dart';
import 'edit_starter_pack_meta.dart';

class EditStarterPack extends ConsumerStatefulWidget {
  final String? starterPackId;

  const EditStarterPack({
    super.key,
    this.starterPackId,
  });

  @override
  ConsumerState<EditStarterPack> createState() => _EditStarterPackState();
}

class _EditStarterPackState extends ConsumerState<EditStarterPack>
    with TickerProviderStateMixin {
  late final String myStarterPackId;
  @override
  void initState() {
    super.initState();

    // new starter pack id gets created
    myStarterPackId =
        widget.starterPackId ?? "i-${Helpers().getRandomString(10)}";
  }

  @override
  void dispose() {
    super.dispose();
  }

  final PageController _horizontalPageController = PageController(
    initialPage: 0,
    keepPage: true,
  );

  bool scrollLock = false;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: PageView(
      controller: _horizontalPageController,
      physics: scrollLock
          ? const NeverScrollableScrollPhysics()
          : const AlwaysScrollableScrollPhysics(),
      children: [
        EditStarterPackMeta(
            starterPackId: myStarterPackId,
            onNext: () {
              _horizontalPageController.animateToPage(
                1,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
              );
            }),
        EditStarterPackContent(
          starterPackId: myStarterPackId,
          onNext: () {
            _horizontalPageController.animateToPage(
              2,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
            );
          },
        ),
        EditStarterPackSummary(
            starterPackId: myStarterPackId,
            onNext: () {
              setState(() {
                scrollLock = true;
              });
            })
      ],
    ));
  }
}
