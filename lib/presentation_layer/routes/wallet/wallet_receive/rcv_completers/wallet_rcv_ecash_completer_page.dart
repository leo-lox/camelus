import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../../helpers/wallet_number_formatting.dart';
import '../../../../atoms/long_button.dart';
import 'wallet_rcv_ecash_completer_state_provider.dart';

class WalletReceiveEcashCompleterPage extends ConsumerWidget {
  const WalletReceiveEcashCompleterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletState = ref.watch(walletReceiveEcashCompleterProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: null,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Spacer(flex: 1),
              // Status Card
              _buildStatusCard(walletState, context),

              Spacer(flex: 7),

              if (walletState.amount != null && walletState.unit != null) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '+',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 28,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      WalletNumberFormatting.formatAmount(
                        amount: walletState.amount!,
                        unit: walletState.unit!,
                      ),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      walletState.unit ?? '',
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ],
              Spacer(flex: 1),
              if (walletState.memo != null) ...[
                const SizedBox(height: 16),
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width - 32,
                    // max height for memo
                    maxHeight: 120,
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      walletState.memo!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],

              if (walletState.errorMessage != null) ...[
                Spacer(flex: 1),
                _ErrorCard(errorMessage: walletState.errorMessage!),
              ],
              Spacer(flex: 10),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: longButton(
            name: "close",
            onPressed: () => {context.pop()},
            inverted: true,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard(
    WalletRcvEcashCompleterState state,
    BuildContext context,
  ) {
    IconData icon;
    Color color;
    String title;
    String subtitle;

    if (state.isPending) {
      icon = PhosphorIcons.hourglass();
      color = Theme.of(context).colorScheme.primary;
      title = 'Processing';
      subtitle = 'Receiving...';
    } else if (state.isError) {
      icon = PhosphorIcons.warningCircle();
      color = Theme.of(context).colorScheme.error;
      title = 'Failed';
      subtitle = 'transaction failed';
    } else if (state.isSuccess) {
      icon = PhosphorIcons.checkCircle();
      color = Colors.green;
      title = 'Success';
      subtitle = 'received successfully';
    } else {
      icon = PhosphorIcons.info();
      color = Colors.grey;
      title = 'Ready';
      subtitle = 'waiting for transaction';
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withAlpha(153),
                    ),
                  ),
                ],
              ),
            ),
            if (state.isPending)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.errorMessage});

  final String errorMessage;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      color: Theme.of(context).colorScheme.onError,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.error,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Error',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    errorMessage,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
