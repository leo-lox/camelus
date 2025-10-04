import 'package:camelus/presentation_layer/atoms/long_button.dart';
import 'package:camelus/config/palette.dart';
import 'package:camelus/domain_layer/entities/onboarding_user_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class OnboardingName extends ConsumerStatefulWidget {
  final Function submitCallback;
  final Function? onPressedBack;

  final OnboardingUserInfo userInfo;

  const OnboardingName({
    super.key,
    required this.submitCallback,
    required this.userInfo,
    this.onPressedBack,
  });
  @override
  ConsumerState<OnboardingName> createState() => _OnboardingNameState();
}

class _OnboardingNameState extends ConsumerState<OnboardingName> {
  final TextEditingController _nameController = TextEditingController();
  final FocusNode _nameFocusNode = FocusNode();

  bool nameSelected = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.userInfo.name ?? '';

    _nameController.addListener(() {
      setState(() {
        nameSelected = _nameController.text.isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Paletter.getBackground(context),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (widget.onPressedBack != null)
              Padding(
                padding: const EdgeInsets.all(30),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    icon: Icon(
                      PhosphorIcons.arrowLeft(),
                      color: Paletter.getWhite(context),
                    ),
                    onPressed: () => widget.onPressedBack!(),
                  ),
                ),
              ),
            const Spacer(
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
                focusNode: _nameFocusNode,
                controller: _nameController,
                autofillHints: const [AutofillHints.name],
                decoration: InputDecoration(
                  hintText: 'what should we call you?',
                  contentPadding: EdgeInsets.all(0),
                  hintStyle: TextStyle(
                    color: Paletter.getWhite(context),
                    letterSpacing: 1.1,
                  ),
                  alignLabelWithHint: true,
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  widget.userInfo.name = value;
                },
                style: TextStyle(
                  color: Paletter.getLightGray(context),
                  letterSpacing: 1.1,
                  fontSize: 28, // Increase the font size
                ),
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            const Spacer(
              flex: 1,
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              width: 400,
              height: 40,
              child: longButton(
                name: nameSelected ? "next" : "skip",
                onPressed: (() {
                  _nameFocusNode.unfocus();
                  widget.submitCallback(_nameController.text);
                }),
                inverted: nameSelected,
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
