// ignore_for_file: experimental_member_use
import 'dart:async';

import 'package:camelus/presentation_layer/atoms/long_button.dart';
import 'package:camelus/presentation_layer/atoms/wallet/mint_info_card_small.dart';
import 'package:camelus/presentation_layer/providers/ndk_provider.dart';
import 'package:camelus/presentation_layer/routes/wallet/wallet_providers/wallet_seed_state_provider.dart';
import 'package:camelus/presentation_layer/routes/wallet/wallet_restore/wallet_restore_state_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ndk/entities.dart';

enum _PageStep { loading, warnExistingSeed, enterSeed, restoring }

class WalletRestorePage extends ConsumerStatefulWidget {
  const WalletRestorePage({super.key});

  @override
  ConsumerState<WalletRestorePage> createState() => _WalletRestorePageState();
}

class _WalletRestorePageState extends ConsumerState<WalletRestorePage> {
  _PageStep _step = _PageStep.loading;
  bool _continuingWithExistingSeed = false;

  final _seedController = TextEditingController();
  final _mintUrlController = TextEditingController();
  final _passphraseController = TextEditingController();
  bool _usePassphrase = false;
  bool _showSeedPhrase = false;
  String? _errorText;

  // Mint validation
  CashuMintInfo? _mintInfo;
  bool _isValidatingMint = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncStep());
  }

  @override
  void dispose() {
    _seedController.dispose();
    _mintUrlController.dispose();
    _passphraseController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _syncStep() {
    if (!mounted || _step == _PageStep.restoring) return;
    final seedState = ref.read(walletSeedStateProvider);
    if (seedState.isLoading) return;
    setState(() {
      _step = seedState.cashuSeed != null
          ? _PageStep.warnExistingSeed
          : _PageStep.enterSeed;
    });
  }

  void _continueWithExistingSeed() {
    setState(() {
      _continuingWithExistingSeed = true;
      _step = _PageStep.enterSeed;
    });
  }

  String _buildValidUrl(String url) {
    final text = url.trim();
    if (!text.startsWith('http://') && !text.startsWith('https://')) {
      return 'https://$text';
    }
    return text;
  }

  void _onMintUrlChanged(String text) {
    setState(() {
      _mintInfo = null;
      _isValidatingMint = false;
    });
    _debounceTimer?.cancel();
    if (text.trim().isEmpty) return;
    setState(() => _isValidatingMint = true);
    _debounceTimer = Timer(
      const Duration(milliseconds: 600),
      () => _validateMintUrl(text),
    );
  }

  Future<void> _validateMintUrl(String text) async {
    try {
      final ndk = ref.read(ndkProvider);
      final info = await ndk.cashu.getMintInfoNetwork(
        mintUrl: _buildValidUrl(text),
      );
      if (mounted) {
        setState(() {
          _mintInfo = info;
          _isValidatingMint = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _mintInfo = null;
          _isValidatingMint = false;
        });
      }
    }
  }

  Future<void> _deleteSeed() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete wallet seed & all wallets?'),
        content: const Text(
          'This will permanently delete all wallets and remove the stored seed phrase from this device. '
          'All wallet data will be lost. Ensure you have your seed phrase backed up — '
          'there is no way to recover it afterwards.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await ref.read(walletSeedStateProvider.notifier).deleteSeed();
      setState(() => _step = _PageStep.enterSeed);
    }
  }

  Future<void> _startRestore() async {
    final mintUrl = _mintUrlController.text.trim();

    if (!_continuingWithExistingSeed) {
      final seedPhrase = _seedController.text.trim();
      if (seedPhrase.isEmpty) {
        setState(() => _errorText = 'Please enter your seed phrase.');
        return;
      }
    }

    if (mintUrl.isEmpty || _mintInfo == null) {
      setState(
        () => _errorText =
            'Please enter a valid mint URL and wait for validation.',
      );
      return;
    }

    setState(() {
      _errorText = null;
      _step = _PageStep.restoring;
    });

    if (!_continuingWithExistingSeed) {
      final seedNotifier = ref.read(walletSeedStateProvider.notifier);
      final seed = CashuUserSeedphrase(
        seedPhrase: _seedController.text.trim(),
        language: Language.english,
        passphrase: _usePassphrase ? _passphraseController.text : '',
      );
      await seedNotifier.setSeedStorage(seed);
      seedNotifier.setSeed(seed);
    }

    final units = _mintInfo!.supportedUnits.toList();
    final effectiveUnits = units.isEmpty ? ['sat'] : units;

    await ref
        .read(restoreStateProvider.notifier)
        .startRestoreAllUnits(
          mintUrl: _buildValidUrl(mintUrl),
          units: effectiveUnits,
        );
  }

  void _stopRestore() {
    ref.read(restoreStateProvider.notifier).reset();
    setState(() => _step = _PageStep.enterSeed);
  }

  void _restoreAnotherMint() {
    ref.read(restoreStateProvider.notifier).reset();
    setState(() => _step = _PageStep.enterSeed);
  }

  @override
  Widget build(BuildContext context) {
    final seedState = ref.watch(walletSeedStateProvider);
    final restoreState = ref.watch(restoreStateProvider);

    // Sync step once seed finishes loading
    if (_step == _PageStep.loading && !seedState.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _syncStep());
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Restore wallet')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: _buildContent(restoreState),
      ),
    );
  }

  Widget _buildContent(RestoreState restoreState) {
    return switch (_step) {
      _PageStep.loading => const Center(
        child: Padding(
          padding: EdgeInsets.only(top: 64),
          child: CircularProgressIndicator(),
        ),
      ),
      _PageStep.warnExistingSeed => _WarnExistingSeedStep(
        onDeleteSeed: _deleteSeed,
        onContinue: _continueWithExistingSeed,
      ),
      _PageStep.enterSeed => _EnterSeedStep(
        seedController: _seedController,
        mintUrlController: _mintUrlController,
        passphraseController: _passphraseController,
        usePassphrase: _usePassphrase,
        showSeedPhrase: _showSeedPhrase,
        isValidatingMint: _isValidatingMint,
        mintInfo: _mintInfo,
        errorText: _errorText,
        showSeedSection: !_continuingWithExistingSeed,
        onUsePassphraseChanged: (v) => setState(() {
          _usePassphrase = v;
          if (!v) _passphraseController.clear();
        }),
        onToggleSeedVisibility: () =>
            setState(() => _showSeedPhrase = !_showSeedPhrase),
        onMintUrlChanged: _onMintUrlChanged,
        onStartRestore: _startRestore,
      ),
      _PageStep.restoring => _RestoringStep(
        restoreState: restoreState,
        onStop: _stopRestore,
        onRestoreAnotherMint: _restoreAnotherMint,
      ),
    };
  }
}

