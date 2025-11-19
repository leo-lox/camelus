import 'package:camelus/l10n/app_localizations.dart';
import 'package:camelus/presentation_layer/atoms/long_button.dart';
import 'package:camelus/presentation_layer/components/responsive_center.dart';
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
  final ValueNotifier<bool> _nameNotEmpty = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.userInfo.name ?? '';
    _nameNotEmpty.value = _nameController.text.isNotEmpty;

    // Use ValueNotifier instead of setState
    _nameController.addListener(() {
      _nameNotEmpty.value = _nameController.text.isNotEmpty;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocusNode.dispose();
    _nameNotEmpty.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ResponsiveCenter(
        maxWidth: 800,
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
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    onPressed: () => widget.onPressedBack!(),
                  ),
                ),
              ),
            const Spacer(flex: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                textAlign: TextAlign.start,
                cursorRadius: const Radius.circular(50),
                maxLines: 2,
                textAlignVertical: TextAlignVertical.center,
                autofocus: true,
                focusNode: _nameFocusNode,
                controller: _nameController,
                autofillHints: const [AutofillHints.name],
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.whatShouldWeCallYou,
                  contentPadding: EdgeInsets.zero,
                  hintStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  alignLabelWithHint: true,
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  widget.userInfo.name = value;
                },
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,

                  fontSize: 28,
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Spacer(flex: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                height: 40,
                child: ValueListenableBuilder<bool>(
                  valueListenable: _nameNotEmpty,
                  builder: (context, nameSelected, _) {
                    return longButton(
                      name: nameSelected
                          ? AppLocalizations.of(context)!.next
                          : AppLocalizations.of(context)!.skip,
                      onPressed: () {
                        _nameFocusNode.unfocus();
                        widget.submitCallback(_nameController.text);
                      },
                      inverted: nameSelected,
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 15),
          ],
        ),
      ),
    );
  }
}
