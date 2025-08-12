import 'package:flutter/material.dart';
import 'package:ndk/entities.dart' as ndk_entities;
import 'wallet_account_card_placeholder.dart';
import 'wallet_accounts_card.dart';

class WalletsCarousel extends StatefulWidget {
  final List<ndk_entities.Wallet> wallets;
  final List<ndk_entities.WalletBalance> balances;
  final AnimationController? nfcAnimController;

  const WalletsCarousel({
    super.key,
    required this.wallets,
    required this.balances,
    this.nfcAnimController,
  });

  @override
  State<WalletsCarousel> createState() => _WalletsCarouselState();
}

class _WalletsCarouselState extends State<WalletsCarousel> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      viewportFraction: _viewportForCount(widget.wallets.length),
    );
  }

  @override
  void didUpdateWidget(covariant WalletsCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((oldWidget.wallets.length > 1) != (widget.wallets.length > 1)) {
      _pageController.dispose();
      _pageController = PageController(
        viewportFraction: _viewportForCount(widget.wallets.length),
      );
      setState(() {});
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  double _viewportForCount(int count) {
    // show a peek of the next card
    return count <= 1 ? 1.0 : 0.9;
  }

  @override
  Widget build(BuildContext context) {
    final wallets = widget.wallets;

    if (wallets.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SizedBox(
          height: 210,
          child: _CardMaxWidth(
            child: WalletAccountCardPlaceholder(),
          ),
        ),
      );
    }

    final hasMultiple = wallets.length > 1;

    return SizedBox(
      height: 210,
      child: PageView.builder(
        controller: _pageController,
        physics: hasMultiple
            ? const BouncingScrollPhysics()
            : const NeverScrollableScrollPhysics(),
        itemCount: wallets.length,
        padEnds: false,
        itemBuilder: (context, index) {
          final w = wallets[index];

          final String? mintUrl;
          if (w is ndk_entities.CashuWallet) {
            mintUrl = w.mintUrl;
          } else {
            mintUrl = null;
          }

          final title =
              w.name.isNotEmpty ? w.name : mintUrl ?? 'Wallet ${index + 1}';
          final alias = w.type.toString();

          final myBalances = widget.balances
              .where(
                (b) => b.walletId == w.id,
              )
              .toList();

          return Padding(
            // keep first left so next card peeks
            padding: EdgeInsets.only(
              left: index == 0 ? 16 : 8,
              right: index == wallets.length - 1 ? 16 : 8,
            ),
            child: _CardMaxWidth(
              child: WalletAccountsCard(
                  walletId: w.id,
                  title: title,
                  alias: alias,
                  balances: myBalances,
                  nfcAnimController: widget.nfcAnimController!),
            ),
          );
        },
      ),
    );
  }
}

/// prevents shrink layouts
class _CardMaxWidth extends StatelessWidget {
  final Widget child;
  const _CardMaxWidth({required this.child});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints.expand(),
      child: child,
    );
  }
}
