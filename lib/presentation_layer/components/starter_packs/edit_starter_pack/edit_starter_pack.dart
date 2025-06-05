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
          onNext: () {},
        ),
      ],
    ));
  }
}
