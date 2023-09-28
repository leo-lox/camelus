import 'package:camelus/atoms/long_button.dart';
import 'package:camelus/config/palette.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class OnboardingName extends ConsumerStatefulWidget {
  final Function nameCallback;

  const OnboardingName({
    Key? key,
    required this.nameCallback,
  }) : super(key: key);
  @override
  ConsumerState<OnboardingName> createState() => _OnboardingNameState();
}

class _OnboardingNameState extends ConsumerState<OnboardingName> {
  TextEditingController _nameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palette.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Spacer(
              flex: 20,
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              width: MediaQuery.of(context).size.width * 0.95,
              child: TextField(
                textAlign: TextAlign.justify,
                cursorRadius: const Radius.circular(50),
                maxLines: 2,
                textAlignVertical: TextAlignVertical.center,
                autofocus: true,
                controller: _nameController,
                autofillHints: const [AutofillHints.name],
                decoration: const InputDecoration(
                  hintText: 'what should we call you?',
                  contentPadding: EdgeInsets.all(0),
                  hintStyle: TextStyle(
                    color: Palette.white,
                    letterSpacing: 1.1,
                  ),
                  alignLabelWithHint: true,
                  border: InputBorder.none,
                ),
                style: const TextStyle(
                  color: Palette.lightGray,
                  letterSpacing: 1.1,
                  fontSize: 28, // Increase the font size
                ),
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            Spacer(
              flex: 1,
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              width: 400,
              height: 40,
              child: longButton(
                name: "next",
                onPressed: (() {
                  widget.nameCallback(_nameController.text);
                }),
                inverted: true,
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
