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
  });

  factory EducationValidateAmountResponse.fromJson(Map<String, dynamic> json) {
    String? message;
    final messages = json['messages'];
    if (messages is Map && messages['error'] is String) {
      message = messages['error'] as String;
    } else {
      message = json['message'] as String?;
    }
    return EducationValidateAmountResponse(
      status: json['status'] == true,
      message: message,
    );
  }
  final bool status;
  final String? message;
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
    final rawAmount = (flattened['amount'] ??
            flattened['total_amount'] ??
            flattened['payable_amount'] ??
            flattened['total_amount_charged'] ??
            '')
        .toString()
        .trim();
    final rawTime = (flattened['transaction_time'] ??
            flattened['created_at'] ??
            flattened['updated_at'] ??
            '')
        .toString()
        .trim();

    return EducationPaymentStatusResponse(
      status: json['status'] == true,
      message: (json['message'] ?? '').toString().trim(),
      transactionId: (flattened['transaction_id'] ?? '').toString().trim(),
      paymentStatus: paymentStatus,
      amount: rawAmount,
      updatedAt: rawTime,
      paymentType: (flattened['payment_type'] ?? '').toString().trim(),
      serviceCharge: (flattened['service_charge'] ?? '').toString().trim(),
      gstOnServiceCharge:
          (flattened['gst_on_service_charge'] ?? '').toString().trim(),
      payableAmount: (flattened['payable_amount'] ??
              flattened['total_payable'] ??
              '')
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
      accountNoUnmasked: json['account_no_unmasked']?.toString(),
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
