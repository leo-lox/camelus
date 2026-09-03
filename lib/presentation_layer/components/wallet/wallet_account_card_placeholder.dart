import 'package:material_ui/material_ui.dart';

class WalletAccountCardPlaceholder extends StatelessWidget {
  const WalletAccountCardPlaceholder({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(18.0),
          border: Border.all(
            width: 1,
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
        child: Center(
          child: Text(
            'add mint +',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
