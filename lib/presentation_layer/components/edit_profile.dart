import 'dart:developer'; 
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../config/palette.dart';
import '../atoms/camer_upload.dart';
import '../atoms/round_image_border.dart';

/// A screen for editing the user's profile, allowing updates to various fields like name
class EditProfile extends ConsumerStatefulWidget {
  // Fields to initialize and update the profile.
  final String initialName;
  final Function(String) onNameChanged;
  final Uint8List? initialPicture;
  final Function() pictureCallback;
  final Uint8List? initialBanner;
  final Function() bannerCallback;
  final String initialAbout;
  final Function(String) onAboutChanged;
  final String initialNip05;
  final Function(String) onNip05Changed;
  final String initialWebsite;
  final Function(String) onWebsiteChanged;
  final String initialLud06;
  final Function(String) onLud06Changed;
  final String initialLud16;
  final Function(String) onLud16Changed;

  const EditProfile({
    super.key,
    required this.initialName,
    required this.initialPicture,
    required this.initialBanner,
    required this.initialAbout,
    required this.initialNip05,
    required this.initialWebsite,
    required this.initialLud06,
    required this.initialLud16,
    required this.onNameChanged,
    required this.pictureCallback,
    required this.bannerCallback,
    required this.onAboutChanged,
    required this.onNip05Changed,
    required this.onWebsiteChanged,
    required this.onLud06Changed,
    required this.onLud16Changed,
  });

  @override
  ConsumerState<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends ConsumerState<EditProfile> {
  // Controller map to manage form fields.
  late final Map<String, TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    // Initializing the controllers with provided initial values.
    _controllers = {
      'name': TextEditingController(text: widget.initialName),
      'about': TextEditingController(text: widget.initialAbout),
      'nip05': TextEditingController(text: widget.initialNip05),
      'website': TextEditingController(text: widget.initialWebsite),
      'lud06': TextEditingController(text: widget.initialLud06),
      'lud16': TextEditingController(text: widget.initialLud16),
    };

    // Adding listeners to each controller to call the corresponding callback when the text changes.
    _controllers.forEach((key, controller) {
      controller.addListener(() {
        switch (key) {
          case 'name':
            widget.onNameChanged(controller.text);
            break;
          case 'about':
            widget.onAboutChanged(controller.text);
            break;
          case 'nip05':
            widget.onNip05Changed(controller.text);
            break;
          case 'website':
            widget.onWebsiteChanged(controller.text);
            break;
          case 'lud06':
            widget.onLud06Changed(controller.text);
            break;
          case 'lud16':
            widget.onLud16Changed(controller.text);
            break;
        }
      });
    });
  }

  @override
  void dispose() {
    // Disposing of all controllers when the widget is disposed.
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(), // Building the header section with profile picture and banner.
        _buildForm(), // Building the form with input fields for profile details.
      ],
    );
  }

  /// Builds the header section of the profile with banner and profile picture.
  Widget _buildHeader() {
    return SizedBox(
      height: (MediaQuery.of(context).size.height / 6) + 60,
      child: Stack(
        children: <Widget>[
          InkWell(
            onTap: () {
              widget.bannerCallback(); // Trigger callback to update banner when clicked.
            },
            child: Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height / 6,
              decoration: BoxDecoration(
                color: Palette.darkGray,
                image: widget.initialBanner != null
                    ? DecorationImage(
                        image: MemoryImage(widget.initialBanner!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
            ),
          ),
          // Positioned profile picture in the header section.
          Positioned(
            bottom: 0,
            left: MediaQuery.of(context).size.width / 8,
            child: InkWell(
              onTap: () {
                widget.pictureCallback(); // Trigger callback to update profile picture when clicked.
              },
              child: widget.initialPicture == null
                  ? const CameraUpload(
                      size: 100, 
                    )
                  : RoundImageWithBorder(
                      image: widget.initialPicture!, size: 102),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the form section with input fields for profile details.
  Widget _buildForm() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildInputField('Name', _controllers['name']!),
          _buildInputField('Bio', _controllers['about']!, isMultiline: true),
          _buildInputField('Website', _controllers['website']!),
          _buildInputField('nip05', _controllers['nip05']!),
          _buildInputField('lud06', _controllers['lud06']!),
          _buildInputField('lud16', _controllers['lud16']!),
        ],
      ),
    );
  }

  /// Builds a single input field with a label and controller.
  Widget _buildInputField(String label, TextEditingController controller,
      {bool isMultiline = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16.0, bottom: 8.0, left: 8.0),
          child: Text(
            label, // Display the label of the input field.
            style: TextStyle(
              color: const Color.fromARGB(213, 245, 248, 250),
              fontSize: MediaQuery.of(context).size.width / 28,
            ),
          ),
        ),
        TextFormField(
          controller: controller, // Bind the controller to the input field.
          decoration: textEditInputDecoration, 
          maxLines: isMultiline
              ? null
              : 1, 
          keyboardType:
              isMultiline ? TextInputType.multiline : TextInputType.text, // Set keyboard type.
        ),
      ],
    );
  }
}

/// Decoration for the text input fields in the form.
const textEditInputDecoration = InputDecoration(
  hintText: "",
  contentPadding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
  enabledBorder: UnderlineInputBorder(
    borderSide: BorderSide(
      width: 1,
      color: Colors.grey, // Border color for the text field.
    ),
  ),
);
