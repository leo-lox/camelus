import 'package:camelus/presentation_layer/components/starter_packs/edit_starter_pack/edit_starter_pack_summary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain_layer/entities/starter_pack_identifier.dart';
import '../../../../helpers/helpers.dart';
import 'edit_starter_pack_content.dart';
import 'edit_starter_pack_meta.dart';

class EditStarterPack extends ConsumerStatefulWidget {
  final StarterPackIdentifier starterPackIdentifier;

  const EditStarterPack({
    super.key,
    required this.starterPackIdentifier,
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
            starterPackIdentifier: widget.starterPackIdentifier,
            onNext: () {
              _horizontalPageController.animateToPage(
                1,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
              );
            }),
        EditStarterPackContent(
          starterPackIdentifier: widget.starterPackIdentifier,
          onNext: () {
            _horizontalPageController.animateToPage(
              2,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
            );
          },
        ),
        EditStarterPackSummary(
            starterPackIdentifier: widget.starterPackIdentifier,
            onNext: () {
              setState(() {
                scrollLock = true;
              });
            })
      ],
    ));
  }
}
