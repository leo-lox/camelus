import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'wallet_pay_select_amount/wallet_pay_select_amount.dart';
import 'wallet_pay_select_reciever/wallet_pay_reciever.dart';
import 'wallet_pay_summary/wallet_pay_summary.dart';

class WalletPayPage extends ConsumerStatefulWidget {
  final int initialPage;

  const WalletPayPage({super.key, this.initialPage = 0});

  @override
  ConsumerState<WalletPayPage> createState() => _WalletPayPageState();
}

class _WalletPayPageState extends ConsumerState<WalletPayPage>
    with TickerProviderStateMixin {
  final PageController _horizontalPageController = PageController(
    keepPage: true,
  );

  @override
  void initState() {
    super.initState();
    // Jump to the requested page after the first frame so the controller
    // is attached to the PageView before we call jumpToPage.
    if (widget.initialPage != 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _horizontalPageController.jumpToPage(widget.initialPage);
        }
      });
    }
  }

  bool horizontalScrollLock = false;

  _navigateToNextPage() {
    if (_horizontalPageController.page != null) {
      _horizontalPageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  _navigateToPreviousPage() {
    if (_horizontalPageController.page != null) {
      _horizontalPageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageView(
      controller: _horizontalPageController,
      physics: horizontalScrollLock
          ? const NeverScrollableScrollPhysics()
          : const AlwaysScrollableScrollPhysics(),
      children: [
        WalletSelectReciever(
          doneCallback: () {
            _navigateToNextPage();
          },
        ),
        WalletPaySelectAmount(
          backCallback: () {
            _navigateToPreviousPage();
          },
          doneCallback: () {
            _navigateToNextPage();
          },
          title: 'Enter amount',
        ),
        WalletPaySummary(
          backCallback: () {
            _navigateToPreviousPage();
          },
        ),
      ],
    );
  }
}
