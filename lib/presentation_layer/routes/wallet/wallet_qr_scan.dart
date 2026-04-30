import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../atoms/spinner_center.dart';
import '../../components/wallet/animated_qr_scanner.dart';
import 'wallet_navigation.dart';
import 'wallet_pay/ln_input_parser.dart';
import 'wallet_pay/wallet_pay_state_provider.dart';
import 'wallet_providers/qr_value_processing_state_provider.dart';
import 'wallet_receive/rcv_completers/wallet_rcv_ecash_completer_state_provider.dart';

class WalletQrScan extends ConsumerStatefulWidget {
  const WalletQrScan({super.key});

  @override
  ConsumerState<WalletQrScan> createState() => _QrScan();
}

class _QrScan extends ConsumerState<WalletQrScan> {
  Barcode? _barcode;
  MobileScannerController controller = MobileScannerController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();

    super.dispose();
  }

  void _handleBarcode(BarcodeCapture barcodes) {
    if (mounted) {
      setState(() {
        _barcode = barcodes.barcodes.firstOrNull;
      });
    }
    if (_barcode != null) {
      _processValue(_barcode!.rawValue!);
    }
  }

  Future<String?> _handleReadClipboard() async {
    try {
      ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
      return data?.text;
    } catch (e) {
      ref
          .read(qrScannerProvider.notifier)
          .setError('Failed to read clipboard: $e');

      return null;
    }
  }

  void _processValue(String barcode) {
    if (barcode.toLowerCase().startsWith('ur:')) {
      ref.read(animatedQrScannerProvider.notifier).processPart(barcode);
    } else {
      ref.read(qrScannerProvider.notifier).processQRCode(barcode);
    }
  }

  @override
  Widget build(BuildContext context) {
    final qrScannerState = ref.watch(qrScannerProvider);

    // listen for completed animated (UR) QR tokens
    ref.listen(animatedQrScannerProvider, (previous, next) {
      if (previous?.completedToken == null && next.completedToken != null) {
        ref.read(animatedQrScannerProvider.notifier).reset();

        final rcvProvider = ref.read(
          walletReceiveEcashCompleterProvider.notifier,
        );
        rcvProvider.receiveEcash(
          tokenString: next.completedToken!.toV4TokenString(),
        );

        context.push('/wallet/receive/ecash');
        ref.read(walletNavigationProvider.notifier).changeDashboardPage(1);
      }
    });

    // apperently this is save to do with riverpod
    ref.listen(qrScannerProvider, (previous, next) {
      // only navigate if its new
      if (previous?.navigationTarget != next.navigationTarget &&
          next.navigationTarget != null &&
          next.navigationData != null) {
        ref.read(qrScannerProvider.notifier).clearNavigation();

        final rcvProvider = ref.read(
          walletReceiveEcashCompleterProvider.notifier,
        );

        switch (next.navigationTarget!) {
          case QRNavigationTarget.rcvPage:
            final ecashTokenString =
                next.navigationData!['cashuTokenString'] as String;
            rcvProvider.receiveEcash(tokenString: ecashTokenString);

            context.push('/wallet/receive/ecash');
            ref.read(walletNavigationProvider.notifier).changeDashboardPage(1);
            break;
          case QRNavigationTarget.sendPage:
            final payNotifier = ref.read(walletPayStateProvider.notifier);
            payNotifier.reset();

            final rawValue =
                (next.navigationData!['lnInvoice'] ??
                        next.navigationData!['lnAddress'])
                    as String?;

            if (rawValue != null) {
              final parser = ref.read(lnInputParserProvider);
              final parsed = parser.parse(rawValue);

              switch (parsed) {
                case LnInvoiceInput():
                  payNotifier.updateLnInvoice(parsed.invoice);
                  payNotifier.updateRecieverType(PaymentRecieverType.lnInvoice);
                  if (parsed.amountSat != null) {
                    payNotifier.updateAmount(parsed.amountSat!);
                    payNotifier.updateUnit('sat');
                  }
                  if (parsed.description != null) {
                    payNotifier.updateMemo(parsed.description);
                  }
                  final initialPage = parsed.amountSat != null ? 2 : 1;
                  context.push(
                    '/wallet/pay',
                    extra: {'initialPage': initialPage},
                  );
                case LnAddressInput():
                  payNotifier.updateLnAddress(parsed.address);
                  payNotifier.updateRecieverType(PaymentRecieverType.lnAddress);
                  context.push('/wallet/pay', extra: {'initialPage': 1});
                case null:
                  ref
                      .read(qrScannerProvider.notifier)
                      .setError('Unsupported QR content');
              }
            }
            break;
        }
      }
    });

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: _handleBarcode,
            errorBuilder: (p0, p1) {
              return Center(
                child: Text(
                  'Error: $p1',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 16,
                  ),
                ),
              );
            },
            placeholderBuilder: (context) {
              return SpinnerCenter();
            },
          ),

          // Container(
          //   width: MediaQuery.of(context).size.width,
          //   height: MediaQuery.of(context).size.height,
          //   decoration: BoxDecoration(
          //     border: Border.lerp(
          //       Border.all(color: Colors.black, width: 10),
          //       Border.all(color: Colors.transparent, width: 1),
          //       0.5,
          //     ),
          //     borderRadius: BorderRadius.circular(40),
          //   ),
          // ),

          /// scanning indicator
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: null,
            ),
          ),

          /// bottom area
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              alignment: Alignment.bottomCenter,
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withAlpha(200),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            _handleReadClipboard().then((value) {
                              if (value != null) {
                                _processValue(value);
                              }
                            });
                          },
                          icon: Icon(PhosphorIcons.clipboardText(), size: 18),
                          label: const Text('paste from clipboard'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                            foregroundColor: Theme.of(
                              context,
                            ).colorScheme.onPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          /// animated QR scan progress overlay
          Positioned(
            bottom: 135,
            left: 20,
            right: 20,
            child: AnimatedQrScanProgress(),
          ),

          if (qrScannerState.isProcessing)
            Positioned(
              bottom: 115,
              left: 20,
              right: 20,
              child: LinearProgressIndicator(
                borderRadius: BorderRadius.circular(20),
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.5),
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),

          /// top controls
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  qrScannerState.error != null
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Text(
                            qrScannerState.error ?? "",
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        )
                      : const SizedBox.shrink(),
                  IconButton(
                    onPressed: () => controller.toggleTorch(),
                    icon: const Icon(Icons.flash_on, color: Colors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
