import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ndk/ndk.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:riverpod/legacy.dart';
import '../../../atoms/long_button.dart';
import 'package:ndk/entities.dart' as ndk_entities;

import '../../../atoms/wallet/mint_info_card_small.dart';
import '../../../providers/ndk_provider.dart';

class ValidationState {
  final String text;
  final bool isValidating;
  final bool? isValid;
  final ndk_entities.CashuMintInfo? mintInfo;

  const ValidationState({
    this.text = '',
    this.isValidating = false,
    this.isValid,
    this.mintInfo,
  });

  ValidationState copyWith({
    String? text,
    bool? isValidating,
    bool? isValid,
    ndk_entities.CashuMintInfo? mintInfo,
    bool clearMintInfo = false,
  }) {
    return ValidationState(
      text: text ?? this.text,
      isValidating: isValidating ?? this.isValidating,
      isValid: isValid ?? this.isValid,
      mintInfo: clearMintInfo ? null : (mintInfo ?? this.mintInfo),
    );
  }
}

class AddMintNotifier extends StateNotifier<ValidationState> {
  final Ndk _ndk;
  AddMintNotifier({required Ndk ndk})
    : _ndk = ndk,
      super(const ValidationState());

  Timer? _debounceTimer;

  void updateText(String text) {
    state = state.copyWith(text: text, isValid: false, clearMintInfo: true);

    _debounceTimer?.cancel();

    if (text.isEmpty) {
      state = state.copyWith(
        isValidating: false,
        isValid: null,
        clearMintInfo: true,
      );
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _validateText(text);
    });
  }

  Future<void> _validateText(String text) async {
    state = state.copyWith(isValidating: true, clearMintInfo: true);

    final isValid = text.length >= 3 && !text.contains(' ');

    try {
      final mintInfoNetwork = await _ndk.cashu.getMintInfoNetwork(
        mintUrl: buildValidUrl(text),
      );

      state = state.copyWith(
        isValidating: false,
        isValid: isValid,
        mintInfo: mintInfoNetwork,
      );
    } catch (e) {
      state = state.copyWith(
        isValidating: false,
        isValid: false,
        clearMintInfo: true,
      );
      debugPrint('Error validating mint: $e');
      return;
    }
  }

  String buildValidUrl(String urlToCheck) {
    final text = urlToCheck.trim();
    if (text.isEmpty) return '';

    if (!text.startsWith('http://') && !text.startsWith('https://')) {
      return 'https://$text';
    }
    return text;
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}

final addMintProvider =
    StateNotifierProvider.autoDispose<AddMintNotifier, ValidationState>((ref) {
      final ndk = ref.watch(ndkProvider);
      return AddMintNotifier(ndk: ndk);
    });

class AddMintPage extends ConsumerWidget {
  const AddMintPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final validationState = ref.watch(addMintProvider);
    final notifier = ref.read(addMintProvider.notifier);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text('Add Mint'),
        backgroundColor: Theme.of(context).colorScheme.background,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Spacer(flex: 10),

            if (validationState.mintInfo != null)
              SingleChildScrollView(
                child: MintInfoCardSmall(mintInfo: validationState.mintInfo!),
              ),

            const Spacer(flex: 2),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: LinearProgressIndicator(
                value: validationState.isValidating ? null : 0.0,
                backgroundColor: Theme.of(context).colorScheme.surface,
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
            ),

            TextField(
              autofocus: true,
              onChanged: notifier.updateText,
              decoration: InputDecoration(
                hintText: 'Enter mint address...',
                border: const OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                suffixIcon: _buildValidationIcon(validationState),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),

            //const Spacer(flex: 1),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: longButton(
            name: "accept terms & add",
            onPressed: () {
              if (validationState.isValid == true &&
                  validationState.mintInfo != null) {
                final validUrl = notifier.buildValidUrl(validationState.text);
                ref
                    .read(ndkProvider)
                    .cashu
                    .addMintToKnownMints(mintUrl: validUrl);
                Navigator.pop(context);
              }
            },
            inverted: true,
            disabled: validationState.isValid != true,
          ),
        ),
      ),
    );
  }

  Widget? _buildValidationIcon(ValidationState state) {
    if (state.text.isEmpty) {
      return null;
    }

    if (state.isValid == true) {
      return Icon(PhosphorIcons.checkCircle(), color: Colors.green);
    }

    return null;
  }
}
