import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/default_relays.dart';
import 'db_app_provider.dart';
import 'inbox_outbox_provider.dart';
import 'messaging/dm_relay_list_provider.dart';
import 'notifications_provider.dart';
import 'signer_provider.dart';

const String _dbKindsKey = 'push_kinds';
const String _dbRelaysKey = 'push_relays';
const String _dbTokenKey = 'fcm_token';
const String _dbPermissionRequestedKey = 'push_permission_requested';

final notificationSettingsProvider =
    NotifierProvider<NotificationSettingsNotifier, NotificationSettingsState>(
      NotificationSettingsNotifier.new,
    );

class NotificationRelayOption {
  final String url;
  final bool isDmRelay;
  final bool isInboxRelay;
  final bool isOutboxRelay;

  const NotificationRelayOption({
    required this.url,
    required this.isDmRelay,
    required this.isInboxRelay,
    required this.isOutboxRelay,
  });

  int get priority {
    if (isDmRelay) {
      return 0;
    }
    if (isInboxRelay) {
      return 1;
    }
    if (isOutboxRelay) {
      return 2;
    }
    return 3;
  }

  NotificationRelayOption merge(NotificationRelayOption other) {
    return NotificationRelayOption(
      url: url,
      isDmRelay: isDmRelay || other.isDmRelay,
      isInboxRelay: isInboxRelay || other.isInboxRelay,
      isOutboxRelay: isOutboxRelay || other.isOutboxRelay,
    );
  }
}

class NotificationSettingsState {
  static const Object _noChange = Object();

  final bool isLoading;
  final bool isEnablingNotifications;
  final bool platformSupported;
  final bool notificationsEnabled;
  final bool notificationsDenied;
  final bool permissionRequested;
  final List<int> selectedKinds;
  final List<NotificationRelayOption> availableRelays;
  final List<String> selectedRelays;
  final String? relaySelectionError;
  final DateTime? lastSyncAt;
  final bool syncSuccessVisible;
  final String? syncError;

  const NotificationSettingsState({
    required this.isLoading,
    required this.isEnablingNotifications,
    required this.platformSupported,
    required this.notificationsEnabled,
    required this.notificationsDenied,
    required this.permissionRequested,
    required this.selectedKinds,
    required this.availableRelays,
    required this.selectedRelays,
    required this.relaySelectionError,
    required this.lastSyncAt,
    required this.syncSuccessVisible,
    required this.syncError,
  });

  NotificationSettingsState copyWith({
    bool? isLoading,
    bool? isEnablingNotifications,
    bool? platformSupported,
    bool? notificationsEnabled,
    bool? notificationsDenied,
    bool? permissionRequested,
    List<int>? selectedKinds,
    List<NotificationRelayOption>? availableRelays,
    List<String>? selectedRelays,
    Object? relaySelectionError = _noChange,
    Object? lastSyncAt = _noChange,
    bool? syncSuccessVisible,
    Object? syncError = _noChange,
  }) {
    return NotificationSettingsState(
      isLoading: isLoading ?? this.isLoading,
      isEnablingNotifications:
          isEnablingNotifications ?? this.isEnablingNotifications,
      platformSupported: platformSupported ?? this.platformSupported,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      notificationsDenied: notificationsDenied ?? this.notificationsDenied,
      permissionRequested: permissionRequested ?? this.permissionRequested,
      selectedKinds: selectedKinds ?? this.selectedKinds,
      availableRelays: availableRelays ?? this.availableRelays,
      selectedRelays: selectedRelays ?? this.selectedRelays,
      relaySelectionError: identical(relaySelectionError, _noChange)
          ? this.relaySelectionError
          : relaySelectionError as String?,
      lastSyncAt: identical(lastSyncAt, _noChange)
          ? this.lastSyncAt
          : lastSyncAt as DateTime?,
      syncSuccessVisible: syncSuccessVisible ?? this.syncSuccessVisible,
      syncError: identical(syncError, _noChange)
          ? this.syncError
          : syncError as String?,
    );
  }
}

