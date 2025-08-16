import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ndk/entities.dart' as ndk_entities;

import '../../../../../config/palette.dart';
import '../../../../../helpers/wallet_number_formatting.dart';
import '../../../../atoms/long_button.dart';
import '../../../../components/wallet/animated_qr.dart';
import '../wallet_pay_state_provider.dart';

class WalletPayDone extends ConsumerWidget {
  const WalletPayDone({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletPayState = ref.watch(walletPayStateProvider);

    return Scaffold(
      backgroundColor: Palette.background,
      appBar: null,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: _buildCurrentStep(walletPayState),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: longButton(
            name: "close",
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStep(WalletPayState state) {
    if (state.isProcessing) {
      return const ProcessingStep();
    }

    if (state.isError) {
      return ErrorStep(errorMessage: state.errorMessage);
    }

    if (state.isSuccess && state.outputToken != null) {
      return SuccessStep(
        outputToken: state.outputToken!,
        amount: state.amount!,
        unit: state.unit!,
      );
    }

    return Container();
  }
}

// Processing step widget
class ProcessingStep extends StatelessWidget {
  const ProcessingStep({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(
          strokeWidth: 3,
        ),
        SizedBox(height: 24),
        Text(
          'Creating Token...',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class ErrorStep extends StatelessWidget {
  final String? errorMessage;

  const ErrorStep({super.key, this.errorMessage});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.error_outline,
          color: Palette.error,
          size: 80,
        ),
        const SizedBox(height: 24),
        const Text(
          'Error',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Palette.error,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: Text(
            errorMessage ?? 'An unknown error occurred',
            style: const TextStyle(
              fontSize: 16,
              color: Palette.error,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

// Success step widget
class SuccessStep extends StatelessWidget {
  final ndk_entities.CashuToken? outputToken;
  final int amount;
  final String unit;

  const SuccessStep({
    super.key,
    required this.outputToken,
    required this.amount,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              WalletNumberFormatting.formatAmount(
                amount: amount,
                unit: unit,
              ),
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Palette.white,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              unit,
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Palette.extraLightGray,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text(
          'Pending Ecash',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Palette.white,
          ),
        ),
        const SizedBox(height: 32),

        Container(
          width: 240,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Palette.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: AnimatedQr(
            qrCodeData: outputToken!.toV4TokenString(),
          ),
        ),
        const SizedBox(height: 32),

        const SizedBox(height: 24),

        /// copy button
        SizedBox(
          width: 250,
          child: CopyTokenButton(
            token: outputToken!.toV4TokenString(),
          ),
        ),
      ],
    );
  }
}

class CopyTokenButton extends StatefulWidget {
  final String token;

  const CopyTokenButton({super.key, required this.token});

  @override
  State<CopyTokenButton> createState() => _CopyTokenButtonState();
}

class _CopyTokenButtonState extends State<CopyTokenButton> {
  bool _copied = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _copied ? null : _copyToClipboard,
        icon: Icon(_copied ? Icons.check : Icons.copy),
        label: Text(_copied ? 'Copied to Clipboard!' : 'Copy Token'),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              _copied ? Palette.white : Palette.primary.withValues(alpha: 0.9),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Future<void> _copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: widget.token));
    setState(() {
      _copied = true;
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _copied = false;
        });
      }
    });
  }
}
