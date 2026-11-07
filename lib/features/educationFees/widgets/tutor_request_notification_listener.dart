import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../services/logger_service.dart';
import '../../../widgets/k_dialog.dart';
import '../constants/tutor_notification_constants.dart';
import '../components/bank_details_request_popup.dart';
import '../controllers/education_fees_controller.dart';
import '../services/tutor_request_notification_service.dart';

/// Key names the backend may use for each popup field. The first non-empty
/// match wins; nested objects are searched too.
const _nameKeys = [
  'requester_name',
  'requesterName',
  'sender_name',
  'senderName',
  'requested_by_name',
  'requested_by',
  'from_name',
  'student_name',
  'parent_name',
  'payer_name',
  'user_name',
  'full_name',
  'tutor_name',
  'name',
];

const _feeKeys = [
  'fee_type',
  'feeType',
  'subject',
  'purpose',
  'payment_purpose',
  'paymentPurpose',
  'category',
];

const _methodKeys = [
  'payment_method',
  'paymentMethod',
  'method',
  'payment_mode',
  'paymentMode',
  'pay_method',
  'payment_type',
  'paymentType',
  'mode',
];

const _statusKeys = [
  'payment_status',
  'paymentStatus',
  'request_status',
  'status',
];

const _amountKeys = [
  'amount',
  'fee_amount',
  'tuition_amount',
  'requested_amount',
];


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
  int _navigatorRetryAttempts = 0;
  int _authRetryAttempts = 0;

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

  /// True when the event is missing any field the popup displays.
  bool _hasMissingDisplayField(TutorRequestEvent event) {
    return event.requesterName.trim().isEmpty ||
        event.subject.trim().isEmpty ||
        event.amount.trim().isEmpty ||
        event.paymentMethod.trim().isEmpty ||
        event.requestStatus.trim().isEmpty;
  }

  /// "₹2,000.00" / "2000" / "2000.00" -> 2000.0 (null when not a number).
  double? _parseAmount(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[^0-9.]'), '');
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
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

    // Alerts / FCM events carry only what the notification payload had, so a
    // field can be blank. Fetch from the API whenever the event is not forced
    // OR is missing a displayed field.
    final needsFetch = !event.forced || _hasMissingDisplayField(event);
    final fetched =
    needsFetch ? await _fetchReceiverDisplay(event.requestReference) : null;

    final amount = _parseAmount(_filled(fetched?.amount, event.amount));
    final requesterName = _filled(fetched?.tutorName, event.requesterName);
    final purpose = _filled(fetched?.feeType, event.subject);
    final statusLabel = _filled(fetched?.status, event.requestStatus);
    final paymentMethod = _filled(fetched?.paymentMethod, event.paymentMethod);
    logger.info(
      'RECEIVER_POPUP_FIELDS: ${event.requestReference} '
          'name=${requesterName.isNotEmpty} fee=${purpose.isNotEmpty} '
          'amount=${amount != null} method=${paymentMethod.isNotEmpty} '
          'status=${statusLabel.isNotEmpty} fetched=${fetched != null}',
    );

    try {
      logger.info('CALLING_SHOW_DIALOG: ${event.requestReference}');
      if (!popupContext.mounted) return;
      final resultFuture = showBankDetailsRequestPopup(
        popupContext,
        requesterName: _optional(requesterName), // Sender name from API
        feeType: _optional(purpose), // Fee type / subject from API
        amount: amount, // Payment amount from API
        paymentPurpose: _optional(purpose), // Payment purpose (same as feeType)
        paymentMethod: _optional(paymentMethod), // Payment method from API
        paymentStatus: _optional(statusLabel), // Payment status from API
        requestReference: event.requestReference, // Request reference ID
        notificationId: event.notificationId, // Notification ID (alerts only)
      );
      _notificationService.markPopupPresented(event.requestReference);
      _navigatorRetryAttempts = 0;
      logger.info('RECEIVED_POPUP_PRESENTED: ${event.requestReference}');

      final result = await resultFuture;
      logger.info(
        'POPUP_RESULT_RECEIVED: ${event.requestReference} result=$result',
      );
      // The popup now handles Respond API and notification deletion internally.
      // We only need to mark the request as handled in the notification service.
      if (result == true || result == false) {
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

  bool _isComplete(_ReceiverDisplay d) {
    return d.tutorName.isNotEmpty &&
        d.feeType.isNotEmpty &&
        d.amount.isNotEmpty &&
        d.status.isNotEmpty &&
        d.paymentMethod.isNotEmpty;
  }

  /// First non-empty value for [keys] on this map, then inside nested maps.
  String _pick(Map<String, dynamic> map, List<String> keys, {int depth = 0}) {
    for (final key in keys) {
      final value = map[key];
      if (value is Map || value is List || value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty && text.toLowerCase() != 'null') return text;
    }
    if (depth > 3) return '';
    for (final value in map.values) {
      if (value is Map) {
        final nested = _pick(
          Map<String, dynamic>.from(value),
          keys,
          depth: depth + 1,
        );
        if (nested.isNotEmpty) return nested;
      }
    }
    return '';
  }

  /// Loads name, fee type, amount, status and payment method for this request
  /// before the popup opens. Uses the received-requests list first, then fills
  /// any blank with the request-status API.
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
        final requestId =
            (request['request_id'] ?? request['id'])?.toString().trim();
        if (requestReference != reference && requestId != reference) continue;
        // Key names only (no personal values) so a missing field can be traced.
        logger.info('RECEIVER_ROW_KEYS: $reference ${request.keys.join(",")}');
        found = _ReceiverDisplay(
          tutorName: _pick(request, _nameKeys),
          feeType: _pick(request, _feeKeys),
          amount: _pick(request, _amountKeys),
          status: _pick(request, _statusKeys),
          paymentMethod: _pick(request, _methodKeys),
        );
        break;
      }
      if (found == null) {
        logger.info('RECEIVER_ROW_NOT_IN_PENDING_LIST: $reference');
      }
    } catch (e) {
      logger.warning('RECEIVER_POPUP_LIST_FETCH_FAILED: $reference');
    }

    // Only skip the status API when EVERY displayed field is already filled.
    if (found != null && _isComplete(found)) {
      return found;
    }

    try {
      final status = await ref
          .read(educationFeesRepositoryProvider)
          .fetchTutorRequestStatus(reference);
      final data = status.data;
      logger.info(
        'RECEIVER_STATUS_DATA: $reference '
            'present=${data != null} '
            'name=${(data?.requesterName ?? '').isNotEmpty} '
            'fee=${(data?.subject ?? '').isNotEmpty} '
            'amount=${(data?.amount ?? '').isNotEmpty} '
            'method=${(data?.paymentMethod ?? '').isNotEmpty} '
            'status=${(data?.requestStatus ?? '').isNotEmpty}',
      );
      if (data == null) return found;
      return _ReceiverDisplay(
        tutorName: _filled(found?.tutorName, data.requesterName),
        feeType: _filled(found?.feeType, data.subject),
        amount: _filled(found?.amount, data.amount),
        status: _filled(found?.status, data.requestStatus),
        paymentMethod: _filled(found?.paymentMethod, data.paymentMethod),
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
    this.paymentMethod = '',
  });

  final String tutorName;
  final String feeType;
  final String amount;
  final String status;
  final String paymentMethod;
}