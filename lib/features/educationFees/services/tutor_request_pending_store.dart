import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../constants/storage_keys.dart';
import '../../../services/logger_service.dart';
import '../../../services/secure_storage_service.dart';

/// Persists PENDING tutor-request popup candidates across background isolates
/// and process restarts. Stores only non-sensitive display fields.
class TutorRequestPendingStore {
  TutorRequestPendingStore._();

  static const _storage = SecureStorageService.instance;

  /// In-memory override used by widget/unit tests (no platform plugins).
  static Map<String, String>? _debugMemory;

  @visibleForTesting
  static void debugUseMemoryStore([Map<String, String>? memory]) {
    _debugMemory = memory ?? <String, String>{};
  }

  @visibleForTesting
  static void debugResetStore() {
    _debugMemory = null;
  }

  static Future<String?> _read() async {
    final memory = _debugMemory;
    if (memory != null) {
      return memory[StorageKeys.pendingTutorRequestPopups];
    }
    return _storage.read(key: StorageKeys.pendingTutorRequestPopups);
  }

  static Future<void> _write(String? value) async {
    final memory = _debugMemory;
    if (memory != null) {
      if (value == null || value.isEmpty) {
        memory.remove(StorageKeys.pendingTutorRequestPopups);
      } else {
        memory[StorageKeys.pendingTutorRequestPopups] = value;
      }
      return;
    }
    if (value == null || value.isEmpty) {
      await _storage.delete(key: StorageKeys.pendingTutorRequestPopups);
      return;
    }
    await _storage.write(
      key: StorageKeys.pendingTutorRequestPopups,
      value: value,
    );
  }

  /// Load all persisted entries (verified and unverified).
  static Future<List<TutorRequestPendingEntry>> loadAll() async {
    try {
      final raw = await _read();
      if (raw == null || raw.trim().isEmpty) return const [];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((item) => TutorRequestPendingEntry.fromJson(
                Map<String, dynamic>.from(item),
              ))
          .where((entry) => entry.requestReference.isNotEmpty)
          .toList(growable: false);
    } catch (e) {
      logger.error('Failed to load pending tutor request store: $e', error: e);
      return const [];
    }
  }

  /// Upsert one entry keyed by [requestReference].
  static Future<void> upsert(TutorRequestPendingEntry entry) async {
    if (entry.requestReference.isEmpty) return;
    final existing = await loadAll();
    final next = <TutorRequestPendingEntry>[
      for (final item in existing)
        if (item.requestReference != entry.requestReference) item,
      entry,
    ];
    await _writeAll(next);
  }

  /// Returns and removes a verified entry for [requestReference], if any.
  static Future<TutorRequestPendingEntry?> takeVerified(
    String requestReference,
  ) async {
    if (requestReference.isEmpty) return null;
    final existing = await loadAll();
    TutorRequestPendingEntry? match;
    final remaining = <TutorRequestPendingEntry>[];
    for (final item in existing) {
      if (item.requestReference == requestReference &&
          item.verified &&
          match == null) {
        match = item;
      } else {
        remaining.add(item);
      }
    }
    if (match != null) {
      await _writeAll(remaining);
    }
    return match;
  }

  static Future<void> remove(String requestReference) async {
    if (requestReference.isEmpty) return;
    final existing = await loadAll();
    final remaining = existing
        .where((item) => item.requestReference != requestReference)
        .toList(growable: false);
    if (remaining.length == existing.length) return;
    await _writeAll(remaining);
  }

  static Future<void> clear() async {
    try {
      await _write(null);
    } catch (e) {
      logger.error('Failed to clear pending tutor request store: $e', error: e);
    }
  }

  static Future<void> _writeAll(List<TutorRequestPendingEntry> entries) async {
    try {
      if (entries.isEmpty) {
        await _write(null);
        return;
      }
      await _write(
        jsonEncode(
          entries.map((entry) => entry.toJson()).toList(growable: false),
        ),
      );
    } catch (e) {
      logger.error('Failed to write pending tutor request store: $e', error: e);
    }
  }
}

class TutorRequestPendingEntry {
  const TutorRequestPendingEntry({
    required this.requestReference,
    required this.verified,
    this.amount = '0',
    this.subject = '',
  });

  final String requestReference;
  final bool verified;
  final String amount;
  final String subject;

  factory TutorRequestPendingEntry.fromJson(Map<String, dynamic> json) {
    return TutorRequestPendingEntry(
      requestReference: (json['request_reference'] ?? json['requestReference'])
              ?.toString()
              .trim() ??
          '',
      verified: json['verified'] == true ||
          json['verified'] == 1 ||
          json['verified']?.toString().toLowerCase() == 'true',
      amount: json['amount']?.toString() ?? '0',
      subject: json['subject']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'request_reference': requestReference,
        'verified': verified,
        'amount': amount,
        'subject': subject,
      };
}
