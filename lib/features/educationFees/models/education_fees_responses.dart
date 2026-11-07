class EducationCreateOrderRequest {
  const EducationCreateOrderRequest({
    required this.recipientName,
    required this.accountNo,
    required this.ifsc,
    required this.amount,
    this.accountNoUnmasked,
  });

  final String recipientName;
  final String accountNo;
  final String ifsc;
  final double amount;
  final String? accountNoUnmasked;

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> map = {
      'recipient_name': recipientName,
      'account_no': accountNoUnmasked ?? accountNo,
      'ifsc': ifsc,
      'amount': double.parse(amount.toStringAsFixed(2)),
    };

    if (accountNoUnmasked != null && accountNoUnmasked!.isNotEmpty) {
      map['account_no_unmasked'] = accountNoUnmasked!;
      map['accountNoUnmasked'] = accountNoUnmasked!;
    }

    return map;
  }
}

class EducationValidateAmountResponse {
  const EducationValidateAmountResponse({
    required this.status,
    this.message,
    this.minAmount,
    this.maxAmount,
    this.limitHint,
  });

  factory EducationValidateAmountResponse.fromJson(Map<String, dynamic> json) {
    String? message;
    final messages = json['messages'];
    if (messages is Map && messages['error'] is String) {
      message = messages['error'] as String;
    } else {
      message = json['message'] as String?;
    }
    num? readAmount(Object? raw) {
      if (raw is num) return raw;
      return num.tryParse(raw?.toString() ?? '');
    }

    double? pickAmount(Map<dynamic, dynamic> map, List<String> keys) {
      for (final key in keys) {
        if (!map.containsKey(key)) continue;
        final value = readAmount(map[key]);
        if (value != null) return value.toDouble();
      }
      return null;
    }

    const minKeys = [
      'min_amount',
      'minAmount',
      'minimum_amount',
      'minimumAmount',
      'min_limit',
      'minLimit',
    ];
    const maxKeys = [
      'max_amount',
      'maxAmount',
      'maximum_amount',
      'maximumAmount',
      'max_limit',
      'maxLimit',
    ];

    double? minAmount;
    double? maxAmount;
    String? limitHint;
    final data = json['data'];
    if (data is Map) {
      minAmount = pickAmount(data, minKeys);
      maxAmount = pickAmount(data, maxKeys);
      final limits = data['limits'] ?? data['amount_limits'];
      if (limits is Map) {
        minAmount ??= pickAmount(limits, minKeys);
        maxAmount ??= pickAmount(limits, maxKeys);
      }
      final hint = data['limit_text'] ??
          data['limitText'] ??
          data['amount_hint'] ??
          data['amountHint'] ??
          data['hint'];
      if (hint is String && hint.trim().isNotEmpty) {
        limitHint = hint.trim();
      }
    }
    minAmount ??= pickAmount(json, minKeys);
    maxAmount ??= pickAmount(json, maxKeys);
    limitHint ??= () {
      final hint = json['limit_text'] ?? json['limitText'] ?? json['hint'];
      if (hint is String && hint.trim().isNotEmpty) return hint.trim();
      return null;
    }();

    return EducationValidateAmountResponse(
      status: json['status'] == true,
      message: message,
      minAmount: minAmount,
      maxAmount: maxAmount,
      limitHint: limitHint,
    );
  }

  final bool status;
  final String? message;
  final double? minAmount;
  final double? maxAmount;

  /// Backend caption for the min/max line. Display only — not a client rule.
  final String? limitHint;
}

class EducationCheckMobileResponse {
  const EducationCheckMobileResponse({
    required this.status,
    required this.exists,
    this.data,
    this.message,
  });

  factory EducationCheckMobileResponse.fromJson(Map<String, dynamic> json) {
    String? message;
    final messages = json['messages'];
    if (messages is Map && messages['error'] is String) {
      message = messages['error'] as String;
    } else {
      message = json['message'] as String?;
    }
    return EducationCheckMobileResponse(
      status: json['status'] == true,
      exists: json['exists'] == true,
      data: json['data'],
      message: message,
    );
  }

  final bool status;
  final bool exists;
  final Object? data;
  final String? message;

  /// Add Tutor registration gate for `POST /api/education/check-mobile`.
  ///
  /// The mobile client treats `exists == true` together with `status == true` as
  /// confirmation that the number belongs to a registered eRupaiya user. If backend
  /// semantics differ, update this helper and the controller together.
  bool get confirmsRegisteredUser => status && exists;
}

/// Tutor verification outcomes of `POST /api/education/tutor/verify`.
///
/// `unknown` is the fail-closed default for a missing, malformed or newly added
/// backend status string, so the client never guesses a verification result.
enum EducationTutorVerificationStatus {
  verified,
  notVerified,
  notFound,
  unknown,
}

class EducationTutorVerifyResponse {
  const EducationTutorVerifyResponse({
    required this.status,
    required this.verificationStatus,
    this.message,
  });

  factory EducationTutorVerifyResponse.fromJson(Map<String, dynamic> json) {
    String? message;
    final messages = json['messages'];
    if (messages is Map && messages['error'] is String) {
      message = messages['error'] as String;
    } else {
      message = json['message'] as String?;
    }
    return EducationTutorVerifyResponse(
      status: json['status'] == true,
      verificationStatus: _readTutorVerificationStatus(
        json['verification_status'],
      ),
      message: message,
    );
  }

  final bool status;

  /// The actual tutor verification result. `status == true` only means the API
  /// call itself succeeded, so this field alone decides the tutor's outcome.
  final EducationTutorVerificationStatus verificationStatus;
  final String? message;

  bool get isVerified =>
      verificationStatus == EducationTutorVerificationStatus.verified;
  bool get isNotVerified =>
      verificationStatus == EducationTutorVerificationStatus.notVerified;
  bool get isNotFound =>
      verificationStatus == EducationTutorVerificationStatus.notFound;
  bool get hasKnownVerificationStatus =>
      verificationStatus != EducationTutorVerificationStatus.unknown;

  /// Convenience gate for callers: the request succeeded and the tutor is
  /// fully verified (KYC complete). NOT_VERIFIED and NOT_FOUND both return
  /// false here and must be distinguished through [verificationStatus].
  bool get confirmsVerifiedTutor => status && isVerified;
}

EducationTutorVerificationStatus _readTutorVerificationStatus(Object? raw) {
  final value = raw?.toString().trim().toUpperCase();
  switch (value) {
    case 'VERIFIED':
      return EducationTutorVerificationStatus.verified;
    case 'NOT_VERIFIED':
      return EducationTutorVerificationStatus.notVerified;
    case 'NOT_FOUND':
      return EducationTutorVerificationStatus.notFound;
    default:
      return EducationTutorVerificationStatus.unknown;
  }
}

