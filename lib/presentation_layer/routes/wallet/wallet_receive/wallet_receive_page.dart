import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'wallet_receive_amout/wallet_receive_amount.dart';
import 'wallet_receive_request/wallet_receive_request.dart';
import 'wallet_receive_type/wallet_receive_type.dart';

class WalletReceivePage extends ConsumerStatefulWidget {
  const WalletReceivePage({
    super.key,
  });

  @override
  ConsumerState<WalletReceivePage> createState() => _WalletReceivePageState();
}

class _WalletReceivePageState extends ConsumerState<WalletReceivePage>
    with TickerProviderStateMixin {
  final PageController _horizontalPageController = PageController(
    initialPage: 0,
    keepPage: true,
  );

  bool horizontalScrollLock = false;

  void _navigateToNextPage() {
    if (_horizontalPageController.page != null) {
      _horizontalPageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _navigateToPreviousPage() {
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
        WalletReceiveType(
          doneCallback: () {
            _navigateToNextPage();
          },
        ),
        WalletReceiveAmount(
          title: "Receive",
          backCallback: () {
            _navigateToPreviousPage();
          },
          doneCallback: () {
            _navigateToNextPage();
          },
        ),
        WalletReceiveRequest(
          backCallback: () {
            _navigateToPreviousPage();
          },
        ),
      ],
    );
  }
}
