import 'package:camelus/presentation_layer/components/images_gallery.dart';
import 'package:camelus/presentation_layer/providers/event_feed/event_feed_provider.dart';
import 'package:camelus/presentation_layer/providers/parsed_note_cache_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EventGalleryPage extends ConsumerStatefulWidget {
  final String eventId;
  final int startIndex;

  const EventGalleryPage({
    super.key,
    required this.eventId,
    this.startIndex = 0,
  });

  @override
  ConsumerState<EventGalleryPage> createState() => _EventGalleryPageState();
}

class _EventGalleryPageState extends ConsumerState<EventGalleryPage> {
  @override
  Widget build(BuildContext context) {
    final noteTree = ref.watch(eventFeedStateProvider(widget.eventId));

    if (noteTree.rootNote == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final parsedPostAsync = ref.watch(
      parsedNoteCacheProvider(noteTree.rootNote!),
    );

    return parsedPostAsync.when(
      data: (parsedPost) {
        if (parsedPost == null) {
          return const Scaffold(body: Center(child: Text('Event not found')));
        }

        if (parsedPost.imageUrls.isEmpty) {
          return const Scaffold(
            body: Center(child: Text('No images in this event')),
          );
        }

        return ImageGallery(
          imageUrls: parsedPost.imageUrls,
          defaultImageIndex: widget.startIndex.clamp(
            0,
            parsedPost.imageUrls.length - 1,
          ),
          topBarTitle: 'Gallery',
          heroTag: widget.eventId,
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) =>
          Scaffold(body: Center(child: Text('Error loading event: $error'))),
    );
  }
}
