import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../config/palette.dart';
import '../../atoms/spinner_center.dart';
import 'wallet_providers/qr_value_processing_state_provider.dart';

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
    ref.read(qrScannerProvider.notifier).processQRCode(barcode);
  }

  @override
  Widget build(BuildContext context) {
    final qrScannerState = ref.watch(qrScannerProvider);

    // apperently this is save to do with riverpod
    ref.listen(qrScannerProvider, (previous, next) {
      // only navigate if its new
      if (previous?.navigationTarget != next.navigationTarget &&
          next.navigationTarget != null &&
          next.navigationData != null) {
        ref.read(qrScannerProvider.notifier).clearNavigation();

        switch (next.navigationTarget!) {
          case QRNavigationTarget.rcvPage:
            Navigator.pushNamed(
              context,
              '/wallet/receive',
              arguments: next.navigationData,
            );
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
                  style: const TextStyle(color: Palette.error, fontSize: 16),
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
                border: Border.all(
                  color: Palette.white,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: Text(
                  'Position QR code here',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
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
                color: Palette.black.withValues(alpha: 0.8),
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
                          icon: Icon(
                            PhosphorIcons.clipboardText(),
                            size: 18,
                          ),
                          label: const Text('paste from clipboard'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Palette.primary,
                            foregroundColor: Palette.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (qrScannerState.isProcessing)
            Positioned(
              bottom: 115,
              left: 20,
              right: 20,
              child: LinearProgressIndicator(
                borderRadius: BorderRadius.circular(20),
                backgroundColor: Palette.extraDarkGray,
                color: Palette.white,
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
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Text(
                            qrScannerState.error ?? "",
                            style: const TextStyle(
                              color: Palette.warn,
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
