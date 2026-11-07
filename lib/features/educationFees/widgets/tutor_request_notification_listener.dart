import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../services/logger_service.dart';
import '../../../widgets/k_dialog.dart';
import '../constants/tutor_notification_constants.dart';
import '../components/bank_details_request_popup.dart';
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

    final fetched = await _fetchReceiverDisplay(event.requestReference);
    final amount = double.tryParse(
      _filled(fetched?.amount, event.amount),
    );
    final requesterName = _optional(_filled(fetched?.tutorName, event.requesterName));
    final purpose = _optional(_filled(fetched?.feeType, event.subject));
    final statusLabel = _optional(
      _filled(fetched?.status, event.requestStatus),
    );
    logger.info(
      'RECEIVER_POPUP_FIELDS: ${event.requestReference} '
      'name=${requesterName != null} fee=${purpose != null}',
    );

    try {
      logger.info('CALLING_SHOW_DIALOG: ${event.requestReference}');
      final resultFuture = showBankDetailsRequestPopup(
        popupContext,
        requesterName: requesterName,
        feeType: purpose,
        amount: amount,
        paymentPurpose: purpose,
        paymentStatus: statusLabel,
      );
      _notificationService.markPopupPresented(event.requestReference);
      _navigatorRetryAttempts = 0;
      logger.info('RECEIVED_POPUP_PRESENTED: ${event.requestReference}');

      final result = await resultFuture;
      logger.info(
        'POPUP_RESULT_RECEIVED: ${event.requestReference} result=$result',
      );
      // Complete only after Share Details / Decline API succeeds — not on
      // tap, popup open, or dismiss.
      final submitted = await _handlePopupResult(event, result);
      if (submitted) {
        logger.info(
          'SHARE_DETAILS_COMPLETE: ${event.requestReference} '
          'source=${event.sourceRequestKey}',
        );
        _notificationService.markRequestHandled(
          event.requestReference,
          alsoKeys: [
            if (event.sourceRequestKey.trim().isNotEmpty)
              event.sourceRequestKey.trim(),
          ],
        );
      } else if (result == true) {
        logger.warning(
          'SHARE_DETAILS_FAILED_KEEP_PENDING: ${event.requestReference}',
        );
      }
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
  /// Returns true only when the respond API succeeds.
  Future<bool> _handlePopupResult(
      TutorRequestEvent event,
      bool? result,
      ) async {
    logger.info(
      'HANDLE_POPUP_RESULT: ${event.requestReference} result=$result',
    );
    if (result == null) return false;
    if (!_responding.add(event.requestReference)) return false;
    final action = result == true
        ? TutorNotificationConstants.statusAccepted
        : TutorNotificationConstants.statusRejected;

    var apiOk = false;
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
      apiOk = res.status == true;
      declinedOk = result == false && apiOk;
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
    return apiOk;
  }

  /// Loads `tutor_name` and `fee_type` for this request before the popup opens.
  Future<_ReceiverDisplay?> _fetchReceiverDisplay(String reference) async {
    if (reference.isEmpty) return null;
    _ReceiverDisplay? found;
    try {
      final response = await ref
          .read(educationFeesRepositoryProvider)
          .fetchTutorReceivedRequests(
            page: 1,
            perPage: 50,
            status: TutorNotificationConstants.statusPending,
          );
      for (final request
          in response.data?.requests ?? const <Map<String, dynamic>>[]) {
        final requestReference = (request['request_reference'] ??
                request['requestReference'] ??
                request['tutor_request_reference'])
            ?.toString()
            .trim();
        if (requestReference != reference) continue;
        found = _ReceiverDisplay(
          tutorName: _filled(
            request['requester_name']?.toString(),
            _filled(
              request['sender_name']?.toString(),
              request['tutor_name']?.toString() ?? '',
            ),
          ),
          feeType:
              (request['fee_type'] ?? request['subject'])?.toString().trim() ??
                  '',
          amount: request['amount']?.toString().trim() ?? '',
          status: (request['request_status'] ?? request['status'])
                  ?.toString()
                  .trim() ??
              '',
        );
        break;
      }
    } catch (e) {
      logger.warning('RECEIVER_POPUP_LIST_FETCH_FAILED: $reference');
    }

    if (found != null &&
        found.tutorName.isNotEmpty &&
        found.feeType.isNotEmpty) {
      return found;
    }

    try {
      final status = await ref
          .read(educationFeesRepositoryProvider)
          .fetchTutorRequestStatus(reference);
      final data = status.data;
      if (data == null) return found;
      return _ReceiverDisplay(
        tutorName: _filled(data.requesterName, found?.tutorName ?? ''),
        feeType: _filled(data.subject, found?.feeType ?? ''),
        amount: _filled(data.amount, found?.amount ?? ''),
        status: _filled(data.requestStatus, found?.status ?? ''),
      );
    } catch (e) {
      logger.warning('RECEIVER_POPUP_STATUS_FETCH_FAILED: $reference');
      return found;
    }
  }

  String _filled(String? primary, String fallback) {
    final first = primary?.trim() ?? '';
    if (first.isNotEmpty && first.toLowerCase() != 'null') return first;
    return fallback.trim();
  }

  String? _optional(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed.toLowerCase() == 'null') return null;
    if (trimmed.toLowerCase() == 'true' || trimmed.toLowerCase() == 'false') {
      return null;
    }
    return trimmed;
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

class _ReceiverDisplay {
  const _ReceiverDisplay({
    required this.tutorName,
    required this.feeType,
    required this.amount,
    required this.status,
  });

  final String tutorName;
  final String feeType;
  final String amount;
  final String status;
}