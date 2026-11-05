import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../../services/logger_service.dart';
import '../../../services/secure_storage_service.dart';
import '../../../utils/utils.dart';
import '../constants/tutor_notification_constants.dart';
import '../repositories/education_fees_repository.dart';
import 'tutor_request_pending_store.dart';

/// Tutor (receiver) side popup source.
///
/// - Foreground FCM / notification tap -> popup (tap is validated against the
///   received PENDING list so an already answered request never reopens).
/// - Startup / resume -> only requests NOT shown before (persisted "seen" set).
///   The first run stores a baseline so old requests never pop up.
/// - `request-status` is sender-only on the backend, so it is never used here.
class TutorRequestNotificationService {
  TutorRequestNotificationService._() {
    _eventController = StreamController<TutorRequestEvent>.broadcast(
      sync: true,
      onListen: _replayQueuedEvents,
    );
  }

  static final TutorRequestNotificationService _instance =
  TutorRequestNotificationService._();
  factory TutorRequestNotificationService() => _instance;

  static const _storage = SecureStorageService.instance;
  static const String _seenKey = 'tutor_seen_request_refs';
  static const String _baselineKey = 'tutor_seen_baseline_done';
  static const int _seenLimit = 300;

  EducationFeesRepository _repository = EducationFeesRepository();
  Future<bool> Function() _authChecker = Utils.checkAuthentication;
  Future<String?> Function() _currentUserId = Utils.getUserId;

  final Set<String> _inFlight = {};
  final Set<String> _awaitingPopup = {};
  final Set<String> _presentedReferences = {};
  final Set<String> _handledReferences = {};
  final Set<String> _needsPresentationRetry = {};

  final StreamController<void> _presentationAttention =
  StreamController<void>.broadcast();
  final List<_DeferredTutorRequest> _authDeferred = [];
  late final StreamController<TutorRequestEvent> _eventController;
  final List<TutorRequestEvent> _eventQueue = [];

  bool _hasRunStartupCheck = false;
  bool _isShowingPopup = false;
  bool _checkRunning = false;

  Set<String>? _seenCache;

  // ---------------------------------------------------------------------------
  // Wiring / test hooks
  // ---------------------------------------------------------------------------

  void bindRepository(EducationFeesRepository repository) {
    _repository = repository;
  }

  @visibleForTesting
  void debugSetRepository(EducationFeesRepository repository) {
    bindRepository(repository);
  }

  @visibleForTesting
  void debugSetAuthChecker(Future<bool> Function() checker) {
    _authChecker = checker;
  }

  @visibleForTesting
  void debugSetCurrentUserId(Future<String?> Function() reader) {
    _currentUserId = reader;
  }

  @visibleForTesting
  void debugReset({
    EducationFeesRepository? repository,
    Future<bool> Function()? authChecker,
    Future<String?> Function()? currentUserId,
  }) {
    clearShownRequests();
    _seenCache = <String>{};
    if (repository != null) _repository = repository;
    if (authChecker != null) _authChecker = authChecker;
    _currentUserId = currentUserId ?? (() async => null);
  }

  Set<String> get shownRequestReferences => Set.unmodifiable({
    ..._awaitingPopup,
    ..._presentedReferences,
    ..._handledReferences,
  });

  Stream<TutorRequestEvent> get requestEvents => _eventController.stream;
  Stream<void> get presentationAttention => _presentationAttention.stream;
  bool get hasAuthDeferred => _authDeferred.isNotEmpty;
  bool get isShowingPopup => _isShowingPopup;

  void initialize() {}

  // ---------------------------------------------------------------------------
  // Persisted "seen" set (a request popup is shown only once)
  // ---------------------------------------------------------------------------

