import 'package:camelus/presentation_layer/atoms/long_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ndk/entities.dart';

import 'wallet_providers/wallet_seed_state_provider.dart';

class WalletSeedSetupOverlay extends ConsumerStatefulWidget {
  const WalletSeedSetupOverlay({super.key});

  @override
  ConsumerState<WalletSeedSetupOverlay> createState() =>
      _WalletSeedSetupOverlayState();
}

class _WalletSeedSetupOverlayState
    extends ConsumerState<WalletSeedSetupOverlay> {
  late Future<String> _generatedSeedFuture;

  final _passwordController = TextEditingController();
  bool _protectWithPassword = false;
  bool _isSubmitting = false;
  bool _showSeedPhrase = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _generatedSeedFuture = ref
        .read(walletSeedStateProvider.notifier)
        .generateSeedPhrase();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _confirmSeed(String seedPhrase) async {
    final notifier = ref.read(walletSeedStateProvider.notifier);
    final password = _passwordController.text.trim();

    if (_protectWithPassword && password.isEmpty) {
      setState(() {
        _errorText = 'Please enter a password to protect this wallet seed.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    final seed = CashuUserSeedphrase(
      seedPhrase: seedPhrase,
      language: Language.english,
      passphrase: _protectWithPassword ? password : '',
    );

    await notifier.setSeedStorage(seed);
    notifier.setSeed(seed);

    if (mounted) {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Future<void> _unlockStoredSeed() async {
    final notifier = ref.read(walletSeedStateProvider.notifier);

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    final unlocked = await notifier.getSeedFromStorage(
      password: _passwordController.text.trim(),
    );

    if (mounted) {
      setState(() {
        _isSubmitting = false;
        if (unlocked?.cashuSeed == null) {
          _errorText = 'Unable to unlock wallet seed. Please try again.';
        }
      });
    }
  }

  void _cancelSetup() {
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final seedState = ref.watch(walletSeedStateProvider);

    if (seedState.cashuSeed != null) {
      return const SizedBox.shrink();
    }

    if (seedState.isLoading) {
      return _WalletOverlayCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading wallet setup...'),
          ],
        ),
      );
    }

    if (seedState.passwordRequired) {
      return _WalletOverlayCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Unlock Wallet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your stored seed is password-protected, enter your password to continue. Warning: Entering a wrong password will not raise an error, technically a new wallet seed will be generated (not advised!)',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Password',
              ),
            ),
            if (_errorText != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorText!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _unlockStoredSeed,
                child: Text(_isSubmitting ? 'Unlocking...' : 'Unlock Wallet'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _isSubmitting ? null : _cancelSetup,
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      );
    }

    return FutureBuilder<String>(
      future: _generatedSeedFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _WalletOverlayCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Generating secure seed phrase...'),
              ],
            ),
          );
        }

        final seedPhrase = snapshot.data!;

        return _WalletOverlayCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Wallet Setup',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'The wallet feature is experimental! Save your seed phrase safely, it is the only way to recover this wallet.',
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        _showSeedPhrase
                            ? seedPhrase
                            : '•••••••• •••••••• •••••••• •••••••• •••••••• •••••••• •••••••• •••••••• •••••••• •••••••• •••••••• •••••••• •••••••• •••••••• •••••••• •••••••• •••••••• •••••••• •••••••• •••••••• •••••••• •••••••• •••••••• ••••••••',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _showSeedPhrase
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _showSeedPhrase = !_showSeedPhrase;
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: seedPhrase));
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Seed phrase copied')),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded),
                  label: const Text('Copy seed phrase'),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Hint: Write these words down offline and never share them. Anyone with this phrase can spend your funds.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Protect seed with password'),
                subtitle: const Text(
                  'You will need this password each time this wallet is unlocked.',
                ),
                value: _protectWithPassword,
                onChanged: _isSubmitting
                    ? null
                    : (value) {
                        setState(() {
                          _protectWithPassword = value;
                          if (!value) {
                            _passwordController.clear();
                          }
                        });
                      },
              ),
              if (_protectWithPassword)
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Password',
                  ),
                ),
              if (_errorText != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorText!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: longButton(
                  name: _isSubmitting ? 'Saving...' : 'I saved my seed phrase',
                  onPressed: () {
                    _isSubmitting ? null : _confirmSeed(seedPhrase);
                  },
                  inverted: true,
                ),
              ),

              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: longButton(
                  name: "Cancel",
                  onPressed: () {
                    _isSubmitting ? null : _cancelSetup();
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WalletOverlayCard extends StatelessWidget {
  const _WalletOverlayCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.55),
        padding: const EdgeInsets.all(20),
        alignment: Alignment.center,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: Card(
            elevation: 8,
            child: Padding(padding: const EdgeInsets.all(16), child: child),
          ),
        ),
      ),
    );
  }
}
