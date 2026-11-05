import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../services/logger_service.dart';
import '../../../widgets/k_dialog.dart';
import '../constants/tutor_notification_constants.dart';
import '../components/education_tuition_request_popup.dart';
import '../controllers/education_fees_controller.dart';
import '../repositories/education_fees_repository.dart';
import '../services/tutor_request_notification_service.dart';

/// Root listener: shows the Received popup for a NEW tutor request
/// (foreground FCM, notification tap, or a not-yet-shown pending request found
/// on startup / resume). Accept / Decline call the respond-request API.
/// After a successful Decline, the declined popup is shown on the RECEIVER
/// device only (the sender never sees it).
class TutorRequestNotificationListener extends ConsumerStatefulWidget {
  const TutorRequestNotificationListener({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  ConsumerState<TutorRequestNotificationListener> createState() =>
      _TutorRequestNotificationListenerState();
}

class _TutorRequestNotificationListenerState
    extends ConsumerState<TutorRequestNotificationListener> {
  final TutorRequestNotificationService _notificationService =
  TutorRequestNotificationService();

  StreamSubscription<TutorRequestEvent>? _subscription;
  StreamSubscription<void>? _attentionSubscription;
  AppLifecycleListener? _lifecycle;
  Timer? _navigatorRetryTimer;
  Timer? _authRetryTimer;

  final List<TutorRequestEvent> _displayQueue = [];
  final List<TutorRequestEvent> _pendingUntilNavigator = [];
  bool _processingQueue = false;
  final Set<String> _responding = {};
  int _navigatorRetryAttempts = 0;
  int _authRetryAttempts = 0;

  EducationFeesRepository get _repository =>
      ref.read(educationFeesRepositoryProvider);

  @override
  void initState() {
    super.initState();
    _notificationService.bindRepository(
      ref.read(educationFeesRepositoryProvider),
    );
    _notificationService.initialize();
    _subscription =
        _notificationService.requestEvents.listen(_onRequestEvent);
    _attentionSubscription =
        _notificationService.presentationAttention.listen((_) {
          _armAuthRetry();
        });

    _lifecycle = AppLifecycleListener(
      onResume: () {
        unawaited(_checkNewAndProcess());
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_checkNewAndProcess(isStartup: true));
    });
  }

  /// Startup / resume: retries deferred taps and shows only NEW requests.
  Future<void> _checkNewAndProcess({bool isStartup = false}) async {
    await _notificationService.checkNewRequests(isStartup: isStartup);
    _enqueueNavigatorDeferred();
    _scheduleProcessDisplayQueue();
    if (_notificationService.hasAuthDeferred) {
      _armAuthRetry();
    }
  }

  Future<void> _flushAuthDeferredOnly() async {
    await _notificationService.flushAuthDeferredRequests();
    _enqueueNavigatorDeferred();
    _scheduleProcessDisplayQueue();
  }

  @override
  void dispose() {
    _navigatorRetryTimer?.cancel();
    _authRetryTimer?.cancel();
    _lifecycle?.dispose();
    _attentionSubscription?.cancel();
    _subscription?.cancel();
    super.dispose();
  }

  void _onRequestEvent(TutorRequestEvent event) {
    logger.info('GLOBAL_LISTENER_EVENT_RECEIVED: ${event.requestReference}');
    _navigatorRetryAttempts = 0;
    _pendingUntilNavigator.removeWhere(
          (queued) => queued.requestReference == event.requestReference,
    );
    _enqueueForDisplay(event);
    scheduleMicrotask(() {
      if (!mounted) return;
      unawaited(_processDisplayQueue());
    });
    _scheduleProcessDisplayQueue();
    Future<void>.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      _enqueueNavigatorDeferred();
      unawaited(_processDisplayQueue());
    });
  }

  void _scheduleProcessDisplayQueue() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_processDisplayQueue());
    });
  }

  void _enqueueForDisplay(TutorRequestEvent event) {
    final alreadyQueued = _displayQueue.any(
          (queued) => queued.requestReference == event.requestReference,
    ) ||
        _pendingUntilNavigator.any(
              (queued) => queued.requestReference == event.requestReference,
        );
    if (alreadyQueued) return;
    _displayQueue.add(event);
  }

  void _enqueueNavigatorDeferred() {
    if (_pendingUntilNavigator.isEmpty) return;
    final deferred = List<TutorRequestEvent>.from(_pendingUntilNavigator);
    _pendingUntilNavigator.clear();
    for (final event in deferred) {
      _enqueueForDisplay(event);
    }
  }

  void _queueUntilNavigatorReady(TutorRequestEvent event) {
    _notificationService.releaseForRetry(event.requestReference);
    if (!_pendingUntilNavigator.any(
          (queued) => queued.requestReference == event.requestReference,
    )) {
      _pendingUntilNavigator.add(event);
    }
    _armNavigatorRetry();
  }

  void _armNavigatorRetry() {
    if (_pendingUntilNavigator.isEmpty) {
      _navigatorRetryTimer?.cancel();
      _navigatorRetryTimer = null;
      _navigatorRetryAttempts = 0;
      return;
    }

    _navigatorRetryAttempts++;
    if (_navigatorRetryAttempts >
        TutorNotificationConstants.navigatorRetryLimit) {
      logger.warning(
        'ROOT_NAVIGATOR_RETRY_EXHAUSTED: ${_pendingUntilNavigator.map((e) => e.requestReference).join(",")}',
      );
      for (final event in _pendingUntilNavigator) {
        _notificationService.releaseForRetry(event.requestReference);
      }
      return;
    }

    _navigatorRetryTimer?.cancel();
    _navigatorRetryTimer =
        Timer(TutorNotificationConstants.navigatorRetryDelay, () {
          if (!mounted) return;
          _enqueueNavigatorDeferred();
          _scheduleProcessDisplayQueue();
          if (_pendingUntilNavigator.isNotEmpty) {
            _armNavigatorRetry();
          }
        });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _enqueueNavigatorDeferred();
      unawaited(_processDisplayQueue());
    });
  }

  Future<void> _processDisplayQueue() async {
    if (_processingQueue) return;
    _processingQueue = true;
    try {
      while (_displayQueue.isNotEmpty) {
        final event = _displayQueue.removeAt(0);
        await _presentReceivedPopup(event);
      }
    } finally {
      _processingQueue = false;
    }
  }

  Future<void> _presentReceivedPopup(TutorRequestEvent event) async {
    logger.info('PRESENT_RECEIVED_POPUP_CALLED: ${event.requestReference}');

    if (!_notificationService.shouldPresentPopup(event.requestReference) &&
        _notificationService.shownRequestReferences
            .contains(event.requestReference)) {
      logger.info(
        'SKIP_RECEIVED_POPUP_ALREADY_HANDLED: ${event.requestReference}',
      );
      return;
    }

    // The sender's own device never shows the receiver popup.
    final sentReference =
        ref.read(educationFeesControllerProvider).requestReference;
    if (sentReference != null &&
        sentReference.isNotEmpty &&
        sentReference == event.requestReference) {
      logger.info(
        'SKIP_RECEIVED_POPUP_SENDER_DEVICE: ${event.requestReference}',
      );
      _notificationService.markRequestHandled(event.requestReference);
      return;
    }

    final popupContext = _resolvePopupContext();
    if (popupContext == null) {
      logger.warning('ROOT_NAVIGATOR_NOT_READY: ${event.requestReference}');
      _queueUntilNavigatorReady(event);
      return;
    }

    final amount = double.tryParse(event.amount.trim());
    final requesterName =
    event.requesterName.trim().isEmpty ? null : event.requesterName.trim();
    final purpose =
    event.subject.trim().isEmpty ? null : event.subject.trim();
    final statusLabel = event.requestStatus.trim().isEmpty
        ? null
        : event.requestStatus.trim();

    try {
      logger.info('CALLING_SHOW_DIALOG: ${event.requestReference}');
      final resultFuture = showEducationTuitionRequestPopup(
        popupContext,
        state: EducationTuitionPopupState.received,
        amount: amount,
        requesterName: requesterName,
        paymentPurpose: purpose,
        requestStatusLabel: statusLabel,
      );
      _notificationService.markPopupPresented(event.requestReference);
      _navigatorRetryAttempts = 0;
      logger.info('RECEIVED_POPUP_PRESENTED: ${event.requestReference}');

      final result = await resultFuture;
      logger.info(
        'POPUP_RESULT_RECEIVED: ${event.requestReference} result=$result',
      );
      await _handlePopupResult(event, result);
      _notificationService.markRequestHandled(event.requestReference);
    } catch (e, stackTrace) {
      logger.error(
        'Error presenting received popup: $e',
        error: e,
        stackTrace: stackTrace,
      );
      _queueUntilNavigatorReady(event);
    }
  }

  void _armAuthRetry() {
    if (!_notificationService.hasAuthDeferred) {
      _authRetryTimer?.cancel();
      _authRetryTimer = null;
      _authRetryAttempts = 0;
      return;
    }
    _authRetryAttempts++;
    if (_authRetryAttempts > TutorNotificationConstants.authRetryLimit) {
      logger.info(
        'TUTOR_POPUP_PRESENTATION_FAILED: auth_deferred_retry_exhausted',
      );
      return;
    }
    _authRetryTimer?.cancel();
    _authRetryTimer = Timer(TutorNotificationConstants.authRetryDelay, () {
      if (!mounted) return;
      unawaited(_flushAuthDeferredOnly().whenComplete(() {
        if (!mounted) return;
        if (_notificationService.hasAuthDeferred) {
          _armAuthRetry();
        } else {
          _authRetryAttempts = 0;
        }
      }));
    });
  }

  /// Accept -> ACCEPTED, Decline -> REJECTED via
  /// POST /api/education/tutor/respond-request
  /// with body {"request_reference", "action"}.
  /// A successful Decline shows the declined popup on THIS (receiver) device.
  Future<void> _handlePopupResult(
      TutorRequestEvent event,
      bool? result,
      ) async {
    logger.info(
      'HANDLE_POPUP_RESULT: ${event.requestReference} result=$result',
    );
    if (result == null) return;
    if (!_responding.add(event.requestReference)) return;
    final action = result == true
        ? TutorNotificationConstants.statusAccepted
        : TutorNotificationConstants.statusRejected;

    var declinedOk = false;
    try {
      logger.info(
        'RESPOND_REQUEST_CALL: ${event.requestReference} action=$action',
      );
      final res = await _repository.respondToTutorRequest(
        requestReference: event.requestReference,
        action: action,
      );
      logger.info(
        'RESPOND_REQUEST_RESULT: ${event.requestReference} '
            'status=${res.status} message=${res.message} '
            'requestStatus=${res.data?.requestStatus ?? res.requestStatus}',
      );
      declinedOk = result == false && res.status == true;
    } catch (e) {
      logger.error(
        'Failed to submit tutor request response: $e',
        error: e,
      );
    } finally {
      _responding.remove(event.requestReference);
    }

    if (declinedOk) {
      await _showDeclinedPopup(event);
    }
  }

  /// Declined popup, shown only on the receiver device after a successful
  /// Decline.
  Future<void> _showDeclinedPopup(TutorRequestEvent event) async {
    final popupContext = _resolvePopupContext();
    if (popupContext == null) {
      logger.warning('DECLINED_POPUP_NO_CONTEXT: ${event.requestReference}');
      return;
    }
    final amount = double.tryParse(event.amount.trim());
    final requesterName =
    event.requesterName.trim().isEmpty ? null : event.requesterName.trim();
    try {
      logger.info('SHOW_DECLINED_POPUP: ${event.requestReference}');
      await showEducationTuitionRequestPopup(
        popupContext,
        state: EducationTuitionPopupState.declined,
        amount: amount,
        requesterName: requesterName,
      );
    } catch (e) {
      logger.error('Failed to show declined popup: $e', error: e);
    }
  }

  BuildContext? _resolvePopupContext() {
    final navigatorState = navigatorKey.currentState;

    final overlayContext = navigatorState?.overlay?.context;
    if (overlayContext != null && overlayContext.mounted) {
      logger.info('POPUP_CONTEXT_SOURCE: overlay');
      return overlayContext;
    }

    if (navigatorState != null && navigatorState.mounted) {
      final navigatorContext = navigatorState.context;
      if (navigatorContext.mounted) {
        logger.info('POPUP_CONTEXT_SOURCE: navigatorKey.state');
        return navigatorContext;
      }
    }

    final keyContext = navigatorKey.currentContext;
    if (keyContext != null && keyContext.mounted) {
      logger.info('POPUP_CONTEXT_SOURCE: navigatorKey');
      return keyContext;
    }

    logger.info(
      'POPUP_CONTEXT_SOURCE: none mounted=$mounted hasState=${navigatorState != null}',
    );
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}