  Future<Set<String>> _loadSeen() async {
    final cached = _seenCache;
    if (cached != null) return cached;
    final set = <String>{};
    try {
      final raw = await _storage.read(key: _seenKey);
      if (raw != null && raw.trim().isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          for (final e in decoded) {
            final s = '$e'.trim();
            if (s.isNotEmpty) set.add(s);
          }
        }
      }
    } catch (e) {
      logger.error('SEEN_LOAD_ERROR: $e', error: e);
    }
    _seenCache = set;
    return set;
  }

  Future<void> _markSeen(Iterable<String> refs) async {
    final seen = await _loadSeen();
    var changed = false;
    for (final r in refs) {
      if (r.isNotEmpty && seen.add(r)) changed = true;
    }
    if (!changed) return;
    while (seen.length > _seenLimit) {
      seen.remove(seen.first);
    }
    try {
      await _storage.write(key: _seenKey, value: jsonEncode(seen.toList()));
    } catch (e) {
      logger.error('SEEN_WRITE_ERROR: $e', error: e);
    }
  }

  Future<bool> _baselineDone() async {
    try {
      return (await _storage.read(key: _baselineKey)) == '1';
    } catch (_) {
      return false;
    }
  }

  Future<void> _setBaselineDone() async {
    try {
      await _storage.write(key: _baselineKey, value: '1');
    } catch (_) {}
  }

  // ---------------------------------------------------------------------------
  // Startup / resume: only NEW (never shown) pending requests
  // ---------------------------------------------------------------------------

  Future<void> checkPendingRequestsOnStartup() =>
      checkNewRequests(isStartup: true);

  Future<void> checkPendingRequestsOnResume() =>
      checkNewRequests(isStartup: false);

  Future<void> checkNewRequests({required bool isStartup}) async {
    if (_checkRunning) return;
    if (isStartup && _hasRunStartupCheck) return;
    _checkRunning = true;
    try {
      final isAuthenticated = await _authChecker();
      if (!isAuthenticated) {
        logger.info('NEW_REQUEST_CHECK_SKIPPED: not authenticated');
        return;
      }

      await flushAuthDeferredRequests();

      final response = await _repository.fetchTutorReceivedRequests(
        page: TutorNotificationConstants.defaultPage,
        perPage: TutorNotificationConstants.defaultPerPage,
        status: TutorNotificationConstants.statusPending,
      );
      if (!response.status || response.data == null) {
        logger.warning('NEW_REQUEST_CHECK_FAILED: list fetch failed');
        return;
      }
      if (isStartup) _hasRunStartupCheck = true;

      final items = <Map<String, dynamic>>[];
      for (final raw in response.data!.requests) {
        final map = _asStringMap(raw);
        if (map != null && _refFromMap(map) != null) items.add(map);
      }
      logger.info('NEW_REQUEST_CHECK: pending=${items.length}');

      // First run on this install: everything pending is "old". Remember it,
      // show nothing.
      if (!await _baselineDone()) {
        await _markSeen(items.map((m) => _refFromMap(m)!));
        await _setBaselineDone();
        logger.info('NEW_REQUEST_BASELINE_SAVED: ${items.length}');
        return;
      }

      final seen = await _loadSeen();
      for (final map in items) {
        final ref = _refFromMap(map)!;
        if (seen.contains(ref)) continue;
        final messageId =
            '${isStartup ? "startup" : "resume"}_${DateTime.now().millisecondsSinceEpoch}';
        await _processRequestReference(
          ref,
          messageId: messageId,
          fallback: _eventFromMap(ref, messageId, map, false),
          trustFallback: true,
        );
      }
    } catch (e) {
      logger.error('NEW_REQUEST_CHECK_ERROR: $e', error: e);
    } finally {
      _checkRunning = false;
    }
  }

  Future<void> flushAuthDeferredRequests() async {
    if (_authDeferred.isEmpty) return;
    final pending = List<_DeferredTutorRequest>.from(_authDeferred);
    _authDeferred.clear();
    for (final d in pending) {
      await _processRequestReference(
        d.requestReference,
        messageId: d.messageId,
        force: d.force,
        fallback: d.fallback,
        fromTap: d.fromTap,
      );
    }
  }

  /// Kept for compatibility. Background-persisted entries are no longer used
  /// to open popups (they caused old requests to reappear).
  Future<void> flushPersistedPendingRequests() async {}

  Future<void> ingestVerifiedPending({
    required String requestReference,
    required String amount,
    required String subject,
    String requesterName = '',
    String requesterUserId = '',
    String requestStatus = '',
    String messageId = 'background_verified',
  }) async {
    if (requestReference.isEmpty) return;
    if (_handledReferences.contains(requestReference) ||
        _presentedReferences.contains(requestReference) ||
        _awaitingPopup.contains(requestReference)) {
      await TutorRequestPendingStore.remove(requestReference);
      return;
    }
    if (await _isCurrentUserTheRequester(requesterUserId)) {
      _handledReferences.add(requestReference);
      await TutorRequestPendingStore.remove(requestReference);
      return;
    }
    _queuePopup(
      TutorRequestEvent(
        requestReference: requestReference,
        messageId: messageId,
        amount: amount,
        subject: subject,
        requesterName: requesterName,
        requestStatus: requestStatus,
      ),
    );
    await TutorRequestPendingStore.remove(requestReference);
  }

  // ---------------------------------------------------------------------------
  // FCM entry points
  // ---------------------------------------------------------------------------

  /// Foreground FCM: a brand new request, always show.
  Future<void> handleForegroundMessage(RemoteMessage message) async {
    logger.info('FCM_RECEIVED: ${message.messageId}');
    await handleIncomingFromData(
      message.data,
      messageId: message.messageId ?? '',
      fromTap: false,
    );
  }

  Future<void> handleOpenedMessage(RemoteMessage message) {
    return handleOpenedData(
      message.data,
      messageId: message.messageId ?? 'opened',
    );
  }

  /// Notification TAP.
  Future<void> handleOpenedData(
      Map<String, dynamic> raw, {
        String messageId = 'notification_tap',
      }) {
    logger.info('TUTOR_NOTIFICATION_TAP_RECEIVED: $messageId');
    final data = notificationDataFromPayload(raw);
    logger.info(
      'TUTOR_NOTIFICATION_PAYLOAD_EXTRACTED: keys=${data.keys.join(',')}',
    );
    return handleIncomingFromData(data, messageId: messageId, fromTap: true);
  }

  static Map<String, dynamic> notificationDataFromPayload(Object? decoded) {
    if (decoded is! Map) return const {};
    final root = decoded.map((key, value) => MapEntry('$key', value));
    final nested = root['data'];
    final data = <String, dynamic>{};
    if (nested is Map) {
      nested.forEach((key, value) {
        data['$key'] = value;
      });
    } else if (nested is String && nested.trim().isNotEmpty) {
      try {
        final parsed = jsonDecode(nested);
        if (parsed is Map) {
          parsed.forEach((key, value) {
            data['$key'] = value;
          });
        }
      } catch (_) {}
    }
    root.forEach((key, value) {
      if (key == 'data' || key == 'title' || key == 'body') return;
      data.putIfAbsent(key, () => value);
    });
    return data;
  }

  Future<void> handleIncomingFromData(
      Map<String, dynamic> data, {
        String messageId = '',
        bool force = true,
        bool fromTap = false,
      }) async {
    if (!isTutorRequestPayload(data)) {
      logger.info('FCM payload is not a tutor request, skipping');
      return;
    }
    final requestReference = extractRequestReference(data);
    if (requestReference == null || requestReference.isEmpty) {
      logger.warning('No request reference in notification data');
      return;
    }
    logger.info('TUTOR_REQUEST_REFERENCE_EXTRACTED: $requestReference');
    await _processRequestReference(
      requestReference,
      messageId: messageId,
      force: force,
      fromTap: fromTap,
      fallback: _eventFromMap(requestReference, messageId, data, force),
    );
  }

  // ---------------------------------------------------------------------------
  // Map helpers
  // ---------------------------------------------------------------------------

  static Map<String, dynamic>? _asStringMap(Object? value) {
    if (value is! Map) return null;
    return value.map((key, v) => MapEntry('$key', v));
  }

  static String? _refFromMap(Map<String, dynamic> m) {
    final v = m['request_reference'] ??
        m['requestReference'] ??
        m['tutor_request_reference'];
    final s = v?.toString().trim() ?? '';
    return s.isEmpty ? null : s;
  }

  static String _firstNonEmpty(Map<String, dynamic> d, List<String> keys) {
    for (final k in keys) {
      final v = d[k]?.toString().trim() ?? '';
      if (v.isNotEmpty && v.toLowerCase() != 'null') return v;
    }
    return '';
  }

  static String _requesterNameFrom(Map<String, dynamic> d) {
    final direct = _firstNonEmpty(d, [
      'requester_name',
      'requesterName',
      'sender_name',
      'student_name',
      'parent_name',
      'name',
    ]);
    if (direct.isNotEmpty) return direct;
    for (final key in ['requester', 'sender', 'user']) {
      final nested = _asStringMap(d[key]);
      if (nested != null) {
        final n = _firstNonEmpty(nested, ['name', 'full_name']);
        if (n.isNotEmpty) return n;
      }
    }
    return '';
  }

  TutorRequestEvent _eventFromMap(
      String requestReference,
      String messageId,
      Map<String, dynamic> d,
      bool force,
      ) {
    return TutorRequestEvent(
      requestReference: requestReference,
      messageId: messageId,
      amount: _firstNonEmpty(d, ['amount', 'fee_amount', 'tuition_amount']),
      subject: _firstNonEmpty(d, ['subject', 'fee_type', 'purpose']),
      requesterName: _requesterNameFrom(d),
      requestStatus: _firstNonEmpty(d, ['request_status', 'status']),
      forced: force,
    );
  }

  static TutorRequestEvent _merge(
      String requestReference,
      String messageId,
      TutorRequestEvent? primary,
      TutorRequestEvent? secondary, {
        required bool forced,
      }) {
    String pick(String Function(TutorRequestEvent e) f) {
      final a = primary == null ? '' : f(primary);
      if (a.trim().isNotEmpty) return a;
      return secondary == null ? '' : f(secondary);
    }

    return TutorRequestEvent(
      requestReference: requestReference,
      messageId: messageId,
      amount: pick((e) => e.amount),
      subject: pick((e) => e.subject),
      requesterName: pick((e) => e.requesterName),
      requestStatus: pick((e) => e.requestStatus),
      forced: forced,
    );
  }

  /// Looks the request up in the tutor's received PENDING list.
  /// `ok == false` means the list could not be fetched (unknown).
  Future<_ListLookup> _lookupInReceivedList(
      String requestReference,
      String messageId,
      ) async {
    try {
      final res = await _repository.fetchTutorReceivedRequests(
        page: 1,
        perPage: 50,
        status: TutorNotificationConstants.statusPending,
      );
      if (!res.status || res.data == null) {
        return const _ListLookup(ok: false);
      }
      for (final item in res.data!.requests) {
        final map = _asStringMap(item);
        if (map == null) continue;
        if (_refFromMap(map) == requestReference) {
          logger.info('RECEIVED_LIST_LOOKUP_HIT: $requestReference');
          return _ListLookup(
            ok: true,
            event: _eventFromMap(requestReference, messageId, map, true),
          );
        }
      }
      logger.info('RECEIVED_LIST_LOOKUP_MISS: $requestReference');
      return const _ListLookup(ok: true);
    } catch (e) {
      logger.error('RECEIVED_LIST_LOOKUP_ERROR: $e', error: e);
      return const _ListLookup(ok: false);
    }
  }

  // ---------------------------------------------------------------------------
  // Core
  // ---------------------------------------------------------------------------

  Future<void> _processRequestReference(
      String requestReference, {
        required String messageId,
        bool force = false,
        bool fromTap = false,
        TutorRequestEvent? fallback,
        bool trustFallback = false,
      }) async {
    if (requestReference.isEmpty) return;

    if (force) {
      if (_presentedReferences.contains(requestReference) &&
          _isShowingPopup) {
        logger.info('FORCE_SKIP_POPUP_ALREADY_VISIBLE: $requestReference');
        return;
      }
      _handledReferences.remove(requestReference);
      _awaitingPopup.remove(requestReference);
      _needsPresentationRetry.remove(requestReference);
      _presentedReferences.remove(requestReference);
      _eventQueue.removeWhere((e) => e.requestReference == requestReference);
    } else {
      if (_handledReferences.contains(requestReference)) return;
      if (_presentedReferences.contains(requestReference) ||
          _awaitingPopup.contains(requestReference)) {
        return;
      }
      if (_inFlight.contains(requestReference)) return;
    }

    _inFlight.add(requestReference);
    try {
      final isAuthenticated = await _authChecker();
      if (!isAuthenticated) {
        _authDeferred.removeWhere(
              (item) => item.requestReference == requestReference,
        );
        _authDeferred.add(
          _DeferredTutorRequest(
            requestReference: requestReference,
            messageId: messageId,
            force: force,
            fromTap: fromTap,
            fallback: fallback,
          ),
        );
        logger.info('AUTH_NOT_READY queued: $requestReference');
        if (!_presentationAttention.isClosed) {
          _presentationAttention.add(null);
        }
        return;
      }

      // Item already came from the received PENDING list.
      if (trustFallback && fallback != null) {
        logger.info('POPUP_FROM_RECEIVED_LIST: $requestReference');
        _queuePopup(fallback);
        return;
      }

      final lookup = await _lookupInReceivedList(requestReference, messageId);

      if (lookup.event != null) {
        _queuePopup(
          _merge(
            requestReference,
            messageId,
            lookup.event,
            fallback,
            forced: force,
          ),
        );
        return;
      }

      // List says: not pending any more -> already answered.
      if (lookup.ok && fromTap) {
        logger.info('TAP_REQUEST_NOT_PENDING_SKIP: $requestReference');
        _handledReferences.add(requestReference);
        await _markSeen([requestReference]);
        return;
      }

      // Foreground FCM, or list unavailable: show from the FCM payload.
      if (force && fallback != null) {
        logger.info('FORCE_FALLBACK_POPUP: $requestReference');
        _queuePopup(fallback);
        return;
      }
      logger.info('NO_POPUP_FOR_REQUEST: $requestReference');
    } catch (e) {
      logger.error('PROCESS_REQUEST_ERROR: $e', error: e);
      if (force && fallback != null) _queuePopup(fallback);
    } finally {
      _inFlight.remove(requestReference);
    }
  }

  void _queuePopup(TutorRequestEvent event) {
    final ref = event.requestReference;
    if (_presentedReferences.contains(ref) || _awaitingPopup.contains(ref)) {
      logger.info('QUEUE_POPUP_SKIP_DUPLICATE: $ref');
      return;
    }
    _awaitingPopup.add(ref);
    unawaited(_markSeen([ref]));
    _broadcast(event);
  }

  // ---------------------------------------------------------------------------
  // Request payload detection
  // ---------------------------------------------------------------------------

  static bool isTutorRequestPayload(Map<String, dynamic> data) {
    final requestReference = extractRequestReference(data);
    if (requestReference == null || requestReference.isEmpty) return false;

    final type = (data['type'] ?? data['notification_type'])
        ?.toString()
        .trim()
        .toLowerCase();
    if (type == null || type.isEmpty) return true;
    if (type.contains(TutorNotificationConstants.typeTutor) ||
        type.contains(TutorNotificationConstants.typeTuition) ||
        type.contains(TutorNotificationConstants.typeEducation) ||
        type.contains(TutorNotificationConstants.typeRequest)) {
      return true;
    }

    final hasTutorRefKey = data.containsKey('request_reference') ||
        data.containsKey('requestReference') ||
        data.containsKey('tutor_request_reference');
    if (!hasTutorRefKey) return false;

    return !TutorNotificationConstants.excludedTypes.any(type.contains);
  }

  static String? extractRequestReference(Map<String, dynamic> data) {
    final requestRef = data['request_reference'] ??
        data['requestReference'] ??
        data['tutor_request_reference'];
    if (requestRef != null && requestRef.toString().trim().isNotEmpty) {
      return requestRef.toString().trim();
    }

    for (final entry in data.entries) {
      final k = entry.key.toLowerCase();
      if (k.contains('request') && (k.contains('ref') || k.endsWith('id'))) {
        final v = entry.value?.toString().trim() ?? '';
        if (v.isNotEmpty) return v;
      }
    }

    final type = (data['type'] ?? data['notification_type'])
        ?.toString()
        .trim()
        .toLowerCase();
    final isTutorType = type != null &&
        (type.contains(TutorNotificationConstants.typeTutor) ||
            type.contains(TutorNotificationConstants.typeTuition) ||
            type.contains(TutorNotificationConstants.typeEducation));
    if (isTutorType) {
      final fallback = data['reference']?.toString().trim();
      if (fallback != null && fallback.isNotEmpty) return fallback;
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Event bus / state
  // ---------------------------------------------------------------------------

  void _broadcast(TutorRequestEvent event) {
    _eventQueue.removeWhere(
          (queued) => queued.requestReference == event.requestReference,
    );
    _eventQueue.add(event);
    if (_eventController.hasListener) {
      _eventController.add(event);
    }
    logger.info('POPUP_EVENT_BROADCAST: ${event.requestReference}');
  }

  void _replayQueuedEvents() {
    if (_eventQueue.isEmpty) return;
    final queued = _eventQueue
        .where(
          (event) =>
      _awaitingPopup.contains(event.requestReference) &&
          !_handledReferences.contains(event.requestReference) &&
          !_presentedReferences.contains(event.requestReference),
    )
        .toList(growable: false);
    if (queued.isEmpty) return;
    scheduleMicrotask(() {
      for (final event in queued) {
        if (_eventController.hasListener) {
          _eventController.add(event);
        }
      }
    });
  }

  void markPopupPresented(String requestReference) {
    _awaitingPopup.remove(requestReference);
    _needsPresentationRetry.remove(requestReference);
    _presentedReferences.add(requestReference);
    _isShowingPopup = true;
    logger.info('TUTOR_RECEIVED_POPUP_PRESENTED: $requestReference');
  }

  void releaseForRetry(String requestReference) {
    _presentedReferences.remove(requestReference);
    _isShowingPopup = false;
    if (!_handledReferences.contains(requestReference)) {
      _awaitingPopup.add(requestReference);
      _needsPresentationRetry.add(requestReference);
    }
    logger.info('TUTOR_POPUP_PRESENTATION_FAILED: $requestReference');
  }

  void rebroadcastAwaiting(TutorRequestEvent event) {
    if (_handledReferences.contains(event.requestReference) ||
        _presentedReferences.contains(event.requestReference)) {
      return;
    }
    _awaitingPopup.add(event.requestReference);
    _broadcast(event);
  }

  void markRequestHandled(String requestReference) {
    _inFlight.remove(requestReference);
    _awaitingPopup.remove(requestReference);
    _needsPresentationRetry.remove(requestReference);
    _presentedReferences.remove(requestReference);
    _handledReferences.add(requestReference);
    _eventQueue.removeWhere(
          (event) => event.requestReference == requestReference,
    );
    _isShowingPopup = false;
    unawaited(_markSeen([requestReference]));
    logger.info('Request $requestReference marked as handled');
  }

  bool shouldPresentPopup(String requestReference) {
    if (_handledReferences.contains(requestReference)) return false;
    if (_presentedReferences.contains(requestReference) && _isShowingPopup) {
      return false;
    }
    return _awaitingPopup.contains(requestReference) ||
        _presentedReferences.contains(requestReference);
  }

  void setPopupShowing(bool isShowing) {
    _isShowingPopup = isShowing;
  }

  void clearShownRequests() {
    _inFlight.clear();
    _awaitingPopup.clear();
    _needsPresentationRetry.clear();
    _presentedReferences.clear();
    _handledReferences.clear();
    _authDeferred.clear();
    _eventQueue.clear();
    _hasRunStartupCheck = false;
    _isShowingPopup = false;
    unawaited(TutorRequestPendingStore.clear());
    logger.info('All shown request references cleared');
  }

  Future<void> clearOnLogout() async {
    clearShownRequests();
    await TutorRequestPendingStore.clear();
    logger.info('Tutor request notification state cleared on logout');
  }

  void dispose() {}

  Future<bool> _isCurrentUserTheRequester(String requesterUserId) async {
    final requester = requesterUserId.trim();
    if (requester.isEmpty) return false;
    try {
      final current = (await _currentUserId())?.trim() ?? '';
      return current.isNotEmpty && current == requester;
    } catch (_) {
      return false;
    }
  }
}

class _ListLookup {
  const _ListLookup({required this.ok, this.event});
  final bool ok;
  final TutorRequestEvent? event;
}

class _DeferredTutorRequest {
  const _DeferredTutorRequest({
    required this.requestReference,
    required this.messageId,
    this.force = false,
    this.fromTap = false,
    this.fallback,
  });

  final String requestReference;
  final String messageId;
  final bool force;
  final bool fromTap;
  final TutorRequestEvent? fallback;
}

/// A tutor request that should show the Received popup.
class TutorRequestEvent {
  const TutorRequestEvent({
    required this.requestReference,
    required this.messageId,
    this.amount = '',
    this.subject = '',
    this.requesterName = '',
    this.requestStatus = '',
    this.forced = false,
  });

  final String requestReference;
  final String messageId;
  final String amount;
  final String subject;
  final String requesterName;
  final String requestStatus;

  /// True for notification tap / foreground FCM. Bypasses sender-device skip.
  final bool forced;
}