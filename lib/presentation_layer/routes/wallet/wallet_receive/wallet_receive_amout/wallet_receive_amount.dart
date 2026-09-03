import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ndk/entities.dart' as ndk_entities;
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../../atoms/currency_picker_bar.dart';
import '../../../../atoms/long_button.dart';
import '../../../../atoms/wallet/wallet_card.dart';
import '../../../../components/wallet/wallets_select_bottom_sheet.dart';
import '../../wallet_providers/wallet_combined_state_provider.dart';

import '../wallet_receive_state_provider.dart';

class WalletReceiveAmount extends ConsumerStatefulWidget {
  final Function doneCallback;
  final Function backCallback;

  const WalletReceiveAmount({
    super.key,
    required this.doneCallback,
    required this.backCallback,
    this.title,
  });

  final String? title;

  @override
  ConsumerState<WalletReceiveAmount> createState() =>
      _WalletPaySelectAmountState();
}

class _WalletPaySelectAmountState extends ConsumerState<WalletReceiveAmount> {
  late final TextEditingController _amountController;
  late final TextEditingController _memoController;
  final FocusNode _amountFocus = FocusNode();
  final FocusNode _memoFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    final state = ref.read(walletRecieverProvider);
    _amountController = TextEditingController(text: state.amount?.toString());
    _memoController = TextEditingController(text: state.memo);

    _amountController.addListener(() {
      final stateR = ref.read(walletRecieverProvider);
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

      ref.read(walletRecieverProvider.notifier).updateAmount(parsedAmount ?? 0);
    });
    _memoController.addListener(() {
      ref
          .read(walletRecieverProvider.notifier)
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

  void _onSwitchCurrency({
    required String previousUnit,
    required String currentUnit,
  }) {
    final state = ref.read(walletRecieverProvider);
    final stateNotifier = ref.read(walletRecieverProvider.notifier);

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

  void showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Theme.of(context).colorScheme.error,
        content: Text(message, style: TextStyle(color: Colors.white)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(walletRecieverProvider);
    final notifier = ref.read(walletRecieverProvider.notifier);

    final combinedWallets = ref.watch(walletCombinedProvider);

    final List<ndk_entities.Wallet?> mySelectedWalletList = combinedWallets
        .wallets
        .where((w) => w.id == state.recieveToWalletId)
        .toList();

    final ndk_entities.CashuWallet? mySelectedWallet =
        mySelectedWalletList.isNotEmpty
        ? mySelectedWalletList.first as ndk_entities.CashuWallet
        : null;

    final List<String> supportedUnitsBySelectedWallet =
        mySelectedWallet?.supportedUnits.toList() ?? [];

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
                  wallet: combinedWallets.wallets.firstWhere(
                    (w) => w.id == state.recieveToWalletId,
                    orElse: () => ndk_entities.CashuWallet(
                      id: '',
                      name: 'Select Wallet',
                      type: ndk_entities.WalletType.CASHU,
                      supportedUnits: {},
                      mintUrl: '',
                      mintInfo: ndk_entities.CashuMintInfo(nuts: {}),
                    ),
                  ),
                  balances: combinedWallets.balances
                      .where((b) => b.walletId == state.recieveToWalletId)
                      .toList(),
                  onTap: (_) {},
                  tralling: IconButton(
                    icon: Icon(PhosphorIcons.notePencil, size: 25),
                    color: Theme.of(context).colorScheme.primary,
                    onPressed: () async {
                      final selectedId = await showWalletsSelectBottomSheet(
                        context: context,
                        selectedId: state.recieveToWalletId,
                        wallets: combinedWallets.wallets,
                        balances: combinedWallets.balances,
                      );
                      if (selectedId != null) {
                        notifier.updateRecieveToWalletId(selectedId);
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
                    currencies: supportedUnitsBySelectedWallet,
                    initialIndex: state.unit != null
                        ? supportedUnitsBySelectedWallet.indexOf(state.unit!)
                        : 0,
                    onChanged: (r) => {
                      notifier.updateUnit(r.currentUnit),
                      _onSwitchCurrency(
                        previousUnit: r.previousUnit,
                        currentUnit: r.currentUnit,
                      ),
                    },
                    showHaptics: true,
                    trackColor: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.1),
                    activeColor: Theme.of(context).colorScheme.primary,
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
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: SizedBox(
            width: double.infinity,
            height: 40,
            child: longButton(
              name: "create request",
              onPressed: () {
                if (state.recieveToWalletId == null ||
                    state.recieveToWalletId!.isEmpty) {
                  showSnackBar(
                    context,
                    'Please select a wallet to receive to.',
                  );
                  return;
                }
                if (state.amount == null || state.amount! <= 0) {
                  _amountFocus.requestFocus();
                  showSnackBar(context, 'Please enter a valid amount.');
                  return;
                }
                notifier.mintEcashToken();
                widget.doneCallback();
              },
              inverted: true,
            ),
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
