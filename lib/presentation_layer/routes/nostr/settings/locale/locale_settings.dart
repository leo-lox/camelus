import 'package:camelus/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../../config/palette.dart';
import '../../../../providers/language_provider.dart';

class LocaleSettingsPage extends ConsumerStatefulWidget {
  const LocaleSettingsPage({super.key});

  @override
  LocaleSettingsPageState createState() => LocaleSettingsPageState();
}

class LocaleSettingsPageState extends ConsumerState<LocaleSettingsPage> {
  final List<Map<String, dynamic>> availableLocales = [
    {'name': 'English', 'locale': const Locale('en', 'US')},
    {'name': 'Deutsch', 'locale': const Locale('de', 'DE')},
    {'name': '日本語', 'locale': const Locale('ja', 'JP')},
    {'name': '中文', 'locale': const Locale('zh', 'CN')},
    {'name': 'ไทย', 'locale': const Locale('th', 'TH')},
    {'name': 'Português', 'locale': const Locale('pt', 'BR')},
    {'name': 'Español', 'locale': const Locale('es', 'ES')},
    {'name': 'Français', 'locale': const Locale('fr', 'FR')},
    {'name': 'Русский', 'locale': const Locale('ru', 'RU')},
  ];

  bool _isSystemLanguage = false;

  @override
  void initState() {
    super.initState();
    // Check if we're using system language on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkIfSystemLanguage();
    });
  }

  // Check if the current locale matches the system locale
  void _checkIfSystemLanguage() {
    final currentLocale = ref.read(currentLocaleProvider);
    final systemLocale = Localizations.localeOf(context);

    setState(() {
      _isSystemLanguage =
          currentLocale.languageCode == systemLocale.languageCode &&
          (currentLocale.countryCode == systemLocale.countryCode ||
              (currentLocale.countryCode == null &&
                  systemLocale.countryCode == null));
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentLocale = ref.watch(currentLocaleProvider);
    final languageNotifier = ref.watch(languageProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.languageSettings),
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),

          ListTile(
            title: Text(
              AppLocalizations.of(context)!.useSystemLanguage,
              style: TextStyle(color: Paletter.getLightGray(context)),
            ),
            trailing: _isSystemLanguage
                ? Icon(
                    PhosphorIcons.check(),
                    color: Theme.of(context).colorScheme.onSurface,
                  )
                : null,
            onTap: () async {
              await languageNotifier.resetToSystemLanguage(context);
              setState(() {
                _isSystemLanguage = true;
              });
            },
            tileColor: Theme.of(context).colorScheme.surface,
          ),

          Divider(color: Paletter.getDarkGray(context), height: 1),

          // Available languages list
          Expanded(
            child: ListView.builder(
              itemCount: availableLocales.length,
              itemBuilder: (context, index) {
                final localeInfo = availableLocales[index];
                final locale = localeInfo['locale'] as Locale;
                final isSelected =
                    !_isSystemLanguage &&
                    currentLocale.languageCode == locale.languageCode &&
                    currentLocale.countryCode == locale.countryCode;

                return ListTile(
                  title: Text(
                    localeInfo['name'],
                    style: TextStyle(color: Paletter.getLightGray(context)),
                  ),
                  trailing: isSelected
                      ? Icon(
                          PhosphorIcons.check(),
                          color: Theme.of(context).colorScheme.onSurface,
                        )
                      : null,
                  onTap: () async {
                    await languageNotifier.changeLanguage(locale);
                    setState(() {
                      _isSystemLanguage = false;
                    });
                  },
                  tileColor: Theme.of(context).colorScheme.surface,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
