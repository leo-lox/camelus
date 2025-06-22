import 'package:flutter/material.dart';

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../config/palette.dart';
import '../../../../domain_layer/entities/onboarding_user_info.dart';
import '../../../atoms/long_button.dart';
import '../../../atoms/username_input.dart';
import '../../../providers/serverpod_provider.dart';

const mydomain = 'camelus.app';

class OnboardingUsername extends ConsumerStatefulWidget {
  final Function submitCallback;

  final OnboardingUserInfo userInfo;

  const OnboardingUsername({
    super.key,
    required this.submitCallback,
    required this.userInfo,
  });
  @override
  ConsumerState<OnboardingUsername> createState() => _OnboardingUsernameState();
}

class _OnboardingUsernameState extends ConsumerState<OnboardingUsername> {
  final FocusNode _nameFocusNode = FocusNode();

  bool _isChecking = false;
  bool _isAvailable = false;
  bool _show = false;
  List<String> _suggestions = [];
  Timer? _debounce;

  String username = "";

  @override
  void initState() {
    super.initState();

    setState(() {
      username = widget.userInfo.nip05?.split('@')[0] ?? '';
    });

    if (username.isNotEmpty) {
      _onUsernameChange(username);
    }
  }

  _onUsernameChange(String username) {
    setState(() {
      _isChecking = true;
    });

    if (username.isNotEmpty) {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 500), () {
        _checkUsernameAvailability(username);
      });
    } else {
      _debounce?.cancel();
      setState(() {
        _isAvailable = false;

        _show = false;
        _suggestions = [];
      });
    }
  }

  Future<void> _checkUsernameAvailability(String username) async {
    if (username.isEmpty) return;

    setState(() {
      _isChecking = true;
      _show = true;
    });

    try {
      final serverpodProv = ref.read(serverpodProvider);

      final checkRes =
          await serverpodProv.client.nip05.checkName(username, mydomain);

      if (checkRes.isAvailable) {
        widget.userInfo.nip05 = '$username@$mydomain';
      } else {
        widget.userInfo.nip05 = '';
      }

      setState(() {
        _isAvailable = checkRes.isAvailable;
        _suggestions = checkRes.suggestions;
        _isChecking = false;
        _show = true;
      });
    } catch (e) {
      setState(() {
        _isChecking = false;
        _isAvailable = false;
        _suggestions = [];
        _show = true;
      });
    }
  }

  void _selectSuggestion(String suggestion) {
    _onUsernameChange(suggestion);
    setState(() {
      username = suggestion;
      _suggestions = [];
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();

    _nameFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palette.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Spacer(flex: 20),
            // Suggestions list
            if (_suggestions.isNotEmpty)
              Container(
                height: 120,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Suggestions:",
                      style: TextStyle(
                        color: Palette.lightGray,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Expanded(
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _suggestions.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: GestureDetector(
                              onTap: () =>
                                  _selectSuggestion(_suggestions[index]),
                              child: Chip(
                                backgroundColor: Palette.darkGray,
                                label: Text(
                                  _suggestions[index],
                                  style: const TextStyle(
                                    color: Palette.lightGray,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

            // Username status indicator

            Row(
              children: [
                const SizedBox(height: 10),
                UsernameInputField(
                  domain: "@camelus.app",
                  onChange: (name) {
                    _onUsernameChange(name);
                  },
                  username: username,
                  trailing: Row(
                    children: [
                      const SizedBox(width: 5),
                      if (_show && _isAvailable && !_isChecking)
                        Icon(
                          PhosphorIcons.sealCheck(),
                          size: 29,
                        ),
                      if (_show && !_isAvailable && !_isChecking)
                        Icon(
                          PhosphorIcons.sealWarning(),
                          size: 29,
                        ),
                      if (_show && _isChecking)
                        Icon(
                          PhosphorIcons.sealQuestion(),
                          size: 29,
                        ),
                      // Icon(
                      //   PhosphorIcons.seal(),
                      //   size: 29,
                      // ),
                    ],
                  ),
                ),
              ],
            ),

            const Spacer(
              flex: 1,
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              width: 400,
              height: 40,
              child: longButton(
                name: _isAvailable ? "next" : "skip",
                onPressed: (() {
                  _nameFocusNode.unfocus();
                  widget.submitCallback(username);
                }),
                inverted: _isAvailable,
              ),
            ),
            const SizedBox(
              height: 15,
            ),
          ],
        ),
      ),
    );
  }
}
