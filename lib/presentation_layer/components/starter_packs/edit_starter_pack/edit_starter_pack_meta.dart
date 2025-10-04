import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../config/palette.dart';
import '../../../../domain_layer/entities/mem_file.dart';
import '../../../../domain_layer/entities/starter_pack_identifier.dart';
import '../../../atoms/crop_avatar.dart';
import '../../../atoms/icon_patter.dart';
import '../../../atoms/long_button.dart';
import '../../../providers/file_upload_provider.dart';
import 'edit_starter_pack_provider.dart';

class EditStarterPackMeta extends ConsumerStatefulWidget {
  final StarterPackIdentifier starterPackIdentifier;
  final Function onNext;
  const EditStarterPackMeta({
    super.key,
    required this.starterPackIdentifier,
    required this.onNext,
  });
  @override
  ConsumerState<EditStarterPackMeta> createState() =>
      _EditStarterPackMetaState();
}

class _EditStarterPackMetaState extends ConsumerState<EditStarterPackMeta> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();

    // Listen to provider changes and update controllers
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final data =
          ref.read(editStarterPackProvider(widget.starterPackIdentifier));
      _titleController.text = data.title;
      _descriptionController.text = data.description ?? "";
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<XFile?> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final result = await picker.pickImage(source: ImageSource.gallery);
    return result;
  }

  Future<void> _bannerUpload() async {
    final pickedImage = await _pickImage();
    if (pickedImage == null) return;
    final uneditedImage = await pickedImage.readAsBytes();
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute<Uint8List>(
        builder: (context) => CropAvatar(
          resize: true,
          targetWidth: 400,
          roundUi: false,
          aspectRatio: 16 / 6,
          buttonText: "upload",
          imageData: uneditedImage,
        ),
      ),
    ).then((value) async {
      if (value != null) {
        final stateNoti = ref.read(
            editStarterPackProvider(widget.starterPackIdentifier).notifier);
        stateNoti.updateImage(imageUploading: true);

        final editedFile = MemFile(
          bytes: value,
          mimeType: pickedImage.mimeType ?? '',
          name: pickedImage.name,
        );
        final imageUrl = await _uploadImage(editedFile);

        if (imageUrl == null) return;

        stateNoti.updateImage(imageUploading: false, imageurl: imageUrl);
      }
    });
  }

  Future<String?> _uploadImage(MemFile imageData) async {
    final uploadResult =
        await ref.read(fileUploadProvider).uploadImage(imageData);
    final hostedImageUrl = uploadResult
        .firstWhere((e) => e.descriptor?.url.isNotEmpty == true)
        .descriptor
        ?.url;
    return hostedImageUrl;
  }

  @override
  Widget build(BuildContext context) {
    final starterPackData =
        ref.watch(editStarterPackProvider(widget.starterPackIdentifier));
    final starterPackNotifier = ref
        .watch(editStarterPackProvider(widget.starterPackIdentifier).notifier);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Starter Pack',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  // Title
                  const Text(
                    'create your starter pack',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  // Subtitle
                  const Text(
                    'Invite your friends to follow your favorite people',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 70),
                  GestureDetector(
                    onTap: () => _bannerUpload(),
                    child: Container(
                      constraints: BoxConstraints(minWidth: 100, maxWidth: 350),
                      child: AspectRatio(
                        aspectRatio: 16 / 6,
                        child: Stack(
                          children: [
                            starterPackData.imageUrl != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.network(
                                      starterPackData.imageUrl!,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : IconPattern(
                                    borderRadius: BorderRadius.circular(10),
                                  ),

                            // upload loading overlay
                            if (starterPackData.imageUploading)
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.6),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Uploading...',
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.onSurface,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Form fields
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Title',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Title input
                      Container(
                        decoration: BoxDecoration(
                          color: Paletter.getExtraDarkGray(context),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextField(
                          controller: _titleController,
                          onChanged: (value) {
                            starterPackNotifier.updateTitle(value);
                          },
                          style: const TextStyle(
                              color: Colors.white, fontSize: 18),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(16),
                            suffixText: '${starterPackData.title.length}/40',
                            suffixStyle: TextStyle(
                              color: starterPackData.title.length > 40
                                  ? Colors.orangeAccent
                                  : Paletter.getGray(context),
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Description',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Description input
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: Paletter.getExtraDarkGray(context),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextField(
                          controller: _descriptionController,
                          onChanged: (value) {
                            starterPackNotifier.updateDescription(value);
                          },
                          style: const TextStyle(
                              color: Colors.white, fontSize: 16),
                          maxLines: null,
                          expands: true,
                          textAlignVertical: TextAlignVertical.top,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(16),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: SafeArea(
              top: false,
              child: SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: longButton(
                      name: "next",
                      inverted: true,
                      onPressed: () {
                        widget.onNext();
                      })),
            ),
          ),
        ],
      ),
    );
  }
}