class NotificationSettingsNotifier extends Notifier<NotificationSettingsState> {
  static const int maxRelaySelection = 4;
  static const List<int> availableKinds = [1, 3, 6, 7, 9, 13, 14, 15, 1059];
  Timer? _successTimer;

  @override
  NotificationSettingsState build() {
    final supported = _isPlatformSupported();
    final initial = NotificationSettingsState(
      isLoading: supported,
      isEnablingNotifications: false,
      platformSupported: supported,
      notificationsEnabled: false,
      notificationsDenied: false,
      permissionRequested: false,
      selectedKinds: availableKinds,
      availableRelays: const [],
      selectedRelays: const [],
      relaySelectionError: null,
      lastSyncAt: null,
      syncSuccessVisible: false,
      syncError: null,
    );

    if (supported) {
      scheduleMicrotask(_loadState);
    }

    ref.onDispose(() {
      _successTimer?.cancel();
    });

    return initial;
  }

  static List<int> parseKinds(String? raw) {
    if (raw == null || raw.isEmpty) {
      return availableKinds;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        final parsed = decoded
            .map((e) => e is int ? e : int.tryParse(e.toString()))
            .whereType<int>()
            .where((k) => availableKinds.contains(k))
            .toList();
        return parsed.isEmpty ? availableKinds : parsed;
      }
    } catch (_) {}

