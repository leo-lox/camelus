import 'package:material_ui/material_ui.dart';

class CameraUpload extends StatelessWidget {
  final double size;
  const CameraUpload({super.key, this.size = 50});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface,
        shape: BoxShape.circle,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.camera_alt,
            size: size / 3,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.add,
                color: Theme.of(context).colorScheme.onSurface,
                size: size / 6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