// ── Step 1: warn about existing seed ──────────────────────────────────────

class _WarnExistingSeedStep extends StatelessWidget {
  const _WarnExistingSeedStep({
    required this.onDeleteSeed,
    required this.onContinue,
  });

  final VoidCallback onDeleteSeed;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Existing seed phrase detected',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSecondaryContainer,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'You already have a wallet seed stored. You can restore additional mints with your existing seed, or delete it and restore from a different seed phrase.',
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: longButton(
            name: 'Continue with existing seed',
            onPressed: onContinue,
            inverted: true,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: longButton(
            name: 'Delete seed & use a different one',
            onPressed: onDeleteSeed,
          ),
        ),
      ],
    );
  }
}

// ── Step 2: enter seed phrase ─────────────────────────────────────────────

class _EnterSeedStep extends StatelessWidget {
  const _EnterSeedStep({
    required this.seedController,
    required this.mintUrlController,
    required this.passphraseController,
    required this.usePassphrase,
    required this.showSeedPhrase,
    required this.isValidatingMint,
    required this.onUsePassphraseChanged,
    required this.onToggleSeedVisibility,
    required this.onMintUrlChanged,
    required this.onStartRestore,
    this.mintInfo,
    this.errorText,
    this.showSeedSection = true,
  });

  final TextEditingController seedController;
  final TextEditingController mintUrlController;
  final TextEditingController passphraseController;
  final bool usePassphrase;
  final bool showSeedPhrase;
  final bool isValidatingMint;
  final CashuMintInfo? mintInfo;
  final ValueChanged<bool> onUsePassphraseChanged;
  final VoidCallback onToggleSeedVisibility;
  final ValueChanged<String> onMintUrlChanged;
  final VoidCallback onStartRestore;
  final String? errorText;
  final bool showSeedSection;

