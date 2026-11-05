import 'dart:async';

import '../../../services/logger_service.dart';
import '../repositories/education_fees_repository.dart';
import 'tutor_request_notification_service.dart';

/// Polling service for tutor requests as a fallback when push notifications are unavailable.
///
/// This service periodically fetches pending tutor requests and triggers notifications
/// for new requests that haven't been seen before. It should be used as a backup mechanism
/// when FCM push notifications are not reliable or not supported by the backend.
class TutorRequestPollingService {
  TutorRequestPollingService._();

  static final TutorRequestPollingService _instance =
      TutorRequestPollingService._();
  factory TutorRequestPollingService() => _instance;

  final EducationFeesRepository _repository = EducationFeesRepository();
  final StreamController<TutorRequestEvent> _eventController =
      StreamController<TutorRequestEvent>.broadcast();

  Timer? _pollingTimer;
  bool _isPolling = false;
  bool _isPaused = false;

  /// Set of request references that have already been seen via polling.
  final Set<String> _seenRequestReferences = {};

  /// Polling interval in seconds. Default is 30 seconds.
  static const int _defaultPollingIntervalSeconds = 30;

  /// Start polling for new tutor requests.
  ///
  /// [intervalSeconds] - Polling interval in seconds (default: 30).
  /// This should be called when the app is in the foreground and push notifications
  /// are not working reliably.
  void startPolling({int intervalSeconds = _defaultPollingIntervalSeconds}) {
    if (_isPolling) {
      logger.info('Polling already active, skipping start');
      return;
    }

    logger.info('Starting tutor request polling (interval: ${intervalSeconds}s)');
    _isPolling = true;
    _isPaused = false;

    _pollingTimer = Timer.periodic(
      Duration(seconds: intervalSeconds),
      (_) => _pollForRequests(),
    );

    // Initial poll immediately
    _pollForRequests();
  }

  /// Stop polling for tutor requests.
  ///
  /// This should be called when the app goes to background or when push
  /// notifications are confirmed to be working.
  void stopPolling() {
    if (!_isPolling) {
      logger.info('Polling not active, skipping stop');
      return;
    }

    logger.info('Stopping tutor request polling');
    _isPolling = false;
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  /// Pause polling temporarily (e.g., when app goes to background).
  void pausePolling() {
    if (!_isPolling || _isPaused) {
      return;
    }

    logger.info('Pausing tutor request polling');
    _isPaused = true;
    _pollingTimer?.cancel();
  }

  /// Resume polling (e.g., when app returns to foreground).
  void resumePolling({int intervalSeconds = _defaultPollingIntervalSeconds}) {
    if (!_isPolling || !_isPaused) {
      return;
    }

    logger.info('Resuming tutor request polling');
    _isPaused = false;
    _pollingTimer = Timer.periodic(
      Duration(seconds: intervalSeconds),
      (_) => _pollForRequests(),
    );
  }

  /// Clear seen request references.
  ///
  /// This should be called on logout to prevent stale data.
  void clearSeenRequests() {
    _seenRequestReferences.clear();
    logger.info('Cleared seen request references from polling');
  }

  Future<void> _pollForRequests() async {
    if (_isPaused) return;

    try {
      logger.debug('Polling for pending tutor requests...');
      final response = await _repository.fetchTutorReceivedRequests(
        page: 1,
        perPage: 20,
        status: 'PENDING',
      );

      if (response.status && response.data != null) {
        final requests = response.data!.requests;
        _processNewRequests(requests);
      }
    } catch (e) {
      logger.error('Error polling for tutor requests: $e', error: e);
    }
  }

  void _processNewRequests(List<Map<String, dynamic>> requests) {
    for (final request in requests) {
      final requestReference =
          request['request_reference']?.toString() ?? '';

      if (requestReference.isEmpty) continue;

      // Check if this is a new request
      if (!_seenRequestReferences.contains(requestReference)) {
        _seenRequestReferences.add(requestReference);

        // Trigger notification for new request
        logger.info('New pending request found via polling: $requestReference');
        _eventController.add(
          TutorRequestEvent(
            requestReference: requestReference,
            messageId: 'polling_${DateTime.now().millisecondsSinceEpoch}',
          ),
        );
      }
    }
  }

  /// Check if polling is currently active.
  bool get isPolling => _isPolling;

  /// Check if polling is currently paused.
  bool get isPaused => _isPaused;
}
