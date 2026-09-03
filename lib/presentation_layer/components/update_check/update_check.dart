import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../domain_layer/entities/app_update.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/app_update_provider.dart';
import '../../providers/language_provider.dart';

class UpdateCheck extends ConsumerStatefulWidget {
  final Widget child;
  const UpdateCheck({super.key, required this.child});

  @override
  ConsumerState<UpdateCheck> createState() => _UpdateCheckState();
}

class _UpdateCheckState extends ConsumerState<UpdateCheck> {
  Future<void> _checkForUpdates() async {
    await Future.delayed(const Duration(seconds: 15));
    if (!mounted) return;

    final appUpdate = ref.read(appUpdateProvider);
    final updateInfo = await appUpdate.call();

    if (updateInfo.isUpdateAvailable && mounted) {
      _showUpdateDialog(updateInfo);
    }
  }

  void _showUpdateDialog(AppUpdate updateInfo) {
    showDialog(
      context: context,
      builder: (BuildContext context) => UpdateDialog(updateInfo: updateInfo),
    );
  }

  @override
  void initState() {
    super.initState();

    _checkForUpdates();

    // set initail page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // set system locale if no locale is set
      ref
          .read(languageProvider.notifier)
          .initializeWithSystemLocaleIfNeeded(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class UpdateDialog extends StatelessWidget {
  final AppUpdate updateInfo;

  const UpdateDialog({super.key, required this.updateInfo});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      title: Text(updateInfo.title),
      content: Text(updateInfo.body),
      actions: <Widget>[
        TextButton(
          child: Text(AppLocalizations.of(context)!.cancel),
          onPressed: () => Navigator.of(context).pop(),
        ),
        TextButton(
          child: Text(AppLocalizations.of(context)!.update),
          onPressed: () {
            launchUrl(
              Uri.parse(updateInfo.url),
              mode: LaunchMode.externalApplication,
            );
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