class EducationTutorDetailsRequest {
  const EducationTutorDetailsRequest({
    required this.mobile,
    required this.amount,
  });

  final String mobile;
  final int amount;

  Map<String, dynamic> toJson() {
    return {
      'mobile': mobile,
      'amount': amount,
    };
  }
}

class EducationTutorDetailsData {
  const EducationTutorDetailsData({
    required this.tutorId,
    required this.tutorName,
    required this.bankName,
    required this.accountNumber,
    required this.accountHolderName,
    required this.ifsc,
    required this.bankLogo,
    required this.amount,
    this.pan,
    this.panMasked,
    this.branch,
    this.accountMasked,
    this.accountNoUnmasked,
  });

  factory EducationTutorDetailsData.fromJson(Map<String, dynamic> json) {
    final rawAccountNumber = _optionalText(json['account_number']);
    final rawAccountNo = _optionalText(json['account_no'] ?? json['accountNo']);
    final rawUnmasked = _optionalText(json['account_no_unmasked']);
    final displayedAccount = rawAccountNumber ?? rawAccountNo ?? rawUnmasked ?? '';
    // A masked account_number must not hide a complete account_no that the
    // same payload already contains. Nothing is rebuilt from the mask.
    final completeAccount = rawUnmasked ??
        ((rawAccountNumber != null &&
                _accountLooksMasked(rawAccountNumber) &&
                rawAccountNo != null &&
                !_accountLooksMasked(rawAccountNo))
            ? rawAccountNo
            : null);
    return EducationTutorDetailsData(
      tutorId: _asInt(json['tutor_id']),
      tutorName: _firstText(json, const ['tutor_name', 'name']),
      bankName: _firstText(json, const ['bank_name', 'bank']),
      accountNumber: displayedAccount,
      accountHolderName: _firstText(
        json,
        const ['account_holder_name', 'account_holder', 'holder_name'],
      ),
      ifsc: _firstText(json, const ['ifsc', 'ifsc_code', 'ifscCode']),
      bankLogo: _optionalText(json['bank_logo']),
      amount: _asInt(json['amount']),
      pan: _optionalText(json['pan'] ?? json['pan_number']),
      panMasked: _optionalText(json['pan_masked']),
      branch: _optionalText(json['branch'] ?? json['branch_name']),
      accountMasked: _optionalText(
        json['account_masked'] ?? json['masked_account'],
      ),
      accountNoUnmasked: completeAccount,
    );
  }

  final int tutorId;
  final String tutorName;
  final String bankName;
  final String accountNumber;
  final String accountHolderName;
  final String ifsc;
  final String? bankLogo;
  final int amount;
  final String? pan;
  final String? panMasked;
  final String? branch;
  final String? accountMasked;

  /// Complete account number when the details payload includes
  /// `account_no_unmasked`. Never derived from a masked `account_number`.
  final String? accountNoUnmasked;
}

bool _accountLooksMasked(String value) => RegExp(r'[xX*]').hasMatch(value);

/// Full account from a saved tutor. A masked `account_no_unmasked` is ignored
/// and is not rebuilt from `account_masked`.
String? _completeBeneficiaryAccount(Map<String, dynamic> json) {
  for (final key in const ['account_no_unmasked', 'account_no', 'accountNo']) {
    final text = _optionalText(json[key]);
    if (text == null || _accountLooksMasked(text)) continue;
    return text;
  }
  return null;
}

String? _optionalText(Object? value) {
  final text = value?.toString().trim() ?? '';
  if (text.isEmpty || text.toLowerCase() == 'null') return null;
  return text;
}

String _firstText(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final text = _optionalText(json[key]);
    if (text != null) return text;
  }
  return '';
}

int _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value?.toString().trim() ?? '') ?? 0;
}

class EducationTutorDetailsResponse {
  const EducationTutorDetailsResponse({
    required this.status,
    required this.verificationStatus,
    this.message,
    this.data,
  });

  factory EducationTutorDetailsResponse.fromJson(Map<String, dynamic> json) {
    String? message;
    final messages = json['messages'];
    if (messages is Map && messages['error'] is String) {
      message = messages['error'] as String;
    } else {
      message = json['message'] as String?;
    }

    final dataJson = json['data'];
    EducationTutorDetailsData? data;
    if (dataJson is Map) {
      data = EducationTutorDetailsData.fromJson(
        Map<String, dynamic>.from(dataJson),
      );
    }

    return EducationTutorDetailsResponse(
      status: json['status'] == true,
      verificationStatus: _readTutorVerificationStatus(
        json['verification_status'],
      ),
      message: message,
      data: data,
    );
  }

  final bool status;
  final EducationTutorVerificationStatus verificationStatus;
  final String? message;
  final EducationTutorDetailsData? data;

  bool get isVerified =>
      verificationStatus == EducationTutorVerificationStatus.verified;
  bool get isNotVerified =>
      verificationStatus == EducationTutorVerificationStatus.notVerified;
  bool get isNotFound =>
      verificationStatus == EducationTutorVerificationStatus.notFound;
  bool get hasKnownVerificationStatus =>
      verificationStatus != EducationTutorVerificationStatus.unknown;

  /// Convenience gate for callers: the request succeeded and the tutor is
  /// fully verified (KYC complete). NOT_VERIFIED and NOT_FOUND both return
  /// false here and must be distinguished through [verificationStatus].
  bool get confirmsVerifiedTutor => status && isVerified;
}

class EducationTutorSendRequestRequest {
  const EducationTutorSendRequestRequest({
    required this.mobile,
    required this.amount,
    required this.subject,
  });

  final String mobile;
  final int amount;
  final String subject;

  Map<String, dynamic> toJson() {
    return {
      'mobile': mobile,
      'amount': amount,
      'subject': subject,
    };
  }
}

class EducationTutorSendRequestData {
  const EducationTutorSendRequestData({
    required this.requestId,
    required this.requestReference,
    required this.tutorId,
    required this.amount,
    required this.requestStatus,
    required this.createdAt,
  });

  factory EducationTutorSendRequestData.fromJson(Map<String, dynamic> json) {
    return EducationTutorSendRequestData(
      requestId: json['request_id'] as int? ?? 0,
      requestReference: json['request_reference']?.toString() ?? '',
      tutorId: json['tutor_id'] as int? ?? 0,
      amount: json['amount']?.toString() ?? '0',
      requestStatus: json['request_status']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
    );
  }

