import 'package:camelus/presentation_layer/atoms/wallet/wallet_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ndk/entities.dart' as ndk_entities;
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../../config/palette.dart';
import '../../../../atoms/long_button.dart';
import '../../../../components/wallet/wallets_select_bottom_sheet.dart';
import '../wallet_pay_state_provider.dart';
import 'wallet_pay_select_amount_state_provider.dart';

class WalletPaySelectAmount extends ConsumerStatefulWidget {
  final Function doneCallback;
  final Function backCallback;

  const WalletPaySelectAmount({
    super.key,
    required this.doneCallback,
    required this.backCallback,
    required this.currencies,
    this.title,
  });

  final List<String> currencies;

  final String? title;

  @override
  ConsumerState<WalletPaySelectAmount> createState() =>
      _WalletPaySelectAmountState();
}

class _WalletPaySelectAmountState extends ConsumerState<WalletPaySelectAmount> {
  late final TextEditingController _amountController;
  late final TextEditingController _memoController;
  final FocusNode _amountFocus = FocusNode();
  final FocusNode _memoFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    final state = ref.read(walletSelectAmountStateProvider);
    _amountController = TextEditingController(text: state.amount.toString());
    _memoController = TextEditingController(text: state.memo);

    _amountController.addListener(() {
      //todo: input validation - double.parse sat vs fiat
      ref
          .read(walletSelectAmountStateProvider.notifier)
          .setAmount(int.parse(_amountController.text));
    });
    _memoController.addListener(() {
      ref
          .read(walletSelectAmountStateProvider.notifier)
          .setMemo(_memoController.text);
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _memoController.dispose();
    _amountFocus.dispose();
    _memoFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectAmountState = ref.watch(walletSelectAmountStateProvider);
    final notifier = ref.read(walletSelectAmountStateProvider.notifier);

    final payState = ref.watch(walletPayStateProvider);
    final payNotifier = ref.read(walletPayStateProvider.notifier);

    return Scaffold(
      appBar: widget.title != null
          ? AppBar(
              backgroundColor: Palette.background,
              title: Text(widget.title!),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  widget.backCallback();
                },
              ),
            )
          : null,
      backgroundColor: Palette.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
          child: Column(
            children: [
              Container(
                child: WalletCard(
                  wallet: payState.availableWallets.firstWhere(
                    (w) => w.id == payState.payFromWalletId,
                    orElse: () => ndk_entities.CashuWallet(
                      id: '',
                      name: 'Select Wallet',
                      type: ndk_entities.WalletType.CASHU,
                      supportedUnits: {},
                      mintUrl: '',
                    ),
                  ),
                  balances: payState.availableBalances
                      .where((b) => b.walletId == payState.payFromWalletId)
                      .toList(),
                  onTap: (_) {},
                  tralling: IconButton(
                    icon: Icon(
                      PhosphorIcons.notePencil(),
                      size: 25,
                    ),
                    color: Palette.primary,
                    onPressed: () async {
                      final selectedId = await showWalletsSelectBottomSheet(
                        context: context,
                        selectedId: payState.payFromWalletId,
                        wallets: payState.availableWallets,
                        balances: payState.availableBalances,
                      );
                      if (selectedId != null) {
                        payNotifier.updatePayFromWalletId(selectedId);
                      }
                    },
                  ),
                ),
              ),

              Spacer(flex: 1),
              TextField(
                controller: _amountController,
                focusNode: _amountFocus,
                autofocus: true,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w600,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: '0.00',
                ),
              ),

              const SizedBox(height: 12),
              Spacer(flex: 1),

              /// currency selector
              Align(
                alignment: Alignment.center,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: DropdownButtonFormField<String>(
                    value: selectAmountState.currency,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Currency',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    items: widget.currencies
                        .map(
                          (c) => DropdownMenuItem<String>(
                            value: c,
                            child: Text(c),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => notifier.setCurrency(value),
                  ),
                ),
              ),
              Spacer(flex: 5),

              /// memo input
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: TextField(
                  controller: _memoController,
                  focusNode: _memoFocus,
                  keyboardType: TextInputType.text,
                  maxLines: 3,
                  minLines: 1,
                  decoration: const InputDecoration(
                    labelText: 'Memo',
                    hintText: 'Add a memo (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: longButton(name: "next", onPressed: () {}, inverted: true),
        ),
      ),
    );
  }
}
