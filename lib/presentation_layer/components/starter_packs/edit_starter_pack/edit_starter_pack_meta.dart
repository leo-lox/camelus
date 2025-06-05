import 'package:camelus/presentation_layer/atoms/long_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/palette.dart';
import 'edit_starter_pack_provider.dart';

class EditStarterPackMeta extends ConsumerStatefulWidget {
  final String starterPackId;
  final Function onNext;
  const EditStarterPackMeta({
    super.key,
    required this.starterPackId,
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
      final data = ref.read(editStarterPackProvider(widget.starterPackId));
      _titleController.text = data.title;
      _descriptionController.text = data.description;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final starterPackData =
        ref.watch(editStarterPackProvider(widget.starterPackId));
    final starterPackNotifier =
        ref.watch(editStarterPackProvider(widget.starterPackId).notifier);

    return Scaffold(
      backgroundColor: Palette.background,
      appBar: AppBar(
        backgroundColor: Palette.background,
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

                  Image.asset("assets/images/list_placeholder.png",
                      width: 80, height: 80),

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

                  const SizedBox(height: 16),

                  // Subtitle
                  const Text(
                    'Invite your friends to follow your favorite people',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 60),

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
                          color: Palette.extraDarkGray,
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
                                  ? Palette.warn
                                  : Palette.gray,
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
                          color: Palette.extraDarkGray,
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
