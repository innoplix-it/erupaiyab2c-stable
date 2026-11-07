import '../../../constants/file_constants.dart';
import '../../../constants/routes_constant.dart';
import '../../educationFees/constants/tutor_notification_constants.dart';
import '../../educationFees/services/tutor_request_notification_service.dart';

class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.iconAsset,
    required this.section,
    this.iconUrl,
    this.showRemindButton = false,
    this.type,
    this.redirectScreen,
    this.referenceId,
    this.requestReference,
    this.requestId,
    this.requestStatus,
    this.isRead = false,
    this.createdAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      subtitle: (json['subtitle'] ?? '').toString(),
      actionLabel: (json['actionLabel'] ?? '').toString(),
      iconAsset: (json['iconAsset'] ?? '').toString(),
      section: (json['section'] ?? '').toString(),
    );
  }

  factory NotificationItem.fromApi(Map<String, dynamic> json) {
    return NotificationItem(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      subtitle: (json['message'] ?? '').toString(),
      actionLabel: _actionLabelFor(json),
      iconAsset: _iconFor(json),
      section: _sectionFor(json),
      iconUrl: (json['icon'] ?? '').toString(),
      showRemindButton: () {
        final raw = json['show_remind_button'];
        if (raw == true) return true;
        final normalized = (raw ?? '').toString().toLowerCase().trim();
        return normalized == 'true' || normalized == '1' || normalized == 'yes';
      }(),
      type: (json['type'] ?? '').toString(),
      redirectScreen: (json['redirect_screen'] ?? '').toString(),
      referenceId: (json['reference_id'] ?? '').toString(),
      requestReference: _requestReferenceFrom(json),
      requestId: _requestIdFrom(json),
      requestStatus: _requestStatusFrom(json),
      isRead: (json['is_read'] ?? '').toString() == '1',
      createdAt: _parseCreatedAt(json['created_at']?.toString()),
    );
  }

  static List<NotificationItem> fromJsonList(List<dynamic> items) {
    return items
        .whereType<Map<String, dynamic>>()
        .map(NotificationItem.fromJson)
        .toList();
  }

  final String id;
  final String title;
  final String subtitle;
  final String actionLabel;
  final String iconAsset;
  final String section;
  final String? iconUrl;
  final bool showRemindButton;
  final String? type;
  final String? redirectScreen;
  final String? referenceId;

  /// Education/tutor payment-request id from the notifications list API
  /// (`request_reference` / aliases). Distinct from [referenceId].
  final String? requestReference;

  /// Numeric education request DB id when the notifications API sends
  /// `request_id` (same field as send-request). Distinct from notification [id].
  final String? requestId;

  /// Education/tutor request status when the notifications API sends it
  /// (`PENDING`, `ACCEPTED`, `REJECTED`, ...). Not the list envelope flag.
  final String? requestStatus;
  final bool isRead;
  final DateTime? createdAt;

  String get _combinedText =>
      '${title.trim()} ${subtitle.trim()} ${(type ?? '').trim()} ${(redirectScreen ?? '').trim()}'
          .toLowerCase();

  static final RegExp _kycWord = RegExp(r'\bkyc\b');

  /// KYC when the backend `type` contains `kyc`, `redirect_screen` is an
  /// existing KYC route, or the title/message asks the user to complete KYC.
  /// "New Education Payment Request" has no KYC word, so it is not KYC.
  bool get isKycNotification {
    final typeValue = (type ?? '').trim().toLowerCase();
    if (typeValue.contains('kyc')) return true;
    final redirect = (redirectScreen ?? '').trim();
    if (redirect == RouteConstants.kycVerification ||
        redirect == RouteConstants.kycOverview ||
        redirect == RouteConstants.panVerification ||
        redirect == RouteConstants.aadhaarVerification) {
      return true;
    }
    final text = '${title.trim()} ${subtitle.trim()}'.toLowerCase();
    return _kycWord.hasMatch(text);
  }

  static final RegExp _educationPaymentRequestText = RegExp(
    r'education\s+payment\s+request|tuition\s+(fee\s+)?request',
  );

  /// Prefer a full `EDUTR...` (or other non-numeric) reference for the popup.
  /// Falls back to a numeric internal `request_id` so the tutor service can
  /// resolve it against received-requests `id` / `request_id`.
  String? get educationRequestReference {
    final candidates = <String>[
      if (_usableId(requestReference) != null) _usableId(requestReference)!,
      if (_usableId(referenceId) != null) _usableId(referenceId)!,
      if (_usableId(requestId) != null) _usableId(requestId)!,
    ];
    if (candidates.isEmpty) return null;
    for (final candidate in candidates) {
      if (!_looksLikeInternalRequestId(candidate)) return candidate;
    }
    return candidates.first;
  }

  /// Numeric DB request id when the Alerts payload only has that (e.g. `93`).
  String? get educationInternalRequestId {
    for (final candidate in [
      requestId,
      requestReference,
      if (_looksLikeEducationPaymentRequest) referenceId,
    ]) {
      final value = _usableId(candidate);
      if (value != null && _looksLikeInternalRequestId(value)) return value;
    }
    return null;
  }

  static bool _looksLikeInternalRequestId(String value) =>
      RegExp(r'^\d+$').hasMatch(value.trim());

  /// Education Payment Request cards that must open the existing tutor
  /// popup (same path as FCM), not Bill Details.
  bool get isEducationPaymentRequestNotification {
    if (isKycNotification) return false;
    final reference = educationRequestReference;
    if (reference == null) return false;
    return _looksLikeEducationPaymentRequest;
  }

  /// True when [requestStatus] is explicitly still `PENDING`.
  bool get isEducationPaymentRequestPending {
    if (!isEducationPaymentRequestNotification) return false;
    final status = (requestStatus ?? '').trim().toUpperCase();
    if (status.isEmpty) return false;
    return status == TutorNotificationConstants.statusPending;
  }

  /// True when [requestStatus] is present and no longer `PENDING`
  /// (e.g. `ACCEPTED` / `REJECTED`).
  bool get isEducationPaymentRequestCompleted {
    if (!isEducationPaymentRequestNotification) return false;
    final status = (requestStatus ?? '').trim().toUpperCase();
    if (status.isEmpty) return false;
    return status != TutorNotificationConstants.statusPending;
  }

  bool get _looksLikeEducationPaymentRequest {
    final typeValue = (type ?? '').trim().toLowerCase();
    if (typeValue.isNotEmpty) {
      if (TutorNotificationConstants.excludedTypes
          .any(typeValue.contains)) {
        return false;
      }
      // Check for underscore-separated type values first (e.g., "tutor_request")
      final parts = typeValue.split('_');
      if (parts.any((part) =>
          part == TutorNotificationConstants.typeTutor ||
          part == TutorNotificationConstants.typeTuition ||
          part == TutorNotificationConstants.typeEducation ||
          part == TutorNotificationConstants.typeRequest)) {
        return true;
      }
      // Check for substring matches
      if (typeValue.contains(TutorNotificationConstants.typeTutor) ||
          typeValue.contains(TutorNotificationConstants.typeTuition) ||
          typeValue.contains(TutorNotificationConstants.typeEducation) ||
          typeValue.contains(TutorNotificationConstants.typeRequest)) {
        return true;
      }
    }
    final text = '${title.trim()} ${subtitle.trim()}'.toLowerCase();
    return _educationPaymentRequestText.hasMatch(text);
  }

  static String? _usableId(String? raw) {
    final value = (raw ?? '').trim();
    if (value.isEmpty) return null;
    final lower = value.toLowerCase();
    if (lower == 'null' || lower == 'undefined' || value == '0') return null;
    return value;
  }

  static String? _requestReferenceFrom(Map<String, dynamic> json) {
    final direct = _usableId(
      (json['request_reference'] ??
              json['requestReference'] ??
              json['tutor_request_reference'])
          ?.toString(),
    );
    if (direct != null && !_looksLikeInternalRequestId(direct)) {
      return direct;
    }
    // Only dig EDUTR from human-readable text — not reference_id / other
    // identity fields (those are handled by [educationRequestReference]).
    final embedded = TutorRequestNotificationService.findEmbeddedEdutrReference({
      'message': json['message'],
      'title': json['title'],
      'body': json['body'],
      'subtitle': json['subtitle'],
    });
    if (embedded != null && embedded.isNotEmpty) return embedded;
    return direct;
  }

  static String? _requestIdFrom(Map<String, dynamic> json) {
    return _usableId((json['request_id'] ?? json['requestId'])?.toString());
  }

  static String? _requestStatusFrom(Map<String, dynamic> json) {
    final raw = json['request_status'] ?? json['status'];
    // List envelope uses boolean `status: true`; ignore that.
    if (raw == null || raw is bool) return null;
    final value = raw.toString().trim();
    if (value.isEmpty) return null;
    final lower = value.toLowerCase();
    if (lower == 'null' || lower == 'true' || lower == 'false') return null;
    return value;
  }

  bool get isBillPaymentSuccessNotification {
    final text = _combinedText;
    return (text.contains('bill payment successful') ||
            text.contains('payment successful') ||
            text.contains('payment success') ||
            text.contains('paid successfully')) &&
        !text.contains('reminder');
  }

  /// Successful, failed or pending bill payment updates, which open the
  /// matching transaction's details.
  bool get isBillPaymentStatusNotification {
    if ((redirectScreen ?? '').trim().toLowerCase() == 'bill_history') {
      return true;
    }
    if (isBillPaymentSuccessNotification) return true;
    final text = _combinedText;
    if (text.contains('reminder') || !text.contains('payment')) return false;
    return text.contains('fail') ||
        text.contains('pending') ||
        text.contains('processing');
  }

  static const Set<String> _transactionRedirects = {
    'bill_history',
    'transaction_history',
    'transactions',
    'transaction_detail',
    'transaction_details',
    'recharge_history',
    'payment_history',
  };

  /// Redirects that keep their own screen even when the text mentions a
  /// payment.
  static const Set<String> _nonTransactionRedirects = {
    'spin_screen',
    'app_update_screen',
    'wallet_history',
  };

  static final RegExp _transactionWords = RegExp(
    r'payment|paid|recharge|transaction|txn|refund|debited|purchase',
  );

  /// Outcome of a transaction, whatever the module calls it ("Tuition fee
  /// of ₹5000 successful", "LPG booking of ₹900 failed", ...).
  static final RegExp _statusWords = RegExp(
    r'\b(success\w*|fail\w*|unsuccessful|declined|pending|processing|'
    r'in process|completed|confirmed)\b',
  );

  static final RegExp _amount = RegExp(r'₹|\brs\.?\s*\d|\binr\b');

  /// Offers and promotions can mention payments without being one.
  static final RegExp _promotionalWords = RegExp(
    r'\b(offers?|cashback|coupons?|promo\w*|discount\w*|rewards?|win|won|'
    r'earn\w*|invite\w*|referral\w*)\b',
  );

  /// Status updates for a transaction from any module (bill payments,
  /// recharges, credit card, FASTag, DTH, education, rent, LPG, insurance,
  /// loans, digital gold, ...), which open that transaction's details.
  /// Reminders, Spin & Win, offers, app updates and wallet history keep
  /// their existing behaviour.
  bool get isTransactionNotification {
    if (isKycNotification) return false;
    if (isEducationPaymentRequestNotification) return false;
    final redirect = (redirectScreen ?? '').trim().toLowerCase();
    if (_transactionRedirects.contains(redirect)) return true;
    if (_nonTransactionRedirects.contains(redirect)) return false;
    if (isBillPaymentStatusNotification) return true;
    if (isBillReminderNotification) return false;
    final text = _combinedText;
    if (text.contains('spin') || _promotionalWords.hasMatch(text)) {
      return false;
    }
    if (_transactionWords.hasMatch(text)) return true;
    return _statusWords.hasMatch(text) && _amount.hasMatch(text);
  }

  /// Carries an id that may be a transaction even though the text does not
  /// say so (modules word their notifications differently). Such a
  /// notification opens the details only if the id matches a transaction,
  /// and otherwise keeps its existing behaviour.
  bool get mayReferToTransaction {
    if (isKycNotification) return false;
    if (isEducationPaymentRequestNotification) return false;
    if (transactionReferenceId == null) return false;
    final redirect = (redirectScreen ?? '').trim().toLowerCase();
    if (_nonTransactionRedirects.contains(redirect)) return false;
    if (isBillReminderNotification) return false;
    return !_combinedText.contains('spin');
  }

  /// [referenceId] when it is a usable transaction identifier.
  String? get transactionReferenceId {
    return _usableId(referenceId);
  }

  bool get isBillReminderNotification {
    if (isKycNotification) return false;
    if (isEducationPaymentRequestNotification) return false;
    if (isBillPaymentSuccessNotification) return false;
    final text = _combinedText;
    if (showRemindButton) return true;
    return text.contains('bill reminder') ||
        text.contains('due date') ||
        text.contains('due in') ||
        text.contains('remind');
  }

  static DateTime? _parseCreatedAt(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final normalized = raw.contains(' ') ? raw.replaceFirst(' ', 'T') : raw;
    return DateTime.tryParse(normalized);
  }

  static String _sectionFor(Map<String, dynamic> json) {
    final createdAt = _parseCreatedAt(json['created_at']?.toString());
    if (createdAt == null) return 'Today';
    final now = DateTime.now();
    if (createdAt.year == now.year &&
        createdAt.month == now.month &&
        createdAt.day == now.day) {
      return 'Today';
    }
    return 'Earlier';
  }

  static String _iconFor(Map<String, dynamic> json) {
    final title = (json['title'] ?? '').toString().toLowerCase();
    final message = (json['message'] ?? '').toString().toLowerCase();
    final combined = '$title $message';
    if (combined.contains('spin')) {
      return FileConstants.spincoin;
    }
    return FileConstants.erupaiyaLogo;
  }

  static String _actionLabelFor(Map<String, dynamic> json) {
    final title = (json['title'] ?? '').toString().toLowerCase();
    final message = (json['message'] ?? '').toString().toLowerCase();
    final combined = '$title $message';
    if (combined.contains('spin')) {
      return 'Play Now';
    }
    return 'View';
  }
}