  @override
  Widget build(BuildContext context) {
    final canStart = mintInfo != null && !isValidatingMint;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Seed phrase section (hidden when continuing with existing seed) ──
        if (showSeedSection) ...[
          const Text(
            'Enter seed phrase',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            'Enter the 12 or 24-word seed phrase you want to restore.',
          ),
          const SizedBox(height: 20),

          Stack(
            alignment: Alignment.topRight,
            children: [
              TextField(
                controller: seedController,
                minLines: showSeedPhrase ? 3 : 1,
                maxLines: showSeedPhrase ? 6 : 1,
                obscureText: !showSeedPhrase,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Seed phrase',
                  hintText: 'word1 word2 word3 ...',
                  alignLabelWithHint: true,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4, right: 4),
                child: IconButton(
                  icon: Icon(
                    showSeedPhrase ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: onToggleSeedVisibility,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Use BIP39 passphrase'),
            subtitle: const Text(
              'Enable only if your original seed was created with a passphrase.',
            ),
            value: usePassphrase,
            onChanged: onUsePassphraseChanged,
          ),
          if (usePassphrase) ...[
            const SizedBox(height: 8),
            TextField(
              controller: passphraseController,
              obscureText: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Passphrase',
              ),
            ),
          ],
          const SizedBox(height: 24),
        ] else ...[
          const Text(
            'Restore from mint',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your existing seed phrase will be used. Enter a mint URL to restore funds from.',
          ),
          const SizedBox(height: 20),
        ],

        // ── Mint URL ──
        const Text('Mint URL', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: mintUrlController,
          keyboardType: TextInputType.url,
          autocorrect: false,
          onChanged: onMintUrlChanged,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: 'Mint URL',
            hintText: 'https://mint.example.com',
            suffixIcon: isValidatingMint
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : mintInfo != null
                ? const Icon(Icons.check_circle_outline, color: Colors.green)
                : null,
          ),
        ),

        // ── Mint info card ──
        if (mintInfo != null) ...[
          const SizedBox(height: 16),
          MintInfoCardSmall(mintInfo: mintInfo!),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final unit in mintInfo!.supportedUnits)
                Chip(label: Text(unit)),
            ],
          ),
        ],

        if (errorText != null) ...[
          const SizedBox(height: 12),
          Text(
            errorText!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          child: longButton(
            name: 'Start restore',
            onPressed: onStartRestore,
            inverted: true,
            disabled: !canStart,
          ),
        ),
      ],
    );
  }
}

// ── Step 3: restore in progress / complete ────────────────────────────────

class _RestoringStep extends StatelessWidget {
  const _RestoringStep({
    required this.restoreState,
    required this.onStop,
    required this.onRestoreAnotherMint,
  });

  final RestoreState restoreState;
  final VoidCallback onStop;
  final VoidCallback onRestoreAnotherMint;

  @override
  Widget build(BuildContext context) {
    final isDone = restoreState.isComplete && !restoreState.isRestoring;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (restoreState.isRestoring) ...[
          const Text(
            'Restoring wallet…',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          if (restoreState.pendingUnits.length > 1 &&
              restoreState.restoringUnit != null) ...[
            const SizedBox(height: 6),
            Text(
              'Unit ${restoreState.pendingUnits.indexOf(restoreState.restoringUnit!) + 1} '
              'of ${restoreState.pendingUnits.length}: ${restoreState.restoringUnit}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ] else if (restoreState.restoringUnit != null) ...[
            const SizedBox(height: 6),
            Text(
              'Restoring unit: ${restoreState.restoringUnit}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 12),
          const LinearProgressIndicator(),
        ] else if (isDone) ...[
          Row(
            children: [
              Icon(
                Icons.check_circle_outline,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              const Text(
                'Restore complete',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ] else ...[
          const Text(
            'Starting restore…',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          const LinearProgressIndicator(),
        ],

        if (restoreState.error != null) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              restoreState.error!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],

        const SizedBox(height: 28),

        if (restoreState.restoredAmountByUnit.isEmpty)
          const _StatCard(label: 'Restored amount', value: '—')
        else
          ...restoreState.restoredAmountByUnit.entries.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _StatCard(
                label: 'Restored (${e.key})',
                value: '${e.value}',
              ),
            ),
          ),
        const SizedBox(height: 12),
        _StatCard(
          label: 'Proofs restored',
          value: '${restoreState.totalProofCount}',
        ),
        const SizedBox(height: 12),
        _StatCard(
          label: 'Current counter',
          value: '${restoreState.currentCounter}',
        ),

        const SizedBox(height: 28),

        SizedBox(
          width: double.infinity,
          child: restoreState.isRestoring
              ? longButton(name: 'Stop restore', onPressed: onStop)
              : longButton(
                  name: 'Restore another mint',
                  onPressed: onRestoreAnotherMint,
                  inverted: true,
                ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
