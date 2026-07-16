import 'package:camelus/presentation_layer/atoms/wallet/wallet_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ndk/entities.dart' as ndk_entities;
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../../atoms/currency_picker_bar.dart';
import '../../../../atoms/long_button.dart';
import '../../../../components/wallet/wallets_select_bottom_sheet.dart';
import '../wallet_pay_state_provider.dart';

class WalletPaySelectAmount extends ConsumerStatefulWidget {
  final Function doneCallback;
  final Function backCallback;

  const WalletPaySelectAmount({
    super.key,
    required this.doneCallback,
    required this.backCallback,
    this.title,
  });

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
    final state = ref.read(walletPayStateProvider);
    _amountController = TextEditingController(text: state.amount?.toString());
    _memoController = TextEditingController(text: state.memo);

    _amountController.addListener(() {
      final stateR = ref.read(walletPayStateProvider);
      if (_amountController.text.isEmpty) {
        return;
      }

      final int? parsedAmount;
      if (stateR.unit == 'sat') {
        parsedAmount = int.tryParse(_amountController.text);
      } else {
        // Handle decimal input for fiat currencies
        final sanitizedInput = _amountController.text.replaceAll(',', '.');
        parsedAmount = ((double.tryParse(sanitizedInput) ?? 0) * 100).toInt();
      }

      ref.read(walletPayStateProvider.notifier).updateAmount(parsedAmount ?? 0);
    });
    _memoController.addListener(() {
      ref
          .read(walletPayStateProvider.notifier)
          .updateMemo(_memoController.text);
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

  _onSwitchCurrency({
    required String previousUnit,
    required String currentUnit,
  }) {
    final state = ref.read(walletPayStateProvider);
    final stateNotifier = ref.read(walletPayStateProvider.notifier);
    if (previousUnit == "sat" && currentUnit != "sat") {
      /// sat to fiat
      final amount = state.amount;
      if (amount != null) {
        final convertedAmount = (amount).toStringAsFixed(2);
        _amountController.text = convertedAmount;
        stateNotifier.updateAmount((amount * 100).toInt());
      }
    } else if (previousUnit != "sat" && currentUnit == "sat") {
      /// fiat to sat
      final amount = state.amount;
      if (amount != null) {
        final convertedAmount = (amount / 100).round();
        _amountController.text = convertedAmount.toString();
        stateNotifier.updateAmount(convertedAmount);
      }
    } else {
      /// fiat to fiat
    }
  }

  showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Theme.of(context).colorScheme.onSurface,
        content: Text(
          message,
          style: TextStyle(color: Theme.of(context).colorScheme.surface),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(walletPayStateProvider);
    final notifier = ref.read(walletPayStateProvider.notifier);

    final payState = ref.watch(walletPayStateProvider);
    final payNotifier = ref.read(walletPayStateProvider.notifier);

    return Scaffold(
      appBar: widget.title != null
          ? AppBar(
              backgroundColor: Theme.of(context).colorScheme.surface,
              title: Text(widget.title!),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  widget.backCallback();
                },
              ),
            )
          : null,
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 24, 10, 16),
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
                      mintInfo: ndk_entities.CashuMintInfo(nuts: {}),
                    ),
                  ),
                  balances: payState.availableBalances
                      .where((b) => b.walletId == payState.payFromWalletId)
                      .toList(),
                  onTap: (_) {},
                  tralling: IconButton(
                    icon: Icon(PhosphorIcons.notePencil, size: 25),
                    color: Theme.of(context).colorScheme.primary,
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
                keyboardType: TextInputType.numberWithOptions(
                  decimal: state.unit != 'sat',
                ),
                inputFormatters: state.unit == 'sat'
                    ? [FilteringTextInputFormatter.digitsOnly]
                    : [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9\.,]')),
                        DecimalTextInputFormatter(decimalRange: 2),
                      ],
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: state.unit != 'sat' ? '0.00' : '0',
                ),
              ),

              const SizedBox(height: 12),
              Spacer(flex: 1),

              /// currency selector
              Align(
                alignment: Alignment.center,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: CurrencyPickerBar(
                    currencies: state.supportedUnitsByWallet != null
                        ? state.supportedUnitsByWallet!.toList()
                        : [],
                    initialIndex: state.unit != null
                        ? state.supportedUnitsByWallet!.toList().indexOf(
                            state.unit!,
                          )
                        : 0,
                    onChanged: (r) => {
                      payNotifier.updateUnit(r.currentUnit),
                      _onSwitchCurrency(
                        previousUnit: r.previousUnit,
                        currentUnit: r.currentUnit,
                      ),
                    },
                    showHaptics: true,
                    trackColor: Theme.of(context).colorScheme.surfaceContainer,
                    activeColor: Theme.of(context).colorScheme.primary,
                    inactiveColor: Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant,
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
              Spacer(flex: 1),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: longButton(
            name: "next",
            onPressed: () {
              if (state.payFromWalletId == null ||
                  state.payFromWalletId!.isEmpty) {
                showSnackBar(context, 'Please select a wallet to pay from.');
                return;
              }
              if (state.amount == null || state.amount! <= 0) {
                _amountFocus.requestFocus();
                showSnackBar(context, 'Please enter a valid amount.');
                return;
              }
              widget.doneCallback();
            },
            inverted: true,
          ),
        ),
      ),
    );
  }
}

class DecimalTextInputFormatter extends TextInputFormatter {
  DecimalTextInputFormatter({required this.decimalRange})
    : assert(decimalRange > 0);

  final int decimalRange;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String newText = newValue.text;

    newText = newText.replaceAll(',', '.');

    if (newText.isEmpty) {
      return newValue.copyWith(text: '');
    }

    if (newText == '.') {
      return newValue.copyWith(text: '0.');
    }

    if (!RegExp(r'^\d*\.?\d*').hasMatch(newText)) {
      return oldValue;
    }

    if (newText.contains('.')) {
      List<String> parts = newText.split('.');
      if (parts.length > 2) {
        return oldValue;
      }
      if (parts[1].length > decimalRange) {
        // too many decimal places
        return oldValue;
      }
    }

    return newValue.copyWith(text: newText);
  }
}
