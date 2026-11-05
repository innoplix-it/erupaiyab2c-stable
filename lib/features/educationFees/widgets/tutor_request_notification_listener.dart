import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../services/logger_service.dart';
import '../../../widgets/k_dialog.dart';
import '../components/education_tuition_request_popup.dart';
import '../controllers/education_fees_controller.dart';
import '../repositories/education_fees_repository.dart';
import '../services/tutor_request_notification_service.dart';

/// Root listener that turns PENDING tutor-request events into the existing
/// Received popup, regardless of the current GoRouter location.
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
  AppLifecycleListener? _lifecycle;
  Timer? _navigatorRetryTimer;

  final List<TutorRequestEvent> _displayQueue = [];
  final List<TutorRequestEvent> _pendingUntilNavigator = [];
  bool _processingQueue = false;
  final Set<String> _responding = {};
  int _navigatorRetryAttempts = 0;

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

    _lifecycle = AppLifecycleListener(
      onResume: () {
        unawaited(_flushPendingAndProcess());
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_flushPendingAndProcess(isStartup: true));
    });
  }

  Future<void> _flushPendingAndProcess({bool isStartup = false}) async {
    await _notificationService.flushAuthDeferredRequests();
    // Background-verified PENDING entries → popup without a duplicate GET.
    await _notificationService.flushPersistedPendingRequests();
    if (isStartup) {
      await _notificationService.checkPendingRequestsOnStartup();
    } else {
      await _notificationService.checkPendingRequestsOnResume();
    }
    _enqueueNavigatorDeferred();
    _scheduleProcessDisplayQueue();
  }

  @override
  void dispose() {
    _navigatorRetryTimer?.cancel();
    _lifecycle?.dispose();
    _subscription?.cancel();
    super.dispose();
  }

  void _onRequestEvent(TutorRequestEvent event) {
    logger.info('GLOBAL_LISTENER_EVENT_RECEIVED: ${event.requestReference}');
    _enqueueForDisplay(event);
    // Defer out of the sync stream callback so we never call showDialog
    // during build. Microtask covers the common ready-navigator path;
    // post-frame is a backup when the first attempt races a frame.
    scheduleMicrotask(() {
      if (!mounted) return;
      unawaited(_processDisplayQueue());
    });
    _scheduleProcessDisplayQueue();
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
    if (_navigatorRetryAttempts > 40) {
      logger.warning(
        'ROOT_NAVIGATOR_RETRY_EXHAUSTED: ${_pendingUntilNavigator.map((e) => e.requestReference).join(",")}',
      );
      return;
    }

    _navigatorRetryTimer?.cancel();
    _navigatorRetryTimer = Timer(const Duration(milliseconds: 250), () {
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
    // Skip only when this reference was already handled or is actively on screen.
    // Fresh PENDING-verified events live in awaiting and must still present.
    if (!_notificationService.shouldPresentPopup(event.requestReference) &&
        _notificationService.shownRequestReferences
            .contains(event.requestReference)) {
      logger.info(
        'SKIP_RECEIVED_POPUP_ALREADY_HANDLED: ${event.requestReference}',
      );
      return;
    }

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
      logger.warning(
        'ROOT_NAVIGATOR_NOT_READY: ${event.requestReference}',
      );
      _queueUntilNavigatorReady(event);
      return;
    }

    logger.info('ROOT_NAVIGATOR_READY: ${event.requestReference}');
    logger.info('RECEIVED_POPUP_OPEN_REQUESTED: ${event.requestReference}');

    final amount = double.tryParse(event.amount) ?? 0;
    final requesterName =
        event.subject.isNotEmpty ? event.subject : 'Student';

    try {
      final resultFuture = showEducationTuitionRequestPopup(
        popupContext,
        state: EducationTuitionPopupState.received,
        amount: amount,
        requesterName: requesterName,
      );
      _notificationService.markPopupPresented(event.requestReference);
      _navigatorRetryAttempts = 0;
      logger.info('RECEIVED_POPUP_PRESENTED: ${event.requestReference}');

      final result = await resultFuture;
      await _handlePopupResult(event, result);
      _notificationService.markRequestHandled(event.requestReference);
    } catch (e) {
      logger.error('Error presenting received popup: $e', error: e);
      _queueUntilNavigatorReady(event);
    }
  }

  Future<void> _handlePopupResult(
    TutorRequestEvent event,
    bool? result,
  ) async {
    if (result == null) return;
    if (!_responding.add(event.requestReference)) return;
    try {
      if (result == true) {
        await _repository.respondToTutorRequest(
          requestReference: event.requestReference,
          action: 'ACCEPTED',
        );
      } else {
        await _repository.respondToTutorRequest(
          requestReference: event.requestReference,
          action: 'REJECTED',
        );
      }
    } catch (e) {
      logger.error(
        'Failed to submit tutor request response: $e',
        error: e,
      );
    } finally {
      _responding.remove(event.requestReference);
    }
  }

  BuildContext? _resolvePopupContext() {
    // Prefer the NavigatorState context attached to the shared root key —
    // MaterialApp.router's builder context sits ABOVE the Router and cannot
    // resolve a Navigator via Navigator.of.
    final navigatorState = navigatorKey.currentState;
    if (navigatorState != null && navigatorState.mounted) {
      final navigatorContext = navigatorState.context;
      if (navigatorContext.mounted) {
        logger.info('POPUP_CONTEXT_SOURCE: navigatorKey.state');
        return navigatorContext;
      }
    }

    final overlayContext = navigatorState?.overlay?.context;
    if (overlayContext != null && overlayContext.mounted) {
      logger.info('POPUP_CONTEXT_SOURCE: overlay');
      return overlayContext;
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
