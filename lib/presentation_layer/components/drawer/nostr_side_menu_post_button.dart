import 'dart:ui';

import 'package:camelus/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import '../../atoms/long_button.dart';
import '../write_post.dart';

class NostrSideMenuPostButton extends StatelessWidget {
  const NostrSideMenuPostButton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 40,
      child: longButton(
        inverted: true,
        name: AppLocalizations.of(context)!.post,
        onPressed: () {
          showModalBottomSheet(
            isScrollControlled: true,
            elevation: 10,
            isDismissible: false,
            context: context,
            builder: (context) => BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: const WritePost(),
              ),
            ),
          );
        },
      ),
    );
  }
}
