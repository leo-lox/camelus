import 'package:material_ui/material_ui.dart';
import 'package:flutter_link_previewer/flutter_link_previewer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'link_preview_state_provider.dart';

class LinkPreviewWidget extends ConsumerWidget {
  const LinkPreviewWidget({
    super.key,
    required double fontSize,
    required this.url,
  }) : _fontSize = fontSize;

  final double _fontSize;
  final String url;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LinkPreview(
      linkStyle: TextStyle(
        color: Theme.of(context).colorScheme.primary,
        fontSize: _fontSize - 2,
        decoration: TextDecoration.none,
      ),
      enableAnimation: true,
      onPreviewDataFetched: (data) {
        ref.read(linkPreviewProvider(url).notifier).setPreview(data);
      },
      previewData: ref.watch(linkPreviewProvider(url)),
      text: url,
      textWidget: Text(
        url,
        style: TextStyle(color: Theme.of(context).colorScheme.primary),
      ),
      width: MediaQuery.of(context).size.width,
      hideImage: false,
      previewBuilder: (context, previewData) {
        return Container(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              if (previewData.image != null)
                Container(
                  width: 80,
                  height: 80,
                  margin: const EdgeInsets.only(right: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      previewData.image!.url,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (previewData.title != null)
                      Text(
                        previewData.title!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    if (previewData.description != null)
                      Text(
                        previewData.description!.substring(
                          0,
                          previewData.description!.length > 100
                              ? 100
                              : previewData.description!.length,
                        ),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
