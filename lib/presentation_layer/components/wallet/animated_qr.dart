import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ndk/entities.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:ur/cashu_token_ur_encoder.dart';
import 'package:ur/ur_encoder.dart';

import '../../routes/wallet/wallet_providers/qr_settings_provider.dart';

class AnimatedQr extends ConsumerStatefulWidget {
  final CashuToken token;
  final double size;

  const AnimatedQr({super.key, required this.token, this.size = 200});

  @override
  ConsumerState<AnimatedQr> createState() => _AnimatedQrState();
}

class _AnimatedQrState extends ConsumerState<AnimatedQr> {
  String? _currentQrData;
  Timer? _timer;
  UREncoder? _encoder;
  bool _isSinglePart = false;
  int _currentPartIndex = 0;
  int _totalParts = 0;
  bool showAnimatedQr = true;

  @override
  void initState() {
    super.initState();
    _initializeEncoder();
  }

  @override
  void didUpdateWidget(AnimatedQr oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.token != widget.token) {
      _timer?.cancel();
      _initializeEncoder();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _initializeEncoder() {
    _setupMultiPartEncoding();
  }

  void _setupMultiPartEncoding() {
    final settings = ref.read(qrSettingsProvider);

    _encoder = CashuTokenUrEncoder.createMultiPartEncoder(
      token: widget.token,
      maxFragmentLen: settings.maxFragmentLen,
    );

    if (_encoder != null) {
      final firstPart = _encoder!.nextPart();
      setState(() {
        _currentQrData = firstPart;
        _isSinglePart = false;
        _currentPartIndex = 1;
      });

      _estimateTotalParts();
      _startAnimation();
    }
  }

  void _estimateTotalParts() {
    int count = 1;
    while (!_encoder!.isComplete) {
      _encoder!.nextPart();
      count++;
    }
    _totalParts = count;

    // Reset encoder with same settings
    final settings = ref.read(qrSettingsProvider);
    _encoder = CashuTokenUrEncoder.createMultiPartEncoder(
      token: widget.token,
      maxFragmentLen: settings.maxFragmentLen,
    );
    _currentPartIndex = 0;
  }

  void _startAnimation() {
    final settings = ref.read(qrSettingsProvider);

    _timer?.cancel();
    _timer = Timer.periodic(Duration(milliseconds: settings.frameDelayMs), (_) {
      if (_encoder != null && mounted) {
        final nextPart = _encoder!.nextPart();
        setState(() {
          _currentQrData = nextPart;
          _currentPartIndex = (_currentPartIndex % _totalParts) + 1;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<QrSettings>(qrSettingsProvider, (previous, next) {
      if (previous?.frameDelayMs != next.frameDelayMs ||
          previous?.maxFragmentLen != next.maxFragmentLen) {
        _timer?.cancel();
        _initializeEncoder();
      }
    });

    if (_currentQrData == null) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );
    }

    final qrData = showAnimatedQr
        ? _currentQrData!
        : widget.token.toV4TokenString();

    return Column(
      children: [
        Container(
          width: widget.size,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: PrettyQrView.data(
            data: qrData,
            decoration: const PrettyQrDecoration(
              shape: PrettyQrSmoothSymbol(color: Colors.black),
              background: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            if (showAnimatedQr && !_isSinglePart && _totalParts > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black, width: 1),
                ),
                child: Text(
                  '$_currentPartIndex/$_totalParts',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const Spacer(),
            Switch(
              activeColor: Colors.black,
              value: showAnimatedQr,
              onChanged: (value) {
                setState(() {
                  showAnimatedQr = value;
                });
              },
            ),
          ],
        ),
      ],
    );
  }
}
