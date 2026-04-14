import 'dart:developer';

import 'package:camelus/domain_layer/entities/nip_65.dart';
import 'package:camelus/domain_layer/usecases/inbox_outbox.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ndk/entities.dart' hide Nip65;

import '../inbox_outbox_provider.dart';
import '../ndk_provider.dart';

enum AddNip65RelayResult { success, invalidUrl, alreadyExists, saveFailed }

class Nip65RelaySettingsState {
  final Map<String, ReadWriteMarker> originalRelays;
  final Map<String, ReadWriteMarker> relays;
  final int? createdAt;
  final bool isLoading;
  final bool isSaving;
  final String? error;

  const Nip65RelaySettingsState({
    this.originalRelays = const {},
    this.relays = const {},
    this.createdAt,
    this.isLoading = false,
    this.isSaving = false,
    this.error,
  });

  bool get hasChanges {
    if (relays.length != originalRelays.length) {
      return true;
    }

    for (final entry in relays.entries) {
      final original = originalRelays[entry.key];
      if (original == null ||
          original.isRead != entry.value.isRead ||
          original.isWrite != entry.value.isWrite) {
        return true;
      }
    }

    return false;
  }

  Nip65RelaySettingsState copyWith({
    Map<String, ReadWriteMarker>? originalRelays,
    Map<String, ReadWriteMarker>? relays,
    Object? createdAt = _keepValue,
    bool? isLoading,
    bool? isSaving,
    Object? error = _keepValue,
  }) {
    return Nip65RelaySettingsState(
      originalRelays: originalRelays ?? this.originalRelays,
      relays: relays ?? this.relays,
      createdAt: createdAt == _keepValue ? this.createdAt : createdAt as int?,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: error == _keepValue ? this.error : error as String?,
    );
  }
}

const _keepValue = Object();

enum _RelayRole { inbox, outbox }

class Nip65RelaySettingsNotifier extends Notifier<Nip65RelaySettingsState> {
  late final String? myPubkey;
  bool _didScheduleInitialLoad = false;

  @override
  Nip65RelaySettingsState build() {
    final inboxOutbox = ref.watch(inboxOutboxProvider);
    final pubkey = ref.watch(ndkProvider).accounts.getPublicKey();

    _inboxOutbox = inboxOutbox;
    myPubkey = pubkey;

    if (myPubkey != null && !_didScheduleInitialLoad) {
      _didScheduleInitialLoad = true;
      Future<void>(() async {
        await _loadFromCacheThenFetch();
      });
    }

    return const Nip65RelaySettingsState();
  }

  late final InboxOutbox _inboxOutbox;

  Future<void> _loadFromCacheThenFetch() async {
    await fetchRelays(forceRefresh: false);
    await fetchRelays(forceRefresh: true);
  }