  final int requestId;
  final String requestReference;
  final int tutorId;
  final String amount;
  final String requestStatus;
  final String createdAt;
}

class EducationTutorSendRequestResponse {
  const EducationTutorSendRequestResponse({
    required this.status,
    this.message,
    this.data,
  });

  factory EducationTutorSendRequestResponse.fromJson(
      Map<String, dynamic> json) {
    String? message;
    final messages = json['messages'];
    if (messages is Map && messages['error'] is String) {
      message = messages['error'] as String;
    } else {
      message = json['message'] as String?;
    }

    final dataJson = json['data'];
    EducationTutorSendRequestData? data;
    if (dataJson is Map<String, dynamic>) {
      data = EducationTutorSendRequestData.fromJson(dataJson);
    }

    return EducationTutorSendRequestResponse(
      status: json['status'] == true,
      message: message,
      data: data,
    );
  }

  final bool status;
  final String? message;
  final EducationTutorSendRequestData? data;
}

class EducationTutorAskKycRequest {
  const EducationTutorAskKycRequest({
    this.requestReference,
    this.mobile,
  });

  /// Tutor payment request reference. This is the only ask-kyc field.
  final String? requestReference;

  /// Unused by the request body. Kept so existing callers still compile.
  final String? mobile;

  Map<String, dynamic> toJson() {
    final reference = requestReference?.trim() ?? '';
    return {
      'request_reference': reference,
    };
  }
}

class EducationTutorAskKycData {
  const EducationTutorAskKycData({
    required this.requestReference,
    required this.notificationSentTo,
  });

  factory EducationTutorAskKycData.fromJson(Map<String, dynamic> json) {
    return EducationTutorAskKycData(
      requestReference: json['request_reference']?.toString().trim() ?? '',
      notificationSentTo: _asInt(json['notification_sent_to']),
    );
  }

  final String requestReference;
  final int notificationSentTo;
}

class EducationTutorAskKycResponse {
  const EducationTutorAskKycResponse({
    required this.status,
    this.message,
    this.data,
  });

  factory EducationTutorAskKycResponse.fromJson(Map<String, dynamic> json) {
    String? message;
    final messages = json['messages'];
    if (messages is Map && messages['error'] is String) {
      message = messages['error'] as String;
    } else {
      message = json['message'] as String?;
    }

    final dataJson = json['data'];
    EducationTutorAskKycData? data;
    if (dataJson is Map) {
      data = EducationTutorAskKycData.fromJson(
        Map<String, dynamic>.from(dataJson),
      );
    }

    return EducationTutorAskKycResponse(
      status: json['status'] == true,
      message: message,
      data: data,
    );
  }

  final bool status;
  final String? message;
  final EducationTutorAskKycData? data;
}

class EducationTutorRequestStatusData {
  const EducationTutorRequestStatusData({
    required this.requestReference,
    required this.amount,
    required this.subject,
    required this.requestStatus,
    required this.isAccepted,
    required this.isRejected,
    required this.isPending,
    required this.rejectionReason,
    required this.createdAt,
    required this.respondedAt,
    this.requesterUserId = '',
    this.requesterName = '',
  });

  factory EducationTutorRequestStatusData.fromJson(Map<String, dynamic> json) {
    // Live request-status bodies use `status: "PENDING"`. Older bodies use
    // `request_status`. A boolean envelope flag is not a request status.
    final explicit = json['request_status']?.toString().trim() ?? '';
    final requestStatus = explicit.isNotEmpty
        ? explicit
        : (_tutorRequestStatusText(json['status']) ?? '');
    final statusUpper = requestStatus.trim().toUpperCase();
    final isAccepted = _tutorStatusAsBool(json['is_accepted']);
    final isRejected = _tutorStatusAsBool(json['is_rejected']);
    // Some backends omit boolean flags or send "1"/"true". Prefer the flag when
    // present; otherwise derive PENDING from request_status.
    final isPending = json.containsKey('is_pending')
        ? _tutorStatusAsBool(json['is_pending'])
        : statusUpper == 'PENDING' && !isAccepted && !isRejected;
    return EducationTutorRequestStatusData(
      requestReference: json['request_reference']?.toString() ?? '',
      amount: json['amount']?.toString().trim() ?? '',
      subject: _deepFirstText(json, const [
        'fee_type',
        'subject',
        'purpose',
      ]),
      requesterUserId: json['requester_user_id']?.toString().trim() ?? '',
      requesterName: _senderDisplayName(json),
      requestStatus: requestStatus,
      isAccepted: isAccepted,
      isRejected: isRejected,
      isPending: isPending,
      rejectionReason: json['rejection_reason']?.toString(),
      createdAt: json['created_at']?.toString() ?? '',
      respondedAt: json['responded_at']?.toString(),
    );
  }

  final String requestReference;
  final String amount;
  final String subject;
  final String requestStatus;
  final bool isAccepted;
  final bool isRejected;
  final bool isPending;
  final String? rejectionReason;
  final String createdAt;
  final String? respondedAt;

  /// Sender id from the status payload. Not a display name.
  final String requesterUserId;

  /// Present only when the payload includes the requester's name.
  final String requesterName;
}

/// Name of the person who called send-request. `tutor_name` is the tutor,
/// so it is only used when the payload has no sender name.
String _senderDisplayName(Map<String, dynamic> json) {
  final direct = _deepFirstText(json, _senderNameKeys);
  if (direct.isNotEmpty) return direct;
  for (final key in _senderObjectKeys) {
    final nested = json[key];
    if (nested is! Map) continue;
    final name = _firstNonEmptyText(
      Map<String, dynamic>.from(nested),
      const ['name', 'full_name', 'requester_name', 'sender_name'],
    );
    if (name.isNotEmpty) return name;
  }
  return _deepFirstText(json, const ['tutor_name']);
}

String _firstNonEmptyText(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key]?.toString().trim() ?? '';
    if (value.isNotEmpty && value.toLowerCase() != 'null') return value;
  }
  return '';
}

/// Reads [keys] on this object, then inside nested objects. Lists named
/// `requests` are skipped so one request does not borrow another request's name.
String _deepFirstText(Object? node, List<String> keys, {int depth = 0}) {
  if (node is! Map || depth > 4) return '';
  final map = Map<String, dynamic>.from(node);
  final direct = _firstNonEmptyText(map, keys);
  if (direct.isNotEmpty) return direct;
  for (final entry in map.entries) {
    if (entry.key == 'requests' || entry.key == 'pagination') continue;
    final nested = _deepFirstText(entry.value, keys, depth: depth + 1);
    if (nested.isNotEmpty) return nested;
  }
  return '';
}

