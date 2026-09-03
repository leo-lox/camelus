import 'package:material_ui/material_ui.dart';

class SpinnerCenter extends StatelessWidget {
  const SpinnerCenter({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