    return availableKinds;
  }

  static List<String> parseSelectedRelays(String? raw) {
    if (raw == null || raw.isEmpty) {
      return const [];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        final unique = <String>{};
        final parsed = <String>[];

        for (final item in decoded) {
          final relay = item.toString().trim();
          if (relay.isEmpty || unique.contains(relay)) {
            continue;
          }
          unique.add(relay);
          parsed.add(relay);
          if (parsed.length >= maxRelaySelection) {
            break;
          }
        }

        return parsed;
      }
    } catch (_) {}

    return const [];
  }

  bool _isPlatformSupported() {
    return kIsWeb || Platform.isAndroid || Platform.isIOS || Platform.isMacOS;
  }

  Future<void> _loadState() async {
    try {
      final appDb = ref.read(dbAppProvider);
      final availableRelays = await _loadAvailableRelays();

      final settings = await FirebaseMessaging.instance
          .getNotificationSettings();
      final isEnabled =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
      final isDenied =
          settings.authorizationStatus == AuthorizationStatus.denied;

      final storedKinds = await appDb.read(_dbKindsKey);
      final storedRelays = await appDb.read(_dbRelaysKey);
      final storedPermissionRequested = await appDb.read(
        _dbPermissionRequestedKey,
      );
      final permissionRequested = storedPermissionRequested == 'true';
      final selectedKinds = parseKinds(storedKinds);
      final selectedRelays = _sanitizeSelectedRelays(
        parseSelectedRelays(storedRelays),
        availableRelays,
      );

      await _saveRelays(selectedRelays);

      if (isEnabled) {
        await _ensureTokenStored();
      }

      state = state.copyWith(
        notificationsEnabled: isEnabled,
        notificationsDenied: isDenied,
        permissionRequested: permissionRequested,
        selectedKinds: selectedKinds,
        availableRelays: availableRelays,
        selectedRelays: selectedRelays,
        relaySelectionError: null,
        syncError: null,
      );
    } catch (e) {
      state = state.copyWith(syncError: e.toString());
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> requestPermission() async {
    if (!state.platformSupported) return;

    if (state.selectedRelays.isEmpty) {
      state = state.copyWith(
        notificationsEnabled: false,
        relaySelectionError: 'Select at least one relay.',
      );
      return;
    }

    state = state.copyWith(
      isLoading: true,
      isEnablingNotifications: true,
      relaySelectionError: null,
      syncError: null,
    );

    try {
      final appDb = ref.read(dbAppProvider);
      await appDb.save(key: _dbPermissionRequestedKey, value: 'true');

      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      final isAuthorized =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
      final isDenied =
          settings.authorizationStatus == AuthorizationStatus.denied;

      if (isAuthorized) {
        final token = await _getAndStoreToken();
        if (token != null) {
          await _registerToken(
            token,
            state.selectedKinds,
            state.selectedRelays,
          );
        }
      }

      state = state.copyWith(
        notificationsEnabled: isAuthorized,
        notificationsDenied: isDenied,
        permissionRequested: true,
      );
    } catch (e) {
      state = state.copyWith(
        notificationsEnabled: false,
        notificationsDenied: false,
        permissionRequested: true,
        syncError: e.toString(),
      );
    } finally {
      state = state.copyWith(isLoading: false, isEnablingNotifications: false);
    }
  }

  Future<void> disableNotifications() async {
    if (!state.platformSupported) return;

    final appDb = ref.read(dbAppProvider);
    await FirebaseMessaging.instance.deleteToken();
    await appDb.delete(_dbTokenKey);

    state = state.copyWith(notificationsEnabled: false);
  }

  Future<void> setKindEnabled(int kind, bool enabled) async {
    final updated = List<int>.from(state.selectedKinds);
    if (enabled) {
      if (!updated.contains(kind)) {
        updated.add(kind);
      }
    } else {
      updated.remove(kind);
    }

    updated.sort();
    await _saveKinds(updated);

    state = state.copyWith(selectedKinds: updated);

    if (state.notificationsEnabled) {
      final token = await _getStoredToken();
      if (token != null) {
        await _registerToken(token, updated, state.selectedRelays);
      }
    }
  }

  Future<void> setRelayEnabled(String relay, bool enabled) async {
    final availableUrls = state.availableRelays.map((e) => e.url).toSet();
    if (!availableUrls.contains(relay)) {
      return;
    }

    final updated = List<String>.from(state.selectedRelays);

    if (enabled) {
      if (updated.contains(relay)) {
        return;
      }
      if (updated.length >= maxRelaySelection) {
        state = state.copyWith(
          relaySelectionError:
              'You can select up to $maxRelaySelection relays.',
        );
        return;
      }
      updated.add(relay);
    } else {
      updated.remove(relay);
    }

    await _saveRelays(updated);
    state = state.copyWith(selectedRelays: updated, relaySelectionError: null);

    if (state.notificationsEnabled) {
      final token = await _getStoredToken();
      if (token != null) {
        await _registerToken(token, state.selectedKinds, updated);
      }
    }
  }

  Future<String?> _getStoredToken() async {
    final appDb = ref.read(dbAppProvider);
    return appDb.read(_dbTokenKey);
  }

  Future<String?> _getAndStoreToken() async {
    /// needed for iOS to ensure the APNs token is generated and linked to FCM before getting the FCM token
    await FirebaseMessaging.instance.getAPNSToken();

    final token = await FirebaseMessaging.instance.getToken(
      vapidKey: kIsWeb ? String.fromEnvironment('FIREBASE_VAPID_KEY') : null,
    );
    if (token != null) {
      final appDb = ref.read(dbAppProvider);
      await appDb.save(key: _dbTokenKey, value: token);
    }
    return token;
  }

  Future<void> _ensureTokenStored() async {
    final existing = await _getStoredToken();
    if (existing == null || existing.isEmpty) {
      await _getAndStoreToken();
    }
  }

  Future<void> _saveKinds(List<int> kinds) async {
    final appDb = ref.read(dbAppProvider);
    await appDb.save(key: _dbKindsKey, value: jsonEncode(kinds));
  }

  Future<void> _saveRelays(List<String> relays) async {
    final appDb = ref.read(dbAppProvider);
    await appDb.save(key: _dbRelaysKey, value: jsonEncode(relays));
  }

  Future<List<NotificationRelayOption>> _loadAvailableRelays() async {
    final fallbackRelays = defaultAccountCreationRelays.entries.map((entry) {
      return NotificationRelayOption(
        url: entry.key,
        isDmRelay: false,
        isInboxRelay: entry.value.isRead,
        isOutboxRelay: entry.value.isWrite,
      );
    }).toList();

    final signer = ref.read(signerProvider);
    if (signer == null) {
      return _sortRelayOptions(fallbackRelays);
    }

    final mergedRelays = <NotificationRelayOption>[];

    try {
      final inboxOutbox = ref.read(inboxOutboxProvider);
      final nip65Data = await inboxOutbox.getNip65data(signer.getPublicKey());

      if (nip65Data != null) {
        mergedRelays.addAll(
          nip65Data.relays.entries.map((entry) {
            return NotificationRelayOption(
              url: entry.key,
              isDmRelay: false,
              isInboxRelay: entry.value.isRead,
              isOutboxRelay: entry.value.isWrite,
            );
          }),
        );
      }
    } catch (_) {}

    try {
      final dmRelayNotifier = ref.read(dmRelayListProvider.notifier);
      final dmRelays = await dmRelayNotifier.getRelays();
      mergedRelays.addAll(
        dmRelays.map(
          (relay) => NotificationRelayOption(
            url: relay,
            isDmRelay: true,
            isInboxRelay: false,
            isOutboxRelay: false,
          ),
        ),
      );
    } catch (_) {}

    mergedRelays.addAll(fallbackRelays);

    final result = _mergeRelayOptions(mergedRelays);
    if (result.isEmpty) {
      return _sortRelayOptions(fallbackRelays);
    }

    return _sortRelayOptions(result);
  }

  List<NotificationRelayOption> _mergeRelayOptions(
    List<NotificationRelayOption> relays,
  ) {
    final merged = <String, NotificationRelayOption>{};

    for (final relay in relays) {
      final normalized = relay.url.trim();
      if (normalized.isEmpty) {
        continue;
      }

      final current = NotificationRelayOption(
        url: normalized,
        isDmRelay: relay.isDmRelay,
        isInboxRelay: relay.isInboxRelay,
        isOutboxRelay: relay.isOutboxRelay,
      );

      final existing = merged[normalized];
      if (existing == null) {
        merged[normalized] = current;
      } else {
        merged[normalized] = existing.merge(current);
      }
    }

    return merged.values.toList();
  }

  List<NotificationRelayOption> _sortRelayOptions(
    List<NotificationRelayOption> relays,
  ) {
    final sorted = [...relays];
    sorted.sort((a, b) {
      final priorityCmp = a.priority.compareTo(b.priority);
      if (priorityCmp != 0) {
        return priorityCmp;
      }
      return a.url.compareTo(b.url);
    });
    return sorted;
  }

  List<String> _sanitizeSelectedRelays(
    List<String> selected,
    List<NotificationRelayOption> available,
  ) {
    final availableUrls = available.map((e) => e.url).toList();
    final availableSet = availableUrls.toSet();
    final unique = <String>{};
    final filtered = <String>[];

    for (final relay in selected) {
      if (!availableSet.contains(relay) || unique.contains(relay)) {
        continue;
      }
      unique.add(relay);
      filtered.add(relay);
      if (filtered.length >= maxRelaySelection) {
        break;
      }
    }

    if (filtered.isNotEmpty) {
      return filtered;
    }

    return availableUrls.take(maxRelaySelection).toList();
  }

  Future<void> _registerToken(
    String token,
    List<int> kinds,
    List<String> relays,
  ) async {
    try {
      final notiProvider = await ref.read(notificationsProvider.future);
      final ok = await notiProvider.registerDevice(
        token: token,
        kinds: kinds,
        relays: relays,
      );
      if (ok) {
        _markSyncSuccess();
      } else {
        _markSyncError('Registration failed');
      }
    } catch (e) {
      _markSyncError(e.toString());
    }
  }

  void _markSyncSuccess() {
    _successTimer?.cancel();
    state = state.copyWith(
      lastSyncAt: DateTime.now(),
      syncSuccessVisible: true,
      syncError: null,
    );
    _successTimer = Timer(const Duration(seconds: 2), () {
      state = state.copyWith(syncSuccessVisible: false);
    });
  }

  void _markSyncError(String message) {
    _successTimer?.cancel();
    state = state.copyWith(
      lastSyncAt: DateTime.now(),
      syncSuccessVisible: false,
      syncError: message,
    );
  }
}