class EducationTutorRequestStatusResponse {
  const EducationTutorRequestStatusResponse({
    required this.status,
    this.message,
    this.data,
  });

  factory EducationTutorRequestStatusResponse.fromJson(
      Map<String, dynamic> json) {
    String? message;
    final messages = json['messages'];
    if (messages is Map && messages['error'] is String) {
      message = messages['error'] as String;
    } else {
      message = json['message'] as String?;
    }

    final dataJson = json['data'];
    EducationTutorRequestStatusData? data;
    var bodyIsRequest = false;
    // Dio/json may yield Map<dynamic, dynamic>; require a Map, then normalize.
    if (dataJson is Map) {
      data = EducationTutorRequestStatusData.fromJson(
        Map<String, dynamic>.from(dataJson),
      );
    } else if ((json['request_reference']?.toString().trim().isNotEmpty ??
        false)) {
      // The request object is the body itself:
      // {request_reference, requester_user_id, amount, status: "PENDING"}.
      bodyIsRequest = true;
      data = EducationTutorRequestStatusData.fromJson(
        Map<String, dynamic>.from(json),
      );
    }

    final envelopeOk = bodyIsRequest
        ? data != null && data.requestStatus.isNotEmpty
        : _tutorStatusAsBool(json['status']);

    return EducationTutorRequestStatusResponse(
      status: envelopeOk,
      message: message,
      data: data,
    );
  }

  final bool status;
  final String? message;
  final EducationTutorRequestStatusData? data;
}

/// Request-status text such as PENDING. Boolean envelope values are ignored.
String? _tutorRequestStatusText(dynamic value) {
  if (value is! String) return null;
  final trimmed = value.trim();
  if (trimmed.isEmpty) return null;
  switch (trimmed.toLowerCase()) {
    case 'true':
    case 'false':
    case '1':
    case '0':
    case 'yes':
    case 'no':
      return null;
    default:
      return trimmed;
  }
}

bool _tutorStatusAsBool(dynamic value) {
  if (value == true || value == 1) return true;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    return normalized == 'true' || normalized == '1' || normalized == 'yes';
  }
  return false;
}

class EducationTutorReceivedRequestsPagination {
  const EducationTutorReceivedRequestsPagination({
    required this.page,
    required this.perPage,
    required this.total,
    required this.totalPages,
  });

  factory EducationTutorReceivedRequestsPagination.fromJson(
    Map<String, dynamic> json,
  ) {
    return EducationTutorReceivedRequestsPagination(
      page: json['page'] as int? ?? 1,
      perPage: json['per_page'] as int? ?? 20,
      total: json['total'] as int? ?? 0,
      totalPages: json['total_pages'] as int? ?? 0,
    );
  }

  final int page;
  final int perPage;
  final int total;
  final int totalPages;
}

class EducationTutorReceivedRequestsData {
  const EducationTutorReceivedRequestsData({
    required this.requests,
    required this.pagination,
  });

  factory EducationTutorReceivedRequestsData.fromJson(
      Map<String, dynamic> json) {
    final requestsJson = json['requests'];
    final requests = <Map<String, dynamic>>[];
    if (requestsJson is List) {
      for (final raw in requestsJson) {
        if (raw is! Map) continue;
        final request = Map<String, dynamic>.from(raw);
        _stampReceiverDisplayFields(request, json);
        requests.add(request);
      }
    }

    final paginationJson = json['pagination'];
    EducationTutorReceivedRequestsPagination? pagination;
    if (paginationJson is Map<String, dynamic>) {
      pagination =
          EducationTutorReceivedRequestsPagination.fromJson(paginationJson);
    }

    return EducationTutorReceivedRequestsData(
      requests: requests,
      pagination: pagination,
    );
  }

  final List<Map<String, dynamic>> requests;
  final EducationTutorReceivedRequestsPagination? pagination;
}

const _senderNameKeys = [
  'requester_name',
  'requesterName',
  'sender_name',
  'student_name',
  'parent_name',
];

const _senderObjectKeys = [
  'requester',
  'sender',
  'user',
  'student',
  'parent',
];

const _receiverFeeKeys = [
  'fee_type',
  'subject',
  'purpose',
];

void _stampReceiverDisplayFields(
  Map<String, dynamic> request,
  Map<String, dynamic> parent,
) {
  final name = _senderDisplayName(request);
  final parentName = name.isNotEmpty ? '' : _senderDisplayName(parent);
  final resolvedName = name.isNotEmpty ? name : parentName;
  if (resolvedName.isNotEmpty &&
      (request['requester_name']?.toString().trim().isEmpty ?? true)) {
    request['requester_name'] = resolvedName;
  }

  final fee = _deepFirstText(request, _receiverFeeKeys);
  final parentFee = fee.isNotEmpty ? '' : _deepFirstText(parent, _receiverFeeKeys);
  final resolvedFee = fee.isNotEmpty ? fee : parentFee;
  if (resolvedFee.isNotEmpty &&
      (request['fee_type']?.toString().trim().isEmpty ?? true)) {
    request['fee_type'] = resolvedFee;
  }
}

class EducationTutorReceivedRequestsResponse {
  const EducationTutorReceivedRequestsResponse({
    required this.status,
    this.message,
    this.data,
  });

  factory EducationTutorReceivedRequestsResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    String? message;
    final messages = json['messages'];
    if (messages is Map && messages['error'] is String) {
      message = messages['error'] as String;
    } else {
      message = json['message'] as String?;
    }

    final dataJson = json['data'];
    EducationTutorReceivedRequestsData? data;
    if (dataJson is Map<String, dynamic>) {
      data = EducationTutorReceivedRequestsData.fromJson(dataJson);
    }

    return EducationTutorReceivedRequestsResponse(
      status: json['status'] == true,
      message: message,
      data: data,
    );
  }

  final bool status;
  final String? message;
  final EducationTutorReceivedRequestsData? data;
}

class EducationTutorRespondToRequestRequest {
  const EducationTutorRespondToRequestRequest({
    required this.requestReference,
    required this.action,
  });

  final String requestReference;
  final String action;

  Map<String, dynamic> toJson() {
    return {
      'request_reference': requestReference,
      'action': action,
    };
  }
}

class EducationTutorRespondToRequestData {
  const EducationTutorRespondToRequestData({
    required this.requestReference,
    required this.amount,
    required this.requestStatus,
    required this.respondedAt,
  });

  factory EducationTutorRespondToRequestData.fromJson(
      Map<String, dynamic> json) {
    return EducationTutorRespondToRequestData(
      requestReference: json['request_reference']?.toString() ?? '',
      amount: json['amount']?.toString() ?? '0',
      requestStatus: json['request_status']?.toString() ?? '',
      respondedAt: json['responded_at']?.toString(),
    );
  }

  final String requestReference;
  final String amount;
  final String requestStatus;
  final String? respondedAt;
}

class EducationTutorRespondToRequestResponse {
  const EducationTutorRespondToRequestResponse({
    required this.status,
    this.message,
    this.data,
    this.requestStatus,
  });

  factory EducationTutorRespondToRequestResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    String? message;
    final messages = json['messages'];
    if (messages is Map && messages['error'] is String) {
      message = messages['error'] as String;
    } else {
      message = json['message'] as String?;
    }

    final dataJson = json['data'];
    EducationTutorRespondToRequestData? data;
    if (dataJson is Map<String, dynamic>) {
      data = EducationTutorRespondToRequestData.fromJson(dataJson);
    }

    final requestStatus = json['request_status']?.toString();

    return EducationTutorRespondToRequestResponse(
      status: json['status'] == true,
      message: message,
      data: data,
      requestStatus: requestStatus,
    );
  }

  final bool status;
  final String? message;
  final EducationTutorRespondToRequestData? data;
  final String? requestStatus;
}

class EducationTutorVerifyPanRequest {
  const EducationTutorVerifyPanRequest({required this.pan});

  final String pan;

  Map<String, dynamic> toJson() {
    return {
      'pan': pan,
    };
  }
}

class EducationTutorVerifyPanData {
  const EducationTutorVerifyPanData({
    required this.recipientReference,
    required this.beneficiaryId,
    required this.name,
    required this.panMasked,
    required this.panVerified,
  });

  factory EducationTutorVerifyPanData.fromJson(Map<String, dynamic> json) {
    return EducationTutorVerifyPanData(
      recipientReference: json['recipient_reference']?.toString() ?? '',
      beneficiaryId: json['beneficiary_id'] as int?,
      name: json['name']?.toString() ?? '',
      panMasked: json['pan_masked']?.toString() ?? '',
      panVerified: json['pan_verified'] == true,
    );
  }

  final String recipientReference;
  final int? beneficiaryId;
  final String name;
  final String panMasked;
  final bool panVerified;
}

class EducationTutorVerifyPanResponse {
  const EducationTutorVerifyPanResponse({
    required this.status,
    this.message,
    this.data,
  });

  factory EducationTutorVerifyPanResponse.fromJson(Map<String, dynamic> json) {
    String? message;
    final messages = json['messages'];
    if (messages is Map && messages['error'] is String) {
      message = messages['error'] as String;
    } else {
      message = json['message'] as String?;
    }

    final dataJson = json['data'];
    EducationTutorVerifyPanData? data;
    if (dataJson is Map<String, dynamic>) {
      data = EducationTutorVerifyPanData.fromJson(dataJson);
    }

    return EducationTutorVerifyPanResponse(
      status: json['status'] == true,
      message: message,
      data: data,
    );
  }

  final bool status;
  final String? message;
  final EducationTutorVerifyPanData? data;

  /// Business success requires the backend status flag and a verified payload.
  bool get confirmsVerifiedPan => status && data != null && data!.panVerified;
}

/// Request for `POST /api/education/tutor/recipient/verify-bank`.
///
/// The [recipientReference] is the exact value stored by a successful tutor
/// PAN verification; it is never hardcoded, reconstructed or replaced by the
/// beneficiary id. Account number and IFSC come live from the Add Details
/// form fields.
class EducationTutorVerifyBankRequest {
  const EducationTutorVerifyBankRequest({
    required this.recipientReference,
    required this.accountNo,
    required this.ifsc,
  });

  final String recipientReference;
  final String accountNo;
  final String ifsc;

  Map<String, dynamic> toJson() {
    return {
      'recipient_reference': recipientReference,
      'account_no': accountNo,
      'ifsc': ifsc,
    };
  }
}

/// Backend ids arrive as ints, JSON numbers, or numeric strings. A bad value
/// stays null instead of throwing away the rest of a successful payload.
int? _educationJsonInt(Object? value) {
  if (value is int) return value;
  if (value is num) {
    if (value.isNaN || value.isInfinite) return null;
    return value.toInt();
  }
  if (value is String) return int.tryParse(value.trim());
  return null;
}

/// `true`, `1`, and `"true"` / `"1"` / `"yes"` all count as verified.
bool _educationJsonBool(Object? value) {
  if (value is bool) return value;
  if (value is num) return value == 1;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    return normalized == 'true' || normalized == '1' || normalized == 'yes';
  }
  return false;
}

/// Nested `data` payload of the tutor recipient bank verification.
///
/// [accountNumber] is the backend-masked account number and is preserved
/// exactly as returned — the client never re-masks or fabricates it.
/// [recipientReference] is echoed back for the next tutor recipient step and
/// must stay the same value that was sent.
class EducationTutorVerifyBankData {
  const EducationTutorVerifyBankData({
    required this.recipientReference,
    required this.beneficiaryId,
    required this.name,
    required this.accountNumber,
    required this.ifsc,
    required this.transactionReference,
    required this.bankVerified,
  });

  factory EducationTutorVerifyBankData.fromJson(Map<String, dynamic> json) {
    return EducationTutorVerifyBankData(
      recipientReference: json['recipient_reference']?.toString() ?? '',
      beneficiaryId: _educationJsonInt(json['beneficiary_id']),
      name: json['name']?.toString() ?? '',
      accountNumber: json['account_number']?.toString() ?? '',
      ifsc: json['ifsc']?.toString() ?? '',
      // Ids often arrive as strings or JSON numbers. A strict `as int?`
      // throws and discards an otherwise successful verification.
      transactionReference: _educationJsonInt(json['transaction_reference']),
      bankVerified: _educationJsonBool(json['bank_verified']),
    );
  }

  final String recipientReference;
  final int? beneficiaryId;
  final String name;

  /// Masked account number exactly as the backend returned it.
  final String accountNumber;
  final String ifsc;

  /// Numeric transaction reference of the backend verification, matching the
  /// project convention of keeping backend ids as nullable ints.
  final int? transactionReference;
  final bool bankVerified;
}

class EducationTutorVerifyBankResponse {
  const EducationTutorVerifyBankResponse({
    required this.status,
    this.message,
    this.data,
  });

