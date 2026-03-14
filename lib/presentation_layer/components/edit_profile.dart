import 'dart:typed_data';

import 'package:camelus/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../atoms/camer_upload.dart';
import '../atoms/round_image_border.dart';

// to control upload state
final editProfilePictureUploadingProvider =
    NotifierProvider<EditProfilePictureUploadingNotifier, bool>(
      EditProfilePictureUploadingNotifier.new,
    );

class EditProfilePictureUploadingNotifier extends Notifier<bool> {
  @override
  bool build() {
    return false;
  }

  void setUploading(bool uploading) {
    state = uploading;
  }
}

final editProfileBannerUploadingProvider =
    NotifierProvider<EditProfileBannerUploadingNotifier, bool>(
      EditProfileBannerUploadingNotifier.new,
    );

class EditProfileBannerUploadingNotifier extends Notifier<bool> {
  @override
  bool build() {
    return false;
  }

  void setUploading(bool uploading) {
    state = uploading;
  }
}

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
  final String initialPronouns;
  final Function(String) onPronounsChanged;

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
    required this.initialPronouns,
    required this.onNameChanged,
    required this.pictureCallback,
    required this.bannerCallback,
    required this.onAboutChanged,
    required this.onNip05Changed,
    required this.onWebsiteChanged,
    required this.onLud06Changed,
    required this.onLud16Changed,
    required this.onPronounsChanged,
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
      'pronouns': TextEditingController(text: widget.initialPronouns),
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
          case 'pronouns':
            widget.onPronounsChanged(controller.text);
            break;
        }
      });
    });
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isUploadingPicture = ref.watch(editProfilePictureUploadingProvider);
    final isUploadingBanner = ref.watch(editProfileBannerUploadingProvider);

    return Column(
      children: [
        _buildHeader(isUploadingPicture, isUploadingBanner),
        _buildForm(),
      ],
    );
  }

  Widget _buildHeader(bool isUploadingPicture, bool isUploadingBanner) {
    return SizedBox(
      height: (MediaQuery.of(context).size.height / 6) + 60,
      child: Stack(
        children: <Widget>[
          // Banner section
          InkWell(
            onTap: isUploadingBanner ? null : widget.bannerCallback,
            child: Stack(
              children: [
                // Banner image or background
                Container(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height / 6,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    image: widget.initialBanner != null
                        ? DecorationImage(
                            image: MemoryImage(widget.initialBanner!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                ),

                // Banner upload overlay
                if (isUploadingBanner)
                  Container(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height / 6,
                    color: Theme.of(
                      context,
                    ).colorScheme.surface.withValues(alpha: 0.8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.uploading,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.inverseSurface,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).colorScheme.primary,
                              ),
                              minHeight: 6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          Positioned(
            bottom: 0,
            left: MediaQuery.of(context).size.width / 8,
            child: InkWell(
              onTap: isUploadingPicture ? null : widget.pictureCallback,
              child: Stack(
                children: [
                  widget.initialPicture == null
                      ? const CameraUpload(size: 100)
                      : RoundImageWithBorder(
                          image: widget.initialPicture!,
                          size: 102,
                        ),
                  if (isUploadingPicture) _buildUploadingProfilePicture(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadingProfilePicture() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Background circle
        Container(
          width: 102,
          height: 102,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
            shape: BoxShape.circle,
            border: Border.all(
              color: Theme.of(context).colorScheme.primary,
              width: 3,
            ),
          ),
        ),

        // Circular progress indicator
        SizedBox(
          width: 60,
          height: 60,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),

        // Text in the center
        Text(
          AppLocalizations.of(context)!.uploadingCapitalized,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildInputField(
            AppLocalizations.of(context)!.name,
            _controllers['name']!,
          ),
          _buildInputField(
            AppLocalizations.of(context)!.bio,
            _controllers['about']!,
            isMultiline: true,
          ),
          _buildInputField(
            AppLocalizations.of(context)!.pronouns,
            _controllers['pronouns']!,
          ),
          _buildInputField(
            AppLocalizations.of(context)!.website,
            _controllers['website']!,
          ),
          _buildInputField(
            AppLocalizations.of(context)!.username,
            _controllers['nip05']!,
          ),
          _buildInputField(
            AppLocalizations.of(context)!.lightningAddress,
            _controllers['lud16']!,
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(
    String label,
    TextEditingController controller, {
    bool isMultiline = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16.0, bottom: 8.0, left: 8.0),
          child: Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          decoration: InputDecoration(
            hintText: "",
            hintStyle: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              letterSpacing: 1.1,
            ),
            contentPadding: EdgeInsets.symmetric(
              vertical: 8.0,
              horizontal: 8.0,
            ),
            filled: true,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),

              borderSide: BorderSide(color: Colors.transparent),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
          maxLines: isMultiline ? 3 : 1,
          keyboardType: isMultiline
              ? TextInputType.multiline
              : TextInputType.text,
        ),
      ],
    );
  }
}
