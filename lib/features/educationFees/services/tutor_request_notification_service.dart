import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../../services/logger_service.dart';
import '../../../utils/utils.dart';
import '../constants/tutor_notification_constants.dart';
import '../models/education_fees_responses.dart';
import '../repositories/education_fees_repository.dart';
import 'tutor_request_pending_store.dart';

/// Handles tutor payment-request FCM events.
///
/// NOTE: backend `GET request-status/{ref}` works only for the SENDER and
/// returns 404 for the tutor (receiver). So the tutor side never depends on
/// it: startup/resume use the received-requests (PENDING) list, and tap /
/// foreground FCM (FORCE mode) always end in a popup (list or FCM payload).
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

  EducationFeesRepository _repository = EducationFeesRepository();
  Future<bool> Function() _authChecker = Utils.checkAuthentication;
  Future<String?> Function() _currentUserId = Utils.getUserId;

  static const Set<String> _terminalStatuses = {
    'ACCEPTED',
    'REJECTED',
    'DECLINED',
    'EXPIRED',
    'CANCELLED',
    'CANCELED',
  };

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
    if (repository != null) {
      _repository = repository;
    }
    if (authChecker != null) {
      _authChecker = authChecker;
    }
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

  Future<void> checkPendingRequestsOnStartup() async {
    await _checkPendingRequestsInternal(isStartup: true);
  }

  Future<void> checkPendingRequestsOnResume() async {
    await _checkPendingRequestsInternal(isStartup: false);
  }

  Future<void> flushAuthDeferredRequests() async {
    if (_authDeferred.isEmpty) return;
    final pending = List<_DeferredTutorRequest>.from(_authDeferred);
    _authDeferred.clear();
    for (final deferred in pending) {
      await _processRequestReference(
        deferred.requestReference,
        messageId: deferred.messageId,
        force: deferred.force,
        fallback: deferred.fallback,
      );
    }
  }

  Future<void> flushPersistedPendingRequests() async {
    final entries = await TutorRequestPendingStore.loadAll();
    if (entries.isEmpty) return;

    logger.info(
      'FLUSH_PERSISTED_PENDING_REQUESTS: count=${entries.length}',
    );

    for (final entry in entries) {
      if (entry.verified) {
        await ingestVerifiedPending(
          requestReference: entry.requestReference,
          amount: entry.amount,
          subject: entry.subject,
          requesterName: entry.requesterName,
          requesterUserId: entry.requesterUserId,
          requestStatus: entry.requestStatus,
          messageId: 'background_verified',
        );
      } else {
        await _processRequestReference(
          entry.requestReference,
          messageId: 'background_unverified',
        );
      }
    }
  }

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
      logger.info(
        'INGEST_VERIFIED_SKIP_ALREADY_QUEUED: $requestReference',
      );
      await TutorRequestPendingStore.remove(requestReference);
      return;
    }
    if (await _isCurrentUserTheRequester(requesterUserId)) {
      logger.info(
        'SKIP_RECEIVED_POPUP_REQUESTER_USER: $requestReference',
      );
      _handledReferences.add(requestReference);
      await TutorRequestPendingStore.remove(requestReference);
      return;
    }

    logger.info('INGEST_VERIFIED_PENDING: $requestReference');
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

  /// Startup / resume: the received-requests PENDING list IS the source of
  /// truth for the tutor. No request-status GET (it 404s for the receiver).
  Future<void> _checkPendingRequestsInternal({required bool isStartup}) async {
    if (isStartup && _hasRunStartupCheck) {
      logger.info('Startup check already ran, skipping');
      return;
    }

    final isAuthenticated = await _authChecker();
    if (!isAuthenticated) {
      logger.info(
        'User not authenticated, skipping ${isStartup ? "startup" : "resume"} check',
      );
      return;
    }

    await flushAuthDeferredRequests();

    try {
      final response = await _repository.fetchTutorReceivedRequests(
        page: TutorNotificationConstants.defaultPage,
        perPage: TutorNotificationConstants.defaultPerPage,
        status: TutorNotificationConstants.statusPending,
      );

      if (!response.status || response.data == null) {
        logger.warning(
          'Failed to fetch pending requests on ${isStartup ? "startup" : "resume"}',
        );
        return;
      }

      final requests = response.data!.requests;
      logger.info(
        'Found ${requests.length} pending requests on ${isStartup ? "startup" : "resume"}',
      );

      if (isStartup) {
        _hasRunStartupCheck = true;
      }

      for (final item in requests) {
        final map = _asStringMap(item);
        if (map == null) continue;
        final requestReference = _refFromMap(map);
        if (requestReference == null || requestReference.isEmpty) continue;

        final messageId =
            '${isStartup ? "startup" : "resume"}_${DateTime.now().millisecondsSinceEpoch}';
        await _processRequestReference(
          requestReference,
          messageId: messageId,
          fallback: _eventFromMap(requestReference, messageId, map, false),
          trustFallback: true,
        );
      }
    } catch (e) {
      logger.error(
        'Error checking pending requests on ${isStartup ? "startup" : "resume"}: $e',
        error: e,
      );
    }
  }

  /// Foreground FCM entry point (FORCE mode).
  Future<void> handleForegroundMessage(RemoteMessage message) async {
    logger.info('FCM_RECEIVED: ${message.messageId}');
    await handleIncomingFromData(
      message.data,
      messageId: message.messageId ?? '',
    );
  }

  Future<void> handleOpenedMessage(RemoteMessage message) {
    return handleOpenedData(
      message.data,
      messageId: message.messageId ?? 'opened',
    );
  }

  /// Notification TAP entry point (FORCE mode).
  Future<void> handleOpenedData(
      Map<String, dynamic> raw, {
        String messageId = 'notification_tap',
      }) {
    logger.info('TUTOR_NOTIFICATION_TAP_RECEIVED: $messageId');
    final data = notificationDataFromPayload(raw);
    logger.info(
      'TUTOR_NOTIFICATION_PAYLOAD_EXTRACTED: keys=${data.keys.join(',')}',
    );
    return handleIncomingFromData(data, messageId: messageId);
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
      fallback: _eventFromMap(requestReference, messageId, data, force),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers: map -> event
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

  /// Finds the request in the tutor's received PENDING list (used to enrich
  /// a tapped notification when the FCM payload has no amount / name).
  Future<TutorRequestEvent?> _lookupInReceivedList(
      String requestReference,
      String messageId,
      ) async {
    try {
      final res = await _repository.fetchTutorReceivedRequests(
        page: 1,
        perPage: 50,
        status: TutorNotificationConstants.statusPending,
      );
      if (!res.status || res.data == null) return null;
      for (final item in res.data!.requests) {
        final map = _asStringMap(item);
        if (map == null) continue;
        if (_refFromMap(map) == requestReference) {
          logger.info('RECEIVED_LIST_LOOKUP_HIT: $requestReference');
          return _eventFromMap(requestReference, messageId, map, true);
        }
      }
      logger.info('RECEIVED_LIST_LOOKUP_MISS: $requestReference');
    } catch (e) {
      logger.error('RECEIVED_LIST_LOOKUP_ERROR: $e', error: e);
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Core
  // ---------------------------------------------------------------------------

  Future<void> _processRequestReference(
      String requestReference, {
        required String messageId,
        bool force = false,
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
      _eventQueue.removeWhere(
            (e) => e.requestReference == requestReference,
      );
    } else {
      if (_handledReferences.contains(requestReference)) {
        logger.info('Request $requestReference already handled, skipping');
        return;
      }
      if (_presentedReferences.contains(requestReference) &&
          _isShowingPopup) {
        return;
      }
      if (_needsPresentationRetry.contains(requestReference) &&
          !_isShowingPopup) {
        _rebroadcastAwaitingPopup(requestReference, messageId);
        return;
      }
      if (_presentedReferences.contains(requestReference) ||
          _awaitingPopup.contains(requestReference)) {
        return;
      }
      if (_inFlight.contains(requestReference)) {
        return;
      }
    }

    _inFlight.add(requestReference);
    try {
      // 1) Background-verified entry.
      final persisted =
      await TutorRequestPendingStore.takeVerified(requestReference);
      if (persisted != null) {
        if (!force &&
            await _isCurrentUserTheRequester(persisted.requesterUserId)) {
          _handledReferences.add(requestReference);
          return;
        }
        _queuePopup(
          TutorRequestEvent(
            requestReference: requestReference,
            messageId: messageId.isNotEmpty
                ? messageId
                : 'background_verified_reuse',
            amount: persisted.amount,
            subject: persisted.subject,
            requesterName: persisted.requesterName,
            requestStatus: persisted.requestStatus,
            forced: force,
          ),
        );
        return;
      }

      // 2) Auth gate.
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
            fallback: fallback,
          ),
        );
        await TutorRequestPendingStore.upsert(
          TutorRequestPendingEntry(
            requestReference: requestReference,
            verified: false,
          ),
        );
        logger.info('AUTH_NOT_READY queued: $requestReference');
        if (!_presentationAttention.isClosed) {
          _presentationAttention.add(null);
        }
        return;
      }

      // 2b) Item came from the received PENDING list -> already verified.
      if (trustFallback && fallback != null) {
        logger.info('POPUP_FROM_RECEIVED_LIST: $requestReference');
        await TutorRequestPendingStore.remove(requestReference);
        _queuePopup(fallback);
        return;
      }

      // 3) Request Status API (sender-only on backend; may 404 for tutor).
      logger.info('TUTOR_REQUEST_STATUS_API_STARTED: $requestReference');
      EducationTutorRequestStatusResponse? response;
      try {
        response = await _repository.fetchTutorRequestStatus(requestReference);
      } catch (e) {
        logger.error('REQUEST_STATUS_API_ERROR: $e', error: e);
      }

      final data = response?.data;
      final apiOk = response != null && response.status == true && data != null;

      if (apiOk) {
        final statusText = data.requestStatus.trim().toUpperCase();
        if (data.isAccepted ||
            data.isRejected ||
            _terminalStatuses.contains(statusText)) {
          logger.info(
            'Request $requestReference is $statusText, skipping popup',
          );
          _handledReferences.add(requestReference);
          await TutorRequestPendingStore.remove(requestReference);
          return;
        }

        if (!force && !_isStrictPending(response, requestReference)) {
          logger.info('Request $requestReference not strict pending, skip');
          await TutorRequestPendingStore.remove(requestReference);
          return;
        }

        if (!force && await _isCurrentUserTheRequester(data.requesterUserId)) {
          _handledReferences.add(requestReference);
          await TutorRequestPendingStore.remove(requestReference);
          return;
        }

        String pick(String a, String? b) => a.trim().isNotEmpty ? a : (b ?? '');

        await TutorRequestPendingStore.remove(requestReference);
        _queuePopup(
          TutorRequestEvent(
            requestReference: requestReference,
            messageId: messageId,
            amount: pick(data.amount, fallback?.amount),
            subject: pick(data.subject, fallback?.subject),
            requesterName: pick(data.requesterName, fallback?.requesterName),
            requestStatus: pick(data.requestStatus, fallback?.requestStatus),
            forced: force,
          ),
        );
        return;
      }

      // 4) Status API failed / 404 (normal for the tutor).
      if (!force) {
        logger.info('REQUEST_STATUS_API_FAILURE: $requestReference');
        return;
      }

      // FORCE: payload first, enrich missing fields from the received list.
      logger.info('FORCE_FALLBACK_POPUP: $requestReference');
      final needsEnrich = fallback == null ||
          fallback.amount.trim().isEmpty ||
          fallback.requesterName.trim().isEmpty;
      final fromList = needsEnrich
          ? await _lookupInReceivedList(requestReference, messageId)
          : null;
      await TutorRequestPendingStore.remove(requestReference);
      _queuePopup(
        _merge(
          requestReference,
          messageId,
          fallback,
          fromList,
          forced: true,
        ),
      );
    } catch (e) {
      logger.error('PROCESS_REQUEST_ERROR: $e', error: e);
      if (force) {
        _queuePopup(
          fallback ??
              TutorRequestEvent(
                requestReference: requestReference,
                messageId: messageId,
                forced: true,
              ),
        );
      }
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
    _broadcast(event);
  }

  bool _isStrictPending(
      EducationTutorRequestStatusResponse response,
      String incomingRequestReference,
      ) {
    final data = response.data;
    return response.status == true &&
        data != null &&
        data.requestReference == incomingRequestReference &&
        data.requestStatus.trim().toUpperCase() ==
            TutorNotificationConstants.statusPending &&
        data.isPending == true &&
        data.isAccepted == false &&
        data.isRejected == false;
  }

  static bool isTutorRequestPayload(Map<String, dynamic> data) {
    final requestReference = extractRequestReference(data);
    if (requestReference == null || requestReference.isEmpty) return false;

    final type = (data['type'] ?? data['notification_type'])
        ?.toString()
        .trim()
        .toLowerCase();
    if (type == null || type.isEmpty) {
      return true;
    }
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

  void _rebroadcastAwaitingPopup(String requestReference, String messageId) {
    TutorRequestEvent? existing;
    for (final event in _eventQueue) {
      if (event.requestReference == requestReference) {
        existing = event;
      }
    }
    _needsPresentationRetry.remove(requestReference);
    _awaitingPopup.add(requestReference);
    _broadcast(
      existing ??
          TutorRequestEvent(
            requestReference: requestReference,
            messageId: messageId,
          ),
    );
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

class _DeferredTutorRequest {
  const _DeferredTutorRequest({
    required this.requestReference,
    required this.messageId,
    this.force = false,
    this.fallback,
  });

  final String requestReference;
  final String messageId;
  final bool force;
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