  factory EducationTutorVerifyBankResponse.fromJson(Map<String, dynamic> json) {
    String? message;
    final messages = json['messages'];
    if (messages is Map && messages['error'] is String) {
      message = messages['error'] as String;
    } else {
      message = json['message'] as String?;
    }

    final dataJson = json['data'];
    EducationTutorVerifyBankData? data;
    if (dataJson is Map) {
      data = EducationTutorVerifyBankData.fromJson(
        Map<String, dynamic>.from(dataJson),
      );
    }

    return EducationTutorVerifyBankResponse(
      status: _educationJsonBool(json['status']) ||
          (json['status'] is String &&
              (json['status'] as String).toUpperCase() == 'SUCCESS'),
      message: message,
      data: data,
    );
  }

  final bool status;
  final String? message;

  /// Nullable by contract: a `status: true` envelope without usable `data`
  /// is an invalid response, not a verified bank account.
  final EducationTutorVerifyBankData? data;

  /// Business success requires the backend status flag and a verified payload.
  bool get confirmsVerifiedBank => status && data != null && data!.bankVerified;
}

class EducationVerifyPanResponse {
  const EducationVerifyPanResponse({
    required this.status,
    this.message,
  });

  factory EducationVerifyPanResponse.fromJson(Map<String, dynamic> json) {
    String? message;
    final messages = json['messages'];
    if (messages is Map && messages['error'] is String) {
      message = messages['error'] as String;
    } else {
      message = json['message'] as String?;
    }
    return EducationVerifyPanResponse(
      status: json['status'] == true,
      message: message,
    );
  }

  final bool status;
  final String? message;
}

class EducationVerifyBankResponse {
  const EducationVerifyBankResponse({
    required this.status,
    this.bankAccountId,
    this.message,
  });

  factory EducationVerifyBankResponse.fromJson(Map<String, dynamic> json) {
    final rawStatus = json['status'];
    final status = rawStatus == true ||
        (rawStatus is String && rawStatus.toUpperCase() == 'SUCCESS');
    return EducationVerifyBankResponse(
      status: status,
      bankAccountId: json['bank_account_id'] as int?,
      message: json['message'] as String?,
    );
  }

  final bool status;
  final int? bankAccountId;
  final String? message;
}

class EducationPaymentSummaryData {
  const EducationPaymentSummaryData({
    required this.amount,
    required this.serviceCharge,
    required this.gstRate,
    required this.gstOnServiceCharge,
    required this.walletBalance,
    required this.walletUsed,
    required this.totalPayable,
  });

  factory EducationPaymentSummaryData.fromJson(Map<String, dynamic> json) {
    double toDouble(Object? value) {
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? 0.0;
    }

    return EducationPaymentSummaryData(
      amount: toDouble(json['amount']),
      serviceCharge: toDouble(json['service_charge']),
      gstRate: toDouble(json['gst_rate']),
      gstOnServiceCharge: toDouble(json['gst_on_service_charge']),
      walletBalance: toDouble(json['wallet_balance']),
      walletUsed: toDouble(json['wallet_used']),
      totalPayable: toDouble(
        json['total_payable'] ?? json['payable_amount'],
      ),
    );
  }

  final double amount;
  final double serviceCharge;
  final double gstRate;
  final double gstOnServiceCharge;
  final double walletBalance;
  final double walletUsed;
  final double totalPayable;

  double get payableAmount => totalPayable;
}

class EducationPaymentSummaryResponse {
  const EducationPaymentSummaryResponse({
    required this.status,
    this.data,
    this.message,
  });

  factory EducationPaymentSummaryResponse.fromJson(Map<String, dynamic> json) {
    String? message;
    final messages = json['messages'];
    if (messages is Map && messages['error'] is String) {
      message = messages['error'] as String;
    } else {
      message = json['message'] as String?;
    }
    final data = json['data'];
    Map<String, dynamic>? summaryData;
    if (data is Map) {
      summaryData = data.map(
        (key, value) => MapEntry(key.toString(), value),
      );
    }
    return EducationPaymentSummaryResponse(
      status: json['status'] == true,
      data: summaryData == null
          ? null
          : EducationPaymentSummaryData.fromJson(summaryData),
      message: message,
    );
  }

  final bool status;
  final EducationPaymentSummaryData? data;
  final String? message;
}

class EducationCreateOrderResponse {
  const EducationCreateOrderResponse({
    required this.status,
    required this.message,
    required this.txnId,
    required this.transactionRefId,
    required this.orderId,
    required this.amount,
    required this.currency,
    required this.key,
  });

  factory EducationCreateOrderResponse.fromJson(Map<String, dynamic> json) {
    double toDouble(Object? value) {
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? 0.0;
    }

    return EducationCreateOrderResponse(
      status: json['status'] == true,
      message: (json['message'] ?? '').toString(),
      txnId: int.tryParse((json['txn_id'] ?? '').toString()) ?? 0,
      transactionRefId: (json['transaction_ref_id'] ?? '').toString().trim(),
      orderId: (json['order_id'] ?? '').toString().trim(),
      amount: toDouble(json['amount']),
      currency: (json['currency'] ?? 'INR').toString().trim(),
      key: (json['key'] ?? '').toString().trim(),
    );
  }

  final bool status;
  final String message;
  final int txnId;
  final String transactionRefId;
  final String orderId;
  final double amount;
  final String currency;
  final String key;
}

class EducationPaymentStatusResponse {
  const EducationPaymentStatusResponse({
    required this.status,
    required this.message,
    required this.transactionId,
    required this.paymentStatus,
    required this.amount,
    required this.updatedAt,
    this.paymentType = '',
    this.serviceCharge = '',
    this.gstOnServiceCharge = '',
    this.payableAmount = '',
    this.bannerImage = '',
  });

  factory EducationPaymentStatusResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    final data = json['data'];
    final flattened = <String, dynamic>{
      ...json,
      if (data is Map)
        ...data.map((key, value) => MapEntry(key.toString(), value)),
    };

    final paymentStatus = _readPaymentStatus(flattened);
    final rawAmount = _readMappedText(
      flattened,
      [
        'amount',
        'Amount',
        'paid_amount',
        'transaction_amount',
        'total_amount',
        'payable_amount',
        'total_amount_charged',
      ],
    );
    final rawTime = _readMappedText(
      flattened,
      [
        'transaction_time',
        'timestamp',
        'paid_at',
        'payment_time',
        'created_at',
        'updated_at',
      ],
    );

