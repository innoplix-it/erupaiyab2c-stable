/// Constants for Tutor Request Notification flow.
///
/// Centralizes hardcoded strings used across notification handling,
/// background processing, and popup presentation to avoid duplication.
class TutorNotificationConstants {
  TutorNotificationConstants._();

  // Request status strings from API contract
  static const String statusPending = 'PENDING';
  static const String statusAccepted = 'ACCEPTED';
  static const String statusRejected = 'REJECTED';

  // Notification payload type identifiers
  static const String typeTutor = 'tutor';
  static const String typeTuition = 'tuition';
  static const String typeEducation = 'education';
  static const String typeRequest = 'request';

  // Excluded notification types (not tutor-related)
  static const List<String> excludedTypes = [
    'wallet',
    'kyc',
    'spin',
    'gold',
    'recharge',
    'bbps',
    'credit_card',
  ];

  // Retry limits and delays
  static const int navigatorRetryLimit = 40;
  static const int authRetryLimit = 30;
  static const Duration navigatorRetryDelay = Duration(milliseconds: 250);
  static const Duration authRetryDelay = Duration(milliseconds: 400);

  // Pagination defaults for startup/resume checks
  static const int defaultPage = 1;
  static const int defaultPerPage = 20;

  // Background processor timeouts
  static const Duration backgroundConnectTimeout = Duration(seconds: 15);
  static const Duration backgroundSendTimeout = Duration(seconds: 15);
  static const Duration backgroundReceiveTimeout = Duration(seconds: 30);
  static const String defaultTokenType = 'Bearer';
  static const String acceptHeader = 'application/json';
}
