import 'dart:io';

import 'package:camelus/config/palette.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OnboardingImage extends ConsumerStatefulWidget {
  final Function imageCallback;

  const OnboardingImage({
    super.key,
    required this.imageCallback,
  });
  @override
  ConsumerState<OnboardingImage> createState() => _OnboardingImageState();
}

class _OnboardingImageState extends ConsumerState<OnboardingImage> {
  _addImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.image,
      dialogTitle: "select profile image",
    );

    if (result != null) {
      File file = File(result.files.single.path!);
    } else {
      // User canceled the picker
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palette.background,
      body: Center(
        child: TextButton(
          onPressed: () {
            _addImage();
          },
          child: const Text('Select Image'),
        ),
      ),
    );
  }
}