    return EducationPaymentStatusResponse(
      status: json['status'] == true,
      message: (json['message'] ?? '').toString().trim(),
      transactionId: (flattened['transaction_id'] ?? '').toString().trim(),
      paymentStatus: paymentStatus,
      amount: rawAmount,
      updatedAt: rawTime,
      paymentType: (flattened['payment_type'] ?? '').toString().trim(),
      serviceCharge: _readCharge(flattened, const [
        'service_charge',
        'Service Charge',
      ]),
      gstOnServiceCharge: _readCharge(flattened, const [
        'gst_on_service_charge',
        'GST on Service Charge',
      ]),
      payableAmount:
          (flattened['payable_amount'] ?? flattened['total_payable'] ?? '')
              .toString()
              .trim(),
      bannerImage: _readBannerImage(flattened),
    );
  }

  final bool status;
  final String message;
  final String transactionId;
  final String paymentStatus;
  final String amount;
  final String updatedAt;
  final String paymentType;
  final String serviceCharge;
  final String gstOnServiceCharge;
  final String payableAmount;
  final String bannerImage;

  bool get isSuccess => paymentStatus.trim().toUpperCase() == 'SUCCESS';
  bool get isPending => paymentStatus.trim().toUpperCase() == 'PENDING';
  bool get isProcessing => paymentStatus.trim().toUpperCase() == 'PROCESSING';
  bool get isFailed => paymentStatus.trim().toUpperCase() == 'FAILED';
  bool get hasKnownPaymentStatus =>
      isSuccess || isFailed || isPending || isProcessing;
}

String _readCharge(Map<String, dynamic> source, List<String> keys) {
  String from(Map<dynamic, dynamic> map) {
    for (final key in keys) {
      for (final entry in map.entries) {
        if (entry.key.toString().trim().toLowerCase() != key.toLowerCase()) {
          continue;
        }
        final text = entry.value?.toString().trim() ?? '';
        if (text.isEmpty || text.toLowerCase() == 'null') continue;
        return text;
      }
    }
    return '';
  }

  final direct = from(source);
  if (direct.isNotEmpty) return direct;
  final breakdown = source['amount_breakdown'];
  if (breakdown is Map) return from(breakdown);
  return '';
}

String _readPaymentStatus(Map<String, dynamic> source) {
  for (final key in ['payment_status', 'status']) {
    final value = source[key];
    if (value == null || value is bool) continue;
    final text = value.toString().trim();
    if (text.isEmpty) continue;
    final normalized = text.toLowerCase();
    if (normalized == 'true' || normalized == 'false') continue;
    return text;
  }
  return '';
}

String _readMappedText(Map<String, dynamic> source, List<String> keys) {
  for (final key in keys) {
    final value = source[key];
    if (value == null || value is bool) continue;
    final text = value.toString().trim();
    if (text.isEmpty || text.toLowerCase() == 'null') continue;
    return text;
  }
  return '';
}

String _readBannerImage(Map<String, dynamic> source) {
  for (final key in [
    'banner_image',
    'ad_image',
    'advertisement_image',
    'promo_image',
    'image_url',
    'banner_url',
    'image',
  ]) {
    final text = (source[key] ?? '').toString().trim();
    if (text.isNotEmpty && text.toLowerCase() != 'null') {
      return text;
    }
  }
  for (final key in ['banner', 'advertisement', 'ad']) {
    final nested = source[key];
    if (nested is Map) {
      final image = (nested['image'] ??
              nested['image_url'] ??
              nested['banner_image'] ??
              '')
          .toString()
          .trim();
      if (image.isNotEmpty && image.toLowerCase() != 'null') {
        return image;
      }
    }
  }
  return '';
}

class EducationCard {
  const EducationCard({
    required this.cardId,
    required this.cardToken,
    required this.cardNumber,
    required this.last4,
    required this.cardNetwork,
    required this.expiryMonth,
    required this.expiryYear,
    required this.expiryDisplay,
    required this.isExpired,
    required this.createdAt,
    this.name,
    this.pan,
    this.accountNumber,
    this.ifsc,
    this.branch,
  });

  factory EducationCard.fromJson(Map<String, dynamic> json) {
    return EducationCard(
      cardId: json['card_id'] as int? ?? 0,
      cardToken: json['card_token']?.toString() ?? '',
      cardNumber: json['card_number']?.toString() ?? '',
      last4: json['last4']?.toString() ?? '',
      cardNetwork: json['card_network']?.toString() ?? '',
      expiryMonth: json['expiry_month']?.toString() ?? '',
      expiryYear: json['expiry_year']?.toString() ?? '',
      expiryDisplay: json['expiry_display']?.toString() ?? '',
      isExpired: json['is_expired'] == true,
      createdAt: json['created_at']?.toString() ?? '',
      name: json['name']?.toString(),
      pan: json['pan']?.toString(),
      accountNumber: json['account_number']?.toString(),
      ifsc: json['ifsc']?.toString(),
      branch: json['branch']?.toString(),
    );
  }

  final int cardId;
  final String cardToken;
  final String cardNumber;
  final String last4;
  final String cardNetwork;
  final String expiryMonth;
  final String expiryYear;
  final String expiryDisplay;
  final bool isExpired;
  final String createdAt;
  final String? name;
  final String? pan;
  final String? accountNumber;
  final String? ifsc;
  final String? branch;
}

class EducationCardListResponse {
  const EducationCardListResponse({
    required this.status,
    this.message,
    this.cards = const [],
  });

  factory EducationCardListResponse.fromJson(Map<String, dynamic> json) {
    String? message;
    final messages = json['messages'];
    if (messages is Map && messages['error'] is String) {
      message = messages['error'] as String;
    } else {
      message = json['message'] as String?;
    }
    final data = json['data'];
    final cards = data is List
        ? data
            .whereType<Map<String, dynamic>>()
            .map(EducationCard.fromJson)
            .toList()
        : <EducationCard>[];
    return EducationCardListResponse(
      status: json['status'] == true,
      message: message,
      cards: cards,
    );
  }

  final bool status;
  final String? message;
  final List<EducationCard> cards;
}

class EducationBeneficiary {
  const EducationBeneficiary({
    required this.id,
    required this.userId,
    required this.name,
    required this.mobile,
    required this.accountType,
    required this.createdAt,
    required this.panMasked,
    required this.accountMasked,
    required this.ifsc,
    required this.branch,
    this.accountNoUnmasked,
  });

