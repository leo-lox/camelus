import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'db_app_provider.dart';
import 'notifications_provider.dart';

const String _dbKindsKey = 'push_kinds';
const String _dbTokenKey = 'fcm_token';
const String _dbPermissionRequestedKey = 'push_permission_requested';

final notificationSettingsProvider =
    NotifierProvider<NotificationSettingsNotifier, NotificationSettingsState>(
      NotificationSettingsNotifier.new,
    );

class NotificationSettingsState {
  final bool isLoading;
  final bool platformSupported;
  final bool notificationsEnabled;
  final bool notificationsDenied;
  final bool permissionRequested;
  final List<int> selectedKinds;
  final DateTime? lastSyncAt;
  final bool syncSuccessVisible;
  final String? syncError;

  const NotificationSettingsState({
    required this.isLoading,
    required this.platformSupported,
    required this.notificationsEnabled,
    required this.notificationsDenied,
    required this.permissionRequested,
    required this.selectedKinds,
    required this.lastSyncAt,
    required this.syncSuccessVisible,
    required this.syncError,
  });

  NotificationSettingsState copyWith({
    bool? isLoading,
    bool? platformSupported,
    bool? notificationsEnabled,
    bool? notificationsDenied,
    bool? permissionRequested,
    List<int>? selectedKinds,
    DateTime? lastSyncAt,
    bool? syncSuccessVisible,
    String? syncError,
  }) {
    return NotificationSettingsState(
      isLoading: isLoading ?? this.isLoading,
      platformSupported: platformSupported ?? this.platformSupported,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      notificationsDenied: notificationsDenied ?? this.notificationsDenied,
      permissionRequested: permissionRequested ?? this.permissionRequested,
      selectedKinds: selectedKinds ?? this.selectedKinds,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      syncSuccessVisible: syncSuccessVisible ?? this.syncSuccessVisible,
      syncError: syncError,
    );
  }
}

class NotificationSettingsNotifier extends Notifier<NotificationSettingsState> {
  static const List<int> availableKinds = [1, 3, 6, 7, 9, 13, 14, 15, 1059];
  Timer? _successTimer;

  @override
  NotificationSettingsState build() {
    final supported = _isPlatformSupported();
    final initial = NotificationSettingsState(
      isLoading: supported,
      platformSupported: supported,
      notificationsEnabled: false,
      notificationsDenied: false,
      permissionRequested: false,
      selectedKinds: availableKinds,
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

  bool _isPlatformSupported() {
    return kIsWeb || Platform.isAndroid || Platform.isIOS || Platform.isMacOS;
  }

  Future<void> _loadState() async {
    try {
      final appDb = ref.read(dbAppProvider);

      final settings = await FirebaseMessaging.instance
          .getNotificationSettings();
      final isEnabled =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
      final isDenied =
          settings.authorizationStatus == AuthorizationStatus.denied;

      final storedKinds = await appDb.read(_dbKindsKey);
      final storedPermissionRequested = await appDb.read(
        _dbPermissionRequestedKey,
      );
      final permissionRequested = storedPermissionRequested == 'true';
      final selectedKinds = parseKinds(storedKinds);

      if (isEnabled) {
        await _ensureTokenStored();
      }

      state = state.copyWith(
        notificationsEnabled: isEnabled,
        notificationsDenied: isDenied,
        permissionRequested: permissionRequested,
        selectedKinds: selectedKinds,
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

    state = state.copyWith(isLoading: true);

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
          await _registerToken(token, state.selectedKinds);
        }
      }

      state = state.copyWith(
        notificationsEnabled: isAuthorized,
        notificationsDenied: isDenied,
        permissionRequested: true,
        syncError: null,
      );
    } catch (e) {
      state = state.copyWith(
        notificationsEnabled: false,
        notificationsDenied: false,
        permissionRequested: true,
        syncError: e.toString(),
      );
    } finally {
      state = state.copyWith(isLoading: false);
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
        await _registerToken(token, updated);
      }
    }
  }

  Future<String?> _getStoredToken() async {
    final appDb = ref.read(dbAppProvider);
    return appDb.read(_dbTokenKey);
  }

  Future<String?> _getAndStoreToken() async {
    final token = await FirebaseMessaging.instance.getToken();
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

  Future<void> _registerToken(String token, List<int> kinds) async {
    try {
      final notiProvider = await ref.read(notificationsProvider.future);
      final ok = await notiProvider.registerDevice(token: token, kinds: kinds);
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
