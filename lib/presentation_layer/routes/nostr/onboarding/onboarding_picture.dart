import 'dart:io';
import 'dart:typed_data';

import 'package:camelus/domain_layer/entities/mem_file.dart';
import 'package:camelus/presentation_layer/atoms/crop_avatar.dart';
import 'package:camelus/presentation_layer/atoms/my_profile_picture.dart';
import 'package:camelus/config/palette.dart';
import 'package:camelus/domain_layer/entities/onboarding_user_info.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mime/mime.dart';

import '../../../atoms/camer_upload.dart';
import '../../../atoms/long_button.dart';

class OnboardingPicture extends ConsumerStatefulWidget {
  final Function pictureCallback;

  final OnboardingUserInfo signUpInfo;

  const OnboardingPicture({
    super.key,
    required this.pictureCallback,
    required this.signUpInfo,
  });
  @override
  ConsumerState<OnboardingPicture> createState() => _OnboardingPictureState();
}

class _OnboardingPictureState extends ConsumerState<OnboardingPicture> {
  bool pictureSelected = false;

  _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      File file = File(result.files.single.path!);

      Uint8List imageData = file.readAsBytesSync();
      String imageMimeType = lookupMimeType(file.path) ?? '';
      String imageName = file.path.split('/').last;

      MemFile memFile = MemFile(
        bytes: imageData,
        mimeType: imageMimeType,
        name: imageName,
      );
      widget.signUpInfo.picture = memFile;
      _openCropImagePopup(memFile.bytes);
    } else {
      // User canceled the picker
      return;
    }
  }

  Uint8List? _displayImage;

  _openCropImagePopup(Uint8List imageData) {
    // push fullscreen widget
    Navigator.push(
      context,
      MaterialPageRoute<Uint8List>(
        builder: (context) => CropAvatar(
          imageData: imageData,
        ),
      ),
    ).then((value) {
      if (value != null) {
        setState(() {
          widget.signUpInfo.picture!.bytes = value;
          pictureSelected = true;
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();
    if (widget.signUpInfo.picture != null) {
      pictureSelected = true;
    }
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
            const Spacer(
              flex: 1,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                const Text("Welcome ", style: TextStyle(fontSize: 20)),
                const SizedBox(
                  width: 5,
                ),
                Text(
                  widget.signUpInfo.name ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 23,
                  ),
                ),
              ],
            ),
            const Spacer(
              flex: 1,
            ),
            InkWell(
              borderRadius: BorderRadius.all(Radius.circular(50)),
              onTap: () {
                _pickFile();
              },
              child: widget.signUpInfo.picture == null
                  ? const CameraUpload(
                      size: 125,
                    )
                  : ClipOval(
                      child: SizedBox.fromSize(
                        size: const Size.square(125),
                        child: Container(
                            color: Palette.background,
                            child:
                                Image.memory(widget.signUpInfo.picture!.bytes)),
                      ),
                    ),
            ),
            const Spacer(
              flex: 1,
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              width: 400,
              height: 40,
              child: longButton(
                name: pictureSelected ? "next" : "skip",
                onPressed: (() {
                  widget.pictureCallback();
                }),
                inverted: pictureSelected,
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
