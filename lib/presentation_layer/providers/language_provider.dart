import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../domain_layer/repositories/app_db.dart';
import 'db_app_provider.dart';

// Define a class to manage language state
class LanguageState {
  final Locale locale;

  const LanguageState({required this.locale});

  LanguageState copyWith({Locale? locale}) {
    return LanguageState(locale: locale ?? this.locale);
  }
}

// Define a notifier class to handle language changes
class LanguageNotifier extends StateNotifier<LanguageState> {
  static const String _dbLangKey = 'app_language';
  final AppDb _appDb;

  // Initialize with a default locale first
  LanguageNotifier(this._appDb)
    : super(const LanguageState(locale: Locale('en'))) {
    // Then load the saved locale asynchronously
    _initializeLocale();
  }

  Future<void> _initializeLocale() async {
    final savedLocale = await _getSavedLocale(_appDb);
    if (savedLocale != null) {
      // Use the saved locale from DB if it exists
      state = LanguageState(locale: savedLocale);
    } else {
      // keep the default 'en' locale, context not available here
    }
  }

  Future<void> initializeWithSystemLocaleIfNeeded(BuildContext context) async {
    final savedLocale = await _getSavedLocale(_appDb);
    if (savedLocale == null) {
      // ignore: use_build_context_synchronously
      final deviceLocale = Localizations.localeOf(context);
      state = state.copyWith(locale: deviceLocale);
    }
  }

  // Helper to get saved locale from app database
  static Future<Locale?> _getSavedLocale(AppDb appDb) async {
    final String? languageCode = await appDb.read(_dbLangKey);
    if (languageCode != null) {
      // Split into language and country code if present
      final parts = languageCode.split('_');
      if (parts.length > 1) {
        return Locale(parts[0], parts[1]);
      }
      return Locale(parts[0]);
    }
    return null;
  }

  // Get system locale
  Future<void> loadSystemLocale(BuildContext context) async {
    final deviceLocale = Localizations.localeOf(context);
    await changeLanguage(deviceLocale);
  }

  // Change app language
  Future<void> changeLanguage(Locale locale) async {
    // Save to app database
    if (locale.countryCode != null) {
      await _appDb.save(
        key: _dbLangKey,
        value: '${locale.languageCode}_${locale.countryCode}',
      );
    } else {
      await _appDb.save(key: _dbLangKey, value: locale.languageCode);
    }

    // Update state
    state = state.copyWith(locale: locale);

    DefaultCacheManager().emptyCache();
  }

  // Reset to system language
  Future<void> resetToSystemLanguage(BuildContext context) async {
    // Get device locale
    final deviceLocale = Localizations.localeOf(context);
    // Clear saved preference
    await _appDb.delete(_dbLangKey);

    state = state.copyWith(locale: deviceLocale);
  }
}

// StateNotifierProvider for language
final languageProvider = StateNotifierProvider<LanguageNotifier, LanguageState>(
  (ref) {
    final appDb = ref.watch(dbAppProvider);
    return LanguageNotifier(appDb);
  },
);

// Provider to get current locale
final currentLocaleProvider = Provider<Locale>((ref) {
  return ref.watch(languageProvider).locale;
});
