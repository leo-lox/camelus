import 'dart:typed_data';
import 'dart:convert' show base64Decode, base64Url, utf8;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bc_ur_dart/bc_ur_dart.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'dart:async';

class AnimatedQr extends ConsumerStatefulWidget {
  final String? qrCodeData;

  const AnimatedQr({super.key, this.qrCodeData});

  @override
  ConsumerState<AnimatedQr> createState() => AnimatedQrState();
}

class AnimatedQrState extends ConsumerState<AnimatedQr> {
  Timer? _timer;
  int _currentIndex = 0;
  List<String> _urParts = [];
  UR? _encoder;

  bool showAnimatedQr = true;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _initializeUR();
  }

  @override
  void didUpdateWidget(AnimatedQr oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.qrCodeData != widget.qrCodeData) {
      _timer?.cancel();
      _initializeUR();
    }
  }

  void _initializeUR() {
    if (widget.qrCodeData != null && widget.qrCodeData!.isNotEmpty) {
      try {
        final tokenString = widget.qrCodeData!;

        Uint8List bytes;
        if (tokenString.startsWith('cashuB')) {
          /// remove cashuB prefix
          final tokenData = tokenString.substring(6);

          /// fix: add padding for base64url decoding
          String paddedTokenData = tokenData;
          while (paddedTokenData.length % 4 != 0) {
            paddedTokenData += '=';
          }

          bytes = base64Url.decode(paddedTokenData);
        } else {
          bytes = utf8.encode(tokenString);
        }

        const int maxLength = 200;

        _encoder = UR(
          payload: bytes,
          maxLength: maxLength,
          type: "bytes",
        );

        _urParts.clear();

        final minParts = (bytes.length / maxLength).ceil();
        final targetParts = (minParts * 1.5).ceil(); // 50% overhead

        for (int i = 0; i < targetParts; i++) {
          final part = _encoder!.next();
          _urParts.add(part);
        }

        if (_urParts.isNotEmpty) {
          _startAnimation();
        }
      } catch (e) {
        // fallback to single QR code if UR encoding fails
        _urParts = [widget.qrCodeData!];
      }
    }
  }

  void _startAnimation() {
    if (_urParts.length > 1) {
      _timer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
        if (mounted) {
          setState(() {
            _currentIndex = (_currentIndex + 1) % _urParts.length;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_urParts.isEmpty) {
      return Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text(
            'No QR Data',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Container(
      child: Column(
        children: [
          if (showAnimatedQr && _urParts.isNotEmpty)
            PrettyQrView.data(
              data: _urParts[_currentIndex],
              decoration: const PrettyQrDecoration(
                shape: PrettyQrSmoothSymbol(
                  color: Colors.black,
                ),
                background: Colors.white,
              ),
            ),
          const SizedBox(height: 8),
          if (!showAnimatedQr)
            PrettyQrView.data(
              data: widget.qrCodeData ?? '',
              decoration: const PrettyQrDecoration(
                shape: PrettyQrSmoothSymbol(
                  color: Colors.black,
                ),
                background: Colors.white,
              ),
            ),
          Row(
            children: [
              if (showAnimatedQr && _urParts.length > 1)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black, width: 1),
                  ),
                  child: Text(
                    '${_currentIndex + 1}/${_urParts.length}',
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
                  }),
            ],
          )
        ],
      ),
    );
  }
}