  factory EducationBeneficiary.fromJson(Map<String, dynamic> json) {
    return EducationBeneficiary(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      mobile: json['mobile']?.toString() ?? '',
      accountType: json['account_type']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
      panMasked: json['pan_masked']?.toString() ?? '',
      accountMasked: json['account_masked']?.toString() ?? '',
      ifsc: json['ifsc']?.toString() ?? '',
      branch: json['branch']?.toString() ?? '',
      accountNoUnmasked: _completeBeneficiaryAccount(json),
    );
  }

  final String id;
  final String userId;
  final String name;
  final String mobile;
  final String accountType;
  final String createdAt;
  final String panMasked;
  final String accountMasked;
  final String ifsc;
  final String branch;
  final String? accountNoUnmasked;
}

class EducationBeneficiariesResponse {
  const EducationBeneficiariesResponse({
    required this.status,
    this.message,
    this.beneficiaries = const [],
  });

  factory EducationBeneficiariesResponse.fromJson(Map<String, dynamic> json) {
    String? message;
    final messages = json['messages'];
    if (messages is Map && messages['error'] is String) {
      message = messages['error'] as String;
    } else {
      message = json['message'] as String?;
    }
    final data = json['data'];
    final items = data is List
        ? data
            .whereType<Map<String, dynamic>>()
            .map(EducationBeneficiary.fromJson)
            .toList()
        : <EducationBeneficiary>[];
    return EducationBeneficiariesResponse(
      status: json['status'] == true,
      message: message,
      beneficiaries: items,
    );
  }

  final bool status;
  final String? message;
  final List<EducationBeneficiary> beneficiaries;
}

class EducationSaveBeneficiaryResponse {
  const EducationSaveBeneficiaryResponse({
    required this.status,
    this.message,
    this.beneficiaryId,
  });

  factory EducationSaveBeneficiaryResponse.fromJson(Map<String, dynamic> json) {
    String? message;
    final messages = json['messages'];
    if (messages is Map && messages['error'] is String) {
      message = messages['error'] as String;
    } else {
      message = json['message'] as String?;
    }
    return EducationSaveBeneficiaryResponse(
      status: json['status'] == true,
      message: message,
      beneficiaryId: json['beneficiary_id'] as int?,
    );
  }

  final bool status;
  final String? message;
  final int? beneficiaryId;
}

/// Request for tutor recipient save beneficiary API
/// (`POST /api/education/save-beneficiary` for unverified tutor flow).
///
/// The [recipientReference] is the exact value stored by a successful tutor
/// PAN verification; it is never hardcoded, reconstructed or replaced by the
/// beneficiary id.
class EducationTutorSaveBeneficiaryRequest {
  const EducationTutorSaveBeneficiaryRequest({
    required this.recipientReference,
  });

  final String recipientReference;

  Map<String, dynamic> toJson() {
    return {
      'recipient_reference': recipientReference,
    };
  }
}

/// Response for tutor recipient save beneficiary API.
///
/// The response contains [beneficiaryId] and [recipientReference] at the
/// ROOT level, not inside a nested `data` object. This is distinct from the
/// registered/verified tutor flow which will be implemented separately.
class EducationTutorSaveBeneficiaryResponse {
  const EducationTutorSaveBeneficiaryResponse({
    required this.status,
    this.message,
    this.beneficiaryId,
    this.recipientReference,
  });

  factory EducationTutorSaveBeneficiaryResponse.fromJson(
      Map<String, dynamic> json) {
    String? message;
    final messages = json['messages'];
    if (messages is Map && messages['error'] is String) {
      message = messages['error'] as String;
    } else {
      message = json['message'] as String?;
    }
    return EducationTutorSaveBeneficiaryResponse(
      status: json['status'] == true,
      message: message,
      beneficiaryId: json['beneficiary_id'] as int?,
      recipientReference: json['recipient_reference']?.toString(),
    );
  }

  final bool status;
  final String? message;
  final int? beneficiaryId;
  final String? recipientReference;
}

/// Request for registered/verified tutor Save Beneficiary API
/// (`POST /api/education/save-beneficiary`).
///
/// The [requestReference] MUST come from the Tutor Send Request response
/// (`data.request_reference`). It is never hardcoded, reconstructed or replaced
/// by the recipient_reference or beneficiary_id.
class EducationTutorSaveBeneficiaryRegisteredRequest {
  const EducationTutorSaveBeneficiaryRegisteredRequest({
    required this.requestReference,
  });

  final String requestReference;

  Map<String, dynamic> toJson() {
    return {
      'request_reference': requestReference,
    };
  }
}

/// Nested data object for registered/verified tutor Save Beneficiary response.
class EducationTutorSaveBeneficiaryRegisteredData {
  const EducationTutorSaveBeneficiaryRegisteredData({
    required this.beneficiaryId,
    required this.recipientReference,
    required this.recipientType,
    required this.panVerified,
    required this.bankVerified,
  });

  factory EducationTutorSaveBeneficiaryRegisteredData.fromJson(
      Map<String, dynamic> json) {
    return EducationTutorSaveBeneficiaryRegisteredData(
      beneficiaryId: json['beneficiary_id'] as int? ?? 0,
      recipientReference: json['recipient_reference']?.toString() ?? '',
      recipientType: json['recipient_type']?.toString() ?? '',
      panVerified: json['pan_verified'] == true,
      bankVerified: json['bank_verified'] == true,
    );
  }

  final int beneficiaryId;
  final String recipientReference;
  final String recipientType;
  final bool panVerified;
  final bool bankVerified;
}

/// Response for registered/verified tutor Save Beneficiary API.
///
/// Unlike the unverified flow, this response has a nested `data` object
/// containing beneficiary details. The request uses `request_reference` from
/// Tutor Send Request, not `recipient_reference`.
class EducationTutorSaveBeneficiaryRegisteredResponse {
  const EducationTutorSaveBeneficiaryRegisteredResponse({
    required this.status,
    this.message,
    this.data,
  });

  factory EducationTutorSaveBeneficiaryRegisteredResponse.fromJson(
      Map<String, dynamic> json) {
    String? message;
    final messages = json['messages'];
    if (messages is Map && messages['error'] is String) {
      message = messages['error'] as String;
    } else {
      message = json['message'] as String?;
    }

    final dataJson = json['data'];
    EducationTutorSaveBeneficiaryRegisteredData? data;
    if (dataJson is Map<String, dynamic>) {
      data = EducationTutorSaveBeneficiaryRegisteredData.fromJson(dataJson);
    }

    return EducationTutorSaveBeneficiaryRegisteredResponse(
      status: json['status'] == true,
      message: message,
      data: data,
    );
  }

  final bool status;
  final String? message;
  final EducationTutorSaveBeneficiaryRegisteredData? data;
}
