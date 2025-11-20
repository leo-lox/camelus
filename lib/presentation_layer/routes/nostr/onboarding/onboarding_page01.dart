import 'package:camelus/l10n/app_localizations.dart';
import 'package:camelus/presentation_layer/atoms/long_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';

class OnboardingPage01 extends ConsumerStatefulWidget {
  final Function loginCallback;
  final Function registerCallback;

  const OnboardingPage01({
    super.key,
    required this.loginCallback,
    required this.registerCallback,
  });
  @override
  ConsumerState<OnboardingPage01> createState() => _OnboardingPage01State();
}

class _OnboardingPage01State extends ConsumerState<OnboardingPage01> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 10),
            Text(
              AppLocalizations.of(context)!.welcomeTo,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: MediaQuery.of(context).size.width / 22,
              ),
            ),
            Text(
              AppLocalizations.of(context)!.camelus,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: MediaQuery.of(context).size.width / 7,
                fontFamily: 'Poppins',
              ),
            ),
            const Spacer(flex: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              width: 400,
              height: 40,
              child: longButton(
                name: AppLocalizations.of(context)!.joinTheConversation,
                onPressed: (() {
                  widget.registerCallback();
                }),
                inverted: true,
              ),
            ),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              width: 400,
              height: 40,
              child: longButton(
                name: AppLocalizations.of(context)!.login,
                onPressed: (() {
                  widget.loginCallback();
                }),
                inverted: false,
              ),
            ),
            const SizedBox(height: 30),
            TextButton(
              onPressed: () {
                context.go('/home');
              },
              child: Text(
                AppLocalizations.of(context)!.browseWithoutLogin,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 14,
                ),
              ),
            ),
            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }
}
