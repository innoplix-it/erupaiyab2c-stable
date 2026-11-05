import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../../services/logger_service.dart';
import '../../../utils/utils.dart';
import '../models/education_fees_responses.dart';
import '../repositories/education_fees_repository.dart';
import 'tutor_request_pending_store.dart';

/// Handles tutor payment-request FCM events and PENDING verification.
///
/// Popup presentation is performed by [TutorRequestNotificationListener]
/// using the existing [EducationTuitionRequestPopup]. This service never
/// creates a dialog of its own.
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

  /// In-progress Request Status GET calls, keyed by request_reference.
  final Set<String> _inFlight = {};

  /// PENDING-verified requests waiting for the Received popup to present.
  final Set<String> _awaitingPopup = {};

  /// Request whose Received popup is currently on screen.
  final Set<String> _presentedReferences = {};

  /// Requests that were dismissed or actioned this session.
  final Set<String> _handledReferences = {};

  /// FCM/open events received before authentication was ready.
  final List<_DeferredTutorRequest> _authDeferred = [];

  late final StreamController<TutorRequestEvent> _eventController;

  /// Events broadcast before any listener subscribed. Replayed on first listen.
  final List<TutorRequestEvent> _eventQueue = [];

  bool _hasRunStartupCheck = false;
  bool _isShowingPopup = false;

  /// Bind the repository used for Request Status / respond APIs.
  ///
  /// The global listener binds the Riverpod instance so widget tests that
  /// override [educationFeesRepositoryProvider] exercise the same object.
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
  void debugReset({
    EducationFeesRepository? repository,
    Future<bool> Function()? authChecker,
  }) {
    clearShownRequests();
    if (repository != null) {
      _repository = repository;
    }
    if (authChecker != null) {
      _authChecker = authChecker;
    }
  }

  /// Union of awaiting / presented / handled references for tests.
  Set<String> get shownRequestReferences => Set.unmodifiable({
        ..._awaitingPopup,
        ..._presentedReferences,
        ..._handledReferences,
      });

  Stream<TutorRequestEvent> get requestEvents => _eventController.stream;

  bool get isShowingPopup => _isShowingPopup;

  /// Kept for compatibility. FCM listeners live in [PushNotificationService].
  void initialize() {}

  Future<void> checkPendingRequestsOnStartup() async {
    await _checkPendingRequestsInternal(isStartup: true);
  }

  Future<void> checkPendingRequestsOnResume() async {
    await _checkPendingRequestsInternal(isStartup: false);
  }

  /// Retry FCM events that arrived before authentication was ready.
  Future<void> flushAuthDeferredRequests() async {
    if (_authDeferred.isEmpty) return;
    final pending = List<_DeferredTutorRequest>.from(_authDeferred);
    _authDeferred.clear();
    for (final deferred in pending) {
      await _processRequestReference(
        deferred.requestReference,
        messageId: deferred.messageId,
      );
    }
  }

  /// Consume PENDING entries persisted by the FCM background isolate.
  ///
  /// Verified entries skip a second Request Status GET and broadcast directly.
  /// Unverified entries run through the normal status verification path.
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
          messageId: 'background_verified',
        );
      } else {
        // Keep the store entry until status verification succeeds or the
        // request is confirmed non-PENDING (handled inside _process).
        await _processRequestReference(
          entry.requestReference,
          messageId: 'background_unverified',
        );
      }
    }
  }

  /// Broadcast a background-verified PENDING request without repeating GET.
  Future<void> ingestVerifiedPending({
    required String requestReference,
    required String amount,
    required String subject,
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

    logger.info('INGEST_VERIFIED_PENDING: $requestReference');
    _awaitingPopup.add(requestReference);
    _broadcast(
      TutorRequestEvent(
        requestReference: requestReference,
        messageId: messageId,
        amount: amount,
        subject: subject,
      ),
    );
    await TutorRequestPendingStore.remove(requestReference);
  }

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
      logger.info(
        'Checking for pending tutor requests on ${isStartup ? "startup" : "resume"}',
      );

      final response = await _repository.fetchTutorReceivedRequests(
        page: 1,
        perPage: 20,
        status: 'PENDING',
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

      for (final request in requests) {
        final requestReference = (request['request_reference'] ??
                request['requestReference'])
            ?.toString();
        if (requestReference == null || requestReference.isEmpty) {
          continue;
        }
        await _processRequestReference(
          requestReference,
          messageId:
              '${isStartup ? "startup" : "resume"}_${DateTime.now().millisecondsSinceEpoch}',
        );
      }
    } catch (e) {
      logger.error(
        'Error checking pending requests on ${isStartup ? "startup" : "resume"}: $e',
        error: e,
      );
    }
  }

  /// Foreground, background-tap and terminated-launch FCM entry point.
  Future<void> handleForegroundMessage(RemoteMessage message) async {
    logger.info('FCM_RECEIVED: ${message.messageId}');
    await handleIncomingFromData(
      message.data,
      messageId: message.messageId ?? '',
    );
  }

  /// Same path as [handleForegroundMessage] for OS notification taps.
  Future<void> handleOpenedMessage(RemoteMessage message) {
    return handleForegroundMessage(message);
  }

  Future<void> handleIncomingFromData(
    Map<String, dynamic> data, {
    String messageId = '',
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

    logger.info('REQUEST_REFERENCE_EXTRACTED: $requestReference');
    await _processRequestReference(
      requestReference,
      messageId: messageId,
    );
  }

  Future<void> _processRequestReference(
    String requestReference, {
    required String messageId,
  }) async {
    if (requestReference.isEmpty) return;

    if (_handledReferences.contains(requestReference) ||
        _presentedReferences.contains(requestReference) ||
        _awaitingPopup.contains(requestReference)) {
      logger.info(
        'Request $requestReference already queued, shown or handled, skipping',
      );
      return;
    }

    if (_inFlight.contains(requestReference)) {
      logger.info(
        'Request $requestReference verification in-flight, skipping duplicate GET',
      );
      return;
    }

    _inFlight.add(requestReference);
    try {
      // Prefer a background-verified PENDING result to avoid a duplicate GET.
      final persisted =
          await TutorRequestPendingStore.takeVerified(requestReference);
      if (persisted != null) {
        logger.info(
          'REQUEST_STATUS_SKIPPED_BACKGROUND_VERIFIED: $requestReference',
        );
        _awaitingPopup.add(requestReference);
        _broadcast(
          TutorRequestEvent(
            requestReference: requestReference,
            messageId: messageId.isNotEmpty
                ? messageId
                : 'background_verified_reuse',
            amount: persisted.amount,
            subject: persisted.subject,
          ),
        );
        return;
      }

      final isAuthenticated = await _authChecker();
      if (!isAuthenticated) {
        _authDeferred.removeWhere(
          (item) => item.requestReference == requestReference,
        );
        _authDeferred.add(
          _DeferredTutorRequest(
            requestReference: requestReference,
            messageId: messageId,
          ),
        );
        logger.info('AUTH_NOT_READY queued: $requestReference');
        return;
      }

      logger.info('REQUEST_STATUS_API_STARTED: $requestReference');
      final response =
          await _repository.fetchTutorRequestStatus(requestReference);
      logger.info('REQUEST_STATUS_API_SUCCESS: $requestReference');

      if (!_isStrictPending(response, requestReference)) {
        logger.info('Request $requestReference is not pending, skipping popup');
        final data = response.data;
        if (data != null && (data.isAccepted || data.isRejected)) {
          _handledReferences.add(requestReference);
        }
        await TutorRequestPendingStore.remove(requestReference);
        return;
      }

      logger.info('REQUEST_STATUS_PENDING_CONFIRMED: $requestReference');

      final data = response.data!;
      _awaitingPopup.add(requestReference);
      await TutorRequestPendingStore.remove(requestReference);
      _broadcast(
        TutorRequestEvent(
          requestReference: requestReference,
          messageId: messageId,
          amount: data.amount,
          subject: data.subject,
        ),
      );
    } catch (e) {
      logger.error('REQUEST_STATUS_API_ERROR: $e', error: e);
    } finally {
      _inFlight.remove(requestReference);
    }
  }

  /// Strict PENDING gate from the Request Status API response.
  bool _isStrictPending(
    EducationTutorRequestStatusResponse response,
    String incomingRequestReference,
  ) {
    final data = response.data;
    return response.status == true &&
        data != null &&
        data.requestReference == incomingRequestReference &&
        data.requestStatus.trim().toUpperCase() == 'PENDING' &&
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
    if (type.contains('tutor') ||
        type.contains('tuition') ||
        type.contains('education') ||
        type.contains('request')) {
      return true;
    }

    // Explicit tutor request reference keys still qualify unless the type is
    // clearly unrelated to education/tutor flows.
    final hasTutorRefKey = data.containsKey('request_reference') ||
        data.containsKey('requestReference') ||
        data.containsKey('tutor_request_reference');
    if (!hasTutorRefKey) return false;

    const excluded = <String>[
      'wallet',
      'kyc',
      'spin',
      'gold',
      'recharge',
      'bbps',
      'credit_card',
    ];
    return !excluded.any(type.contains);
  }

  static String? extractRequestReference(Map<String, dynamic> data) {
    final requestRef = data['request_reference'] ??
        data['requestReference'] ??
        data['tutor_request_reference'];
    if (requestRef != null && requestRef.toString().trim().isNotEmpty) {
      return requestRef.toString().trim();
    }

    final type = (data['type'] ?? data['notification_type'])
        ?.toString()
        .trim()
        .toLowerCase();
    final isTutorType = type != null &&
        (type.contains('tutor') ||
            type.contains('tuition') ||
            type.contains('education'));
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

  void _replayQueuedEvents() {
    if (_eventQueue.isEmpty) return;
    // Only replay verified requests that still need the Received popup.
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

  /// Called by the listener after [showDialog] has inserted the route.
  void markPopupPresented(String requestReference) {
    _awaitingPopup.remove(requestReference);
    _presentedReferences.add(requestReference);
    _isShowingPopup = true;
    logger.info('POPUP_PRESENTATION_LOCKED: $requestReference');
  }

  /// Navigator was not ready. Keep the verified request until it is.
  void releaseForRetry(String requestReference) {
    _presentedReferences.remove(requestReference);
    _isShowingPopup = false;
    if (!_handledReferences.contains(requestReference)) {
      _awaitingPopup.add(requestReference);
    }
    logger.info('POPUP_PRESENTATION_RELEASED_FOR_RETRY: $requestReference');
  }

  /// Re-broadcast awaiting events so the listener can present them later.
  void rebroadcastAwaiting(TutorRequestEvent event) {
    if (_handledReferences.contains(event.requestReference) ||
        _presentedReferences.contains(event.requestReference)) {
      return;
    }
    _awaitingPopup.add(event.requestReference);
    _broadcast(event);
  }

  /// Popup was dismissed or ACCEPT/REJECT completed.
  void markRequestHandled(String requestReference) {
    _inFlight.remove(requestReference);
    _awaitingPopup.remove(requestReference);
    _presentedReferences.remove(requestReference);
    _handledReferences.add(requestReference);
    _eventQueue.removeWhere(
      (event) => event.requestReference == requestReference,
    );
    _isShowingPopup = false;
    logger.info('Request $requestReference marked as handled');
  }

  /// Whether this request still needs popup presentation.
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
    _presentedReferences.clear();
    _handledReferences.clear();
    _authDeferred.clear();
    _eventQueue.clear();
    _hasRunStartupCheck = false;
    _isShowingPopup = false;
    // Fire-and-forget persistence cleanup (logout / test reset).
    unawaited(TutorRequestPendingStore.clear());
    logger.info('All shown request references cleared');
  }

  /// Explicit logout cleanup for in-memory + persisted popup candidates.
  Future<void> clearOnLogout() async {
    clearShownRequests();
    await TutorRequestPendingStore.clear();
    logger.info('Tutor request notification state cleared on logout');
  }

  void dispose() {
    // Singleton stream stays open for the process lifetime.
  }
}

class _DeferredTutorRequest {
  const _DeferredTutorRequest({
    required this.requestReference,
    required this.messageId,
  });

  final String requestReference;
  final String messageId;
}

/// Event representing a PENDING-verified tutor request that should show
/// the existing Received popup.
class TutorRequestEvent {
  const TutorRequestEvent({
    required this.requestReference,
    required this.messageId,
    this.amount = '0',
    this.subject = '',
  });

  final String requestReference;
  final String messageId;
  final String amount;
  final String subject;
}
