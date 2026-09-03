import 'package:material_ui/material_ui.dart';

import '../../../../domain_layer/entities/list_identifier.dart';
import 'edit_list_content.dart';
import 'edit_list_meta.dart';
import 'edit_list_summary.dart';

class EditList extends StatefulWidget {
  final ListIdentifier listIdentifier;
  final bool isNewList;

  const EditList({
    super.key,
    required this.listIdentifier,
    required this.isNewList,
  });

  @override
  State<EditList> createState() => _EditListState();
}

class _EditListState extends State<EditList> {
  final _pageController = PageController(initialPage: 0, keepPage: true);
  bool _scrollLock = false;

  void _toPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: PageView(
        controller: _pageController,
        physics: _scrollLock
            ? const NeverScrollableScrollPhysics()
            : const AlwaysScrollableScrollPhysics(),
        children: [
          EditListMeta(
            listIdentifier: widget.listIdentifier,
            isNewList: widget.isNewList,
            onNext: () => _toPage(1),
          ),
          EditListContent(
            listIdentifier: widget.listIdentifier,
            onNext: () => _toPage(2),
          ),
          EditListSummary(
            listIdentifier: widget.listIdentifier,
            onPublishing: () => setState(() => _scrollLock = true),
          ),
        ],
      ),
    );
  }
}
