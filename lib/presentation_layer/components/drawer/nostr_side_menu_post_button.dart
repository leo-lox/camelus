import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../atoms/long_button.dart';
import '../../providers/ndk_provider.dart';
import '../write_post.dart';

class NostrSideMenuPostButton extends ConsumerWidget {
  const NostrSideMenuPostButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ndk = ref.watch(ndkProvider);
    final canSign = !ndk.accounts.cannotSign;

    return SizedBox(
      width: double.infinity,
      height: 40,
      child: longButton(
        inverted: true,
        name: "post",
        onPressed: () {
          if (!canSign) {
            // Show login dialog instead
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('Login Required'),
                content: Text('Please login to create posts'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      context.push('/onboarding');
                    },
                    child: Text('Login'),
                  ),
                ],
              ),
            );
            return;
          }

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