  Future<void> fetchRelays({bool forceRefresh = true}) async {
    if (myPubkey == null) {
      return;
    }

    if (state.relays.isEmpty) {
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      final nip65 = await _inboxOutbox.getNip65data(
        myPubkey!,
        forceRefresh: forceRefresh,
      );

      if (nip65 == null) {
        state = state.copyWith(
          originalRelays: {},
          relays: {},
          createdAt: null,
          isLoading: false,
          error: null,
        );
        return;
      }

      final fetchedRelays = Map<String, ReadWriteMarker>.from(nip65.relays);
      state = state.copyWith(
        originalRelays: fetchedRelays,
        relays: fetchedRelays,
        createdAt: nip65.createdAt,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      log('NIP-65: Error fetching relays: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<AddNip65RelayResult> addInboxRelay(String relayUrl) {
    return _addRelay(relayUrl, role: _RelayRole.inbox);
  }

  Future<AddNip65RelayResult> addOutboxRelay(String relayUrl) {
    return _addRelay(relayUrl, role: _RelayRole.outbox);
  }

  AddNip65RelayResult addRelay(String relayUrl) {
    final normalized = _normalizeRelayUrl(relayUrl);
    if (normalized == null) {
      return AddNip65RelayResult.invalidUrl;
    }

    if (state.relays.containsKey(normalized)) {
      return AddNip65RelayResult.alreadyExists;
    }

    state = state.copyWith(
      relays: Map<String, ReadWriteMarker>.from(state.relays)
        ..[normalized] = ReadWriteMarker.readWrite,
    );

    return AddNip65RelayResult.success;
  }

  void setRelayPermissions(
    String relayUrl, {
    required bool isRead,
    required bool isWrite,
  }) {
    final existing = state.relays[relayUrl];
    if (existing == null) {
      return;
    }

    final updatedRelays = Map<String, ReadWriteMarker>.from(state.relays);
    if (!isRead && !isWrite) {
      updatedRelays.remove(relayUrl);
    } else {
      updatedRelays[relayUrl] = _markerFrom(isRead: isRead, isWrite: isWrite);
    }

    state = state.copyWith(relays: updatedRelays);
  }

  void removeRelay(String relayUrl) {
    if (!state.relays.containsKey(relayUrl)) {
      return;
    }

    state = state.copyWith(
      relays: Map<String, ReadWriteMarker>.from(state.relays)..remove(relayUrl),
    );
  }

  void discardChanges() {
    state = state.copyWith(
      relays: Map<String, ReadWriteMarker>.from(state.originalRelays),
      error: null,
    );
  }

  Future<bool> saveChanges() {
    if (!state.hasChanges) {
      return Future.value(true);
    }

    return _saveRelays(state.relays);
  }

  Future<AddNip65RelayResult> _addRelay(
    String relayUrl, {
    required _RelayRole role,
  }) async {
    if (myPubkey == null) {
      return AddNip65RelayResult.invalidUrl;
    }

    final normalized = _normalizeRelayUrl(relayUrl);
    if (normalized == null) {
      return AddNip65RelayResult.invalidUrl;
    }

    final currentMarker = state.relays[normalized];
    final hasRole = role == _RelayRole.inbox
        ? (currentMarker?.isRead ?? false)
        : (currentMarker?.isWrite ?? false);

    if (hasRole) {
      return AddNip65RelayResult.alreadyExists;
    }

    final isRead = role == _RelayRole.inbox || (currentMarker?.isRead ?? false);
    final isWrite =
        role == _RelayRole.outbox || (currentMarker?.isWrite ?? false);

    final updatedRelays = Map<String, ReadWriteMarker>.from(state.relays)
      ..[normalized] = _markerFrom(isRead: isRead, isWrite: isWrite);

    final saved = await _saveRelays(updatedRelays);
    return saved ? AddNip65RelayResult.success : AddNip65RelayResult.saveFailed;
  }

  Future<bool> removeInboxRelay(String relayUrl) {
    return _removeRelay(relayUrl, role: _RelayRole.inbox);
  }

  Future<bool> removeOutboxRelay(String relayUrl) {
    return _removeRelay(relayUrl, role: _RelayRole.outbox);
  }

  Future<bool> _removeRelay(String relayUrl, {required _RelayRole role}) async {
    final currentMarker = state.relays[relayUrl];
    if (currentMarker == null) {
      return true;
    }

    final hasRole = role == _RelayRole.inbox
        ? currentMarker.isRead
        : currentMarker.isWrite;

    if (!hasRole) {
      return true;
    }

    final nextRead = role == _RelayRole.inbox ? false : currentMarker.isRead;
    final nextWrite = role == _RelayRole.outbox ? false : currentMarker.isWrite;

    final updatedRelays = Map<String, ReadWriteMarker>.from(state.relays);
    if (!nextRead && !nextWrite) {
      updatedRelays.remove(relayUrl);
    } else {
      updatedRelays[relayUrl] = _markerFrom(
        isRead: nextRead,
        isWrite: nextWrite,
      );
    }

    return _saveRelays(updatedRelays);
  }

  Future<bool> _saveRelays(Map<String, ReadWriteMarker> relays) async {
    if (myPubkey == null) {
      return false;
    }

    state = state.copyWith(isSaving: true, error: null);

    try {
      final createdAt = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      await _inboxOutbox.setNip65data(
        Nip65(pubKey: myPubkey!, relays: relays, createdAt: createdAt),
      );

      final refreshed = await _inboxOutbox.getNip65data(
        myPubkey!,
        forceRefresh: true,
      );

      if (refreshed != null) {
        final refreshedRelays = Map<String, ReadWriteMarker>.from(
          refreshed.relays,
        );
        state = state.copyWith(
          originalRelays: refreshedRelays,
          relays: refreshedRelays,
          createdAt: refreshed.createdAt,
          isSaving: false,
          error: null,
        );
      } else {
        final savedRelays = Map<String, ReadWriteMarker>.from(relays);
        state = state.copyWith(
          originalRelays: savedRelays,
          relays: savedRelays,
          createdAt: createdAt,
          isSaving: false,
          error: null,
        );
      }

      return true;
    } catch (e) {
      log('NIP-65: Error saving relays: $e');
      state = state.copyWith(isSaving: false, error: e.toString());
      return false;
    }
  }

  String? _normalizeRelayUrl(String relayUrl) {
    String url = relayUrl.trim();
    if (url.isEmpty) {
      return null;
    }

    if (!url.startsWith('wss://') && !url.startsWith('ws://')) {
      url = 'wss://$url';
    }

    final uri = Uri.tryParse(url);
    if (uri == null ||
        !uri.hasAuthority ||
        uri.host.isEmpty ||
        url.contains(' ')) {
      return null;
    }

    return url;
  }

  ReadWriteMarker _markerFrom({required bool isRead, required bool isWrite}) {
    if (isRead && isWrite) {
      return ReadWriteMarker.readWrite;
    }

    if (isRead) {
      return ReadWriteMarker.readOnly;
    }

    if (isWrite) {
      return ReadWriteMarker.values.firstWhere(
        (marker) => marker.isWrite && !marker.isRead,
        orElse: () => ReadWriteMarker.readWrite,
      );
    }

    return ReadWriteMarker.readWrite;
  }
}

final nip65RelaySettingsProvider =
    NotifierProvider<Nip65RelaySettingsNotifier, Nip65RelaySettingsState>(
      Nip65RelaySettingsNotifier.new,
    );
