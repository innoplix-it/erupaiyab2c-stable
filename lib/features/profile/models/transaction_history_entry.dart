import 'dart:convert';

class TransactionHistoryEntry {
  const TransactionHistoryEntry({
    required this.paymentStatus,
    required this.paymentType,
    required this.billerName,
    required this.maskedIdentifier,
    required this.amount,
    required this.platformFees,
    required this.totalAmountCharged,
    required this.customerMobile,
    required this.iconUrl,
    required this.pgTransactionId,
    required this.ecoinsTransactionId,
    required this.transactionId,
    required this.bankReferenceId,
    required this.referenceId,
    required this.transactionTime,
    required this.method,
    required this.methodIcon,
    required this.paymentMode,
    required this.vpa,
    required this.rrn,
    this.customerParams = const [],
    this.amountBreakdown = const {},
    this.routes = const [],
    this.feeType,
    this.serviceNo,
    this.serviceNoFull,
  });

  final String? serviceNo;
  final String? serviceNoFull;

  String get primaryConsumerNumber {
    final full = serviceNoFull?.trim();
    if (full != null && full.isNotEmpty && full.toLowerCase() != 'null') {
      return full;
    }
    final sNo = serviceNo?.trim();
    if (sNo != null && sNo.isNotEmpty && sNo.toLowerCase() != 'null') {
      return sNo;
    }
    for (final param in customerParams) {
      final l = param.label.trim().toLowerCase();
      if (l.contains('consumer') ||
          l.contains('ca number') ||
          l.contains('account') ||
          l.contains('k no')) {
        final val = param.value.trim();
        if (val.isNotEmpty && val.toLowerCase() != 'null') {
          return val;
        }
      }
    }
    return maskedIdentifier.trim();
  }

  /// Client-side safety net for the View History consumer filter.
  /// [normalizedTarget] must be the selected biller's full consumer number
  /// (service_no_full) with whitespace stripped. Matches only on equality or
  /// when a candidate carries the full target as a substring (prefix/suffix
  /// tolerant). The previous reverse check (target containing a candidate)
  /// let short masked values like "5046" match unrelated transactions.
  ///
  /// NOTE: generic/main history path. Left untouched for the Electricity
  /// card-scoped flow, which uses [explicitServiceNoFull] /
  /// [explicitlyBelongsToDifferentCard] / [isDefinitelyOtherService] below.
  bool matchesConsumerId(String normalizedTarget) {
    if (normalizedTarget.isEmpty) return true;
    final candidates = <String>[
      primaryConsumerNumber,
      serviceNoFull ?? '',
      serviceNo ?? '',
      maskedIdentifier,
    ];
    for (final param in customerParams) {
      candidates.add(param.value);
    }
    for (final raw in candidates) {
      final c = raw.trim().replaceAll(RegExp(r'\s+'), '');
      if (c.isEmpty || c.toLowerCase() == 'null') continue;
      if (c == normalizedTarget || c.contains(normalizedTarget)) return true;
    }
    return false;
  }

  /// Partial identifiers (last-4 / last-5 style) are never full consumer
  /// numbers, so they must not be used to exclude a row from a card scope.
  static const int _minFullConsumerNumberLength = 6;

  static String? _unmaskedFullNumber(String? raw, {bool trusted = false}) {
    final value = (raw ?? '').trim().replaceAll(RegExp(r'\s+'), '');
    if (value.isEmpty || value.toLowerCase() == 'null') return null;
    // Masked values ("XXXX5841", "****5841") carry no full number.
    if (value.contains('*') || value.toLowerCase().contains('x')) return null;
    if (!trusted && value.length < _minFullConsumerNumberLength) return null;
    return value;
  }

  /// Explicit, unmasked FULL consumer number carried by this row, if any.
  ///
  /// Used ONLY by the Electricity card-scoped View History flow. Reads, in
  /// order, `service_no_full`, an unmasked full `service_no`, then an unmasked
  /// consumer-labelled customer param. `masked_identifier`, `customer_mobile`
  /// and short/partial values are never considered. Returns null when the row
  /// carries no explicit full number (such rows are preserved, since the API
  /// request itself is already scoped by service_no_full).
  String? get explicitFullConsumerNumber {
    final full = _unmaskedFullNumber(serviceNoFull, trusted: true);
    if (full != null) return full;
    final sNo = _unmaskedFullNumber(serviceNo);
    if (sNo != null) return sNo;
    for (final param in customerParams) {
      final l = param.label.trim().toLowerCase();
      if (l.contains('consumer') ||
          l.contains('ca number') ||
          l.contains('account') ||
          l.contains('k no')) {
        final val = _unmaskedFullNumber(param.value);
        if (val != null) return val;
      }
    }
    return null;
  }

  /// True only when this row explicitly identifies a DIFFERENT full consumer
  /// number than the selected card (normalized exact equality; no
  /// contains/startsWith/endsWith/last-4). Rows without an explicit full
  /// number return false (preserved, not filtered out).
  bool explicitlyBelongsToDifferentCard(String normalizedTarget) {
    if (normalizedTarget.isEmpty) return false;
    final own = explicitFullConsumerNumber;
    if (own == null || own.isEmpty) return false;
    return own != normalizedTarget;
  }

  /// True only when this row is definitely a non-Electricity service
  /// (FASTag, Mobile Prepaid/Postpaid, Tuition/School/College fee, DTH, Gas,
  /// Water, Broadband, Credit Card, Insurance, ...). Electricity rows and
  /// ambiguous/empty rows return false so valid scoped records are preserved.
  bool get isDefinitelyOtherService {
    final haystack =
        '${paymentType.trim()} ${billerName.trim()} ${feeType?.trim() ?? ''}'
            .trim()
            .toLowerCase();
    if (haystack.isEmpty) return false;
    if (haystack.contains('electric')) return false;
    const otherMarkers = [
      'fastag',
      'mobile',
      'recharge',
      'postpaid',
      'tuition',
      'tution',
      'school',
      'college',
      'education',
      'dth',
      'gas',
      'water',
      'broadband',
      'landline',
      'credit card',
      'insurance',
      'loan',
    ];
    return otherMarkers.any(haystack.contains);
  }

  final String paymentStatus;
  final String paymentType;
  final String billerName;
  final String maskedIdentifier;
  final String amount;
  final String platformFees;
  final String totalAmountCharged;
  final String customerMobile;
  final String iconUrl;
  final String pgTransactionId;
  final String ecoinsTransactionId;
  final String transactionId;
  final String bankReferenceId;
  final String referenceId;
  final String transactionTime;
  final String method;
  final String methodIcon;
  final String paymentMode;
  final String vpa;
  final String rrn;
  final List<TransactionCustomerParam> customerParams;
  final Map<String, dynamic> amountBreakdown;
  final List<TransactionRoute> routes;
  final String? feeType;

  factory TransactionHistoryEntry.fromJson(Map<String, dynamic> json) {
    final rawCustomerParams = json['customer_params'];
    final customerParams = parseTransactionCustomerParams(rawCustomerParams);
    final rawAmountBreakdown = json['amount_breakdown'];
    final amountBreakdown = rawAmountBreakdown is Map
        ? rawAmountBreakdown.map(
            (key, value) => MapEntry(key.toString(), value),
          )
        : const <String, dynamic>{};
    final rawRoutes = json['routes'];
    final routes = rawRoutes is List
        ? rawRoutes
            .whereType<Map>()
            .map(
              (e) => TransactionRoute.fromJson(
                e.map((key, value) => MapEntry(key.toString(), value)),
              ),
            )
            .toList()
        : const <TransactionRoute>[];
    final paymentType = _stringOrEmpty(json['payment_type']);
    final amount = _stringOrEmpty(json['amount']);
    final totalAmountCharged = _stringOrEmpty(json['total_amount_charged']);
    final billAmountLabel = paymentType.toLowerCase().contains('recharge')
        ? 'Recharge Amount'
        : 'Bill Amount';

    return TransactionHistoryEntry(
      paymentStatus: _readPaymentStatus(json),
      paymentType: paymentType,
      billerName: _stringOrEmpty(json['biller_name']),
      maskedIdentifier: _stringOrEmpty(json['masked_identifier']),
      amount: amount,
      platformFees: _stringOrEmpty(json['platform_fees']),
      totalAmountCharged: totalAmountCharged,
      customerMobile: _stringOrEmpty(json['customer_mobile']),
      iconUrl: _stringOrEmpty(json['icon']),
      pgTransactionId: _stringOrEmpty(
        json['pg_transaction_id'] ??
            json['payment_transaction_id'] ??
            json['transaction_id'],
      ),
      ecoinsTransactionId: _stringOrEmpty(json['ecoins_transaction_id']),
      transactionId: _stringOrEmpty(
        json['pg_transaction_id'] ??
            json['payment_transaction_id'] ??
            json['transaction_id'],
      ),
      bankReferenceId: _stringOrEmpty(
        json['bank_reference_id'] ?? json['bank_referenceId'],
      ),
      referenceId: _stringOrEmpty(json['org_ref_id'] ?? json['reference_id']),
      transactionTime: _stringOrEmpty(json['transaction_time']),
      method: _stringOrEmpty(json['method']),
      methodIcon: _stringOrEmpty(json['method_icon']),
      paymentMode: _stringOrEmpty(json['payment_mode']),
      vpa: _stringOrEmpty(json['vpa']),
      rrn: _stringOrEmpty(json['rrn']),
      customerParams: ensurePaymentTypeCustomerParam(
        params: customerParams,
        paymentType: paymentType,
      ),
      amountBreakdown: composeTransactionAmountBreakdown(
        source: json,
        existingBreakdown: amountBreakdown,
        fallbackBillAmount: amount,
        fallbackTotal: _stringOrEmpty(
          json['payable_amount'] ??
              json['total_payable'] ??
              totalAmountCharged,
        ),
        billAmountLabel: billAmountLabel,
      ),
      routes: routes,
      feeType: _stringOrEmpty(json['fee_type']).isEmpty
          ? null
          : _stringOrEmpty(json['fee_type']),
      serviceNo: () {
        final data = json['data'] is Map ? json['data'] as Map : null;
        final raw = json['service_no'] ??
            json['serviceNo'] ??
            data?['service_no'] ??
            data?['serviceNo'];
        return _stringOrEmpty(raw);
      }(),
      serviceNoFull: () {
        final data = json['data'] is Map ? json['data'] as Map : null;
        final raw = json['service_no_full'] ??
            json['serviceNoFull'] ??
            json['service_number_full'] ??
            data?['service_no_full'] ??
            data?['serviceNoFull'] ??
            data?['service_number_full'];
        final val = _stringOrEmpty(raw);
        return val.isEmpty ? null : val;
      }(),
    );
  }
}

class TransactionCustomerParam {
  const TransactionCustomerParam({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  factory TransactionCustomerParam.fromJson(Map<String, dynamic> json) {
    return TransactionCustomerParam(
      label: _stringOrEmpty(json['label']),
      value: _stringOrEmpty(json['value']),
    );
  }
}

class TransactionRoute {
  const TransactionRoute({
    required this.routeName,
    required this.routeKey,
    required this.deeplink,
    required this.params,
  });

  final String routeName;
  final String routeKey;
  final String deeplink;
  final Map<String, dynamic> params;

  factory TransactionRoute.fromJson(Map<String, dynamic> json) {
    final rawParams = json['params'];
    final params = rawParams is Map
        ? rawParams.map((key, value) => MapEntry(key.toString(), value))
        : const <String, dynamic>{};
    return TransactionRoute(
      routeName: _stringOrEmpty(json['route_name']),
      routeKey: _stringOrEmpty(json['route_key']),
      deeplink: _stringOrEmpty(json['deeplink']),
      params: params,
    );
  }
}

String _stringOrEmpty(dynamic value) {
  if (value == null) return '';
  final text = value.toString().trim();
  return text == 'null' ? '' : text;
}

String _readPaymentStatus(Map<String, dynamic> json) {
  for (final key in [
    'payment_status',
    'paymentStatus',
    'txn_status',
    'transaction_status',
    'transactionStatus',
  ]) {
    final value = _stringOrEmpty(json[key]);
    if (value.isNotEmpty) return value;
  }
  final status = json['status'];
  if (status is bool || status is num) return '';
  return _stringOrEmpty(status);
}

bool _hasMappedValue(dynamic value) => _stringOrEmpty(value).isNotEmpty;

String _readMappedValue(Map<String, dynamic> source, List<String> keys) {
  for (final key in keys) {
    final exact = source[key];
    if (_hasMappedValue(exact)) return _stringOrEmpty(exact);
    for (final entry in source.entries) {
      if (entry.key.trim().toLowerCase() == key.toLowerCase() &&
          _hasMappedValue(entry.value)) {
        return _stringOrEmpty(entry.value);
      }
    }
  }
  return '';
}

List<TransactionCustomerParam> ensurePaymentTypeCustomerParam({
  required List<TransactionCustomerParam> params,
  required String paymentType,
}) {
  final resolvedType = paymentType.trim();
  if (resolvedType.isEmpty) return params;

  final hasPaymentType = params.any(
    (item) => item.label.trim().toLowerCase() == 'payment type',
  );
  if (hasPaymentType) return params;

  final paymentToIndex = params.indexWhere(
    (item) => item.label.trim().toLowerCase() == 'payment to',
  );
  if (paymentToIndex < 0) return params;

  final next = [...params];
  next.insert(
    paymentToIndex + 1,
    TransactionCustomerParam(
      label: 'Payment Type',
      value: resolvedType,
    ),
  );
  return next;
}

Map<String, dynamic> composeTransactionAmountBreakdown({
  required Map<String, dynamic> source,
  Map<String, dynamic> existingBreakdown = const {},
  String fallbackBillAmount = '',
  String fallbackTotal = '',
  String billAmountLabel = 'Bill Amount',
}) {
  final data = source['data'];
  final flattened = <String, dynamic>{
    ...source,
    if (data is Map)
      ...data.map((key, value) => MapEntry(key.toString(), value)),
    ...existingBreakdown,
  };

  final billAmount = _readMappedValue(
    flattened,
    [
      'Bill Amount',
      'Recharge Amount',
      'bill_amount',
      'amount',
    ],
  );
  final resolvedBillAmount =
      billAmount.isNotEmpty ? billAmount : fallbackBillAmount.trim();

  final serviceCharge = _readMappedValue(
    flattened,
    ['Service Charge', ''
        ''],
  );
  final gstOnServiceCharge = _readMappedValue(
    flattened,
    ['GST on Service Charge', 'gst_on_service_charge'],
  );
  final payableAmount = _readMappedValue(
    flattened,
    [
      'payable_amount',
      'Payable Amount',
      'total_payable',
      'Total',
      'total_amount_charged',
    ],
  );
  final resolvedTotal = payableAmount.isNotEmpty
      ? payableAmount
      : (fallbackTotal.trim().isNotEmpty
          ? fallbackTotal.trim()
          : resolvedBillAmount);

  final ordered = <String, dynamic>{
    if (resolvedBillAmount.isNotEmpty) billAmountLabel: resolvedBillAmount,
    if (serviceCharge.isNotEmpty) 'Service Charge': serviceCharge,
    if (gstOnServiceCharge.isNotEmpty)
      'GST on Service Charge': gstOnServiceCharge,
  };

  const reserved = {
    'bill amount',
    'recharge amount',
    'bill_amount',
    'amount',
    'service charge',
    'service_charge',
    'gst on service charge',
    'gst_on_service_charge',
    'total',
    'payable_amount',
    'payable amount',
    'total_payable',
    'total_amount_charged',
  };

  for (final entry in existingBreakdown.entries) {
    final key = entry.key.trim();
    if (key.isEmpty) continue;
    if (reserved.contains(key.toLowerCase())) continue;
    if (!_hasMappedValue(entry.value)) continue;
    ordered[entry.key] = entry.value;
  }

  if (resolvedTotal.isNotEmpty) {
    ordered['Total'] = resolvedTotal;
  }
  return ordered;
}

List<TransactionCustomerParam> parseTransactionCustomerParams(dynamic raw) {
  if (raw == null) return const [];
  final List<TransactionCustomerParam> result = [];

  void addParam(String label, dynamic value) {
    final cleanLabel = label.trim();
    if (cleanLabel.isEmpty) return;
    if (value == null) return;

    if (value is List) {
      for (final item in value) {
        if (item is Map) {
          final pName = _readParamKey(
            item,
            ['paramName', 'param_name', 'name', 'label', 'key'],
          );
          final pVal = item['paramValue'] ??
              item['param_value'] ??
              item['value'] ??
              item['val'];
          if (pName.isNotEmpty && pVal != null) {
            addParam(pName, pVal);
          }
        }
      }
      return;
    }

    if (value is Map) {
      final pName = _readParamKey(
        value,
        ['paramName', 'param_name', 'name', 'label', 'key'],
      );
      final pVal =
          value['paramValue'] ?? value['param_value'] ?? value['value'];
      if (pName.isNotEmpty && pVal != null) {
        addParam(pName, pVal);
        return;
      }
      for (final entry in value.entries) {
        addParam(entry.key.toString(), entry.value);
      }
      return;
    }

    final valStr = value.toString().trim();
    if (valStr.isEmpty || valStr == 'null') return;

    // Check if valStr is JSON encoded string
    if ((valStr.startsWith('[') && valStr.endsWith(']')) ||
        (valStr.startsWith('{') && valStr.endsWith('}'))) {
      try {
        final decoded = jsonDecode(valStr);
        if (decoded is List || decoded is Map) {
          addParam(cleanLabel, decoded);
          return;
        }
      } catch (_) {
        // Fallback for Dart map toString format: {paramName: ..., paramValue: ...}
        final regex =
            RegExp(r'paramName:\s*([^,}]+),\s*paramValue:\s*([^,}]+)');
        final matches = regex.allMatches(valStr);
        if (matches.isNotEmpty) {
          for (final m in matches) {
            final pName = m.group(1)?.trim() ?? '';
            final pVal = m.group(2)?.trim() ?? '';
            if (pName.isNotEmpty && pVal.isNotEmpty) {
              addParam(pName, pVal);
            }
          }
          return;
        }
      }
    }

    result.add(TransactionCustomerParam(label: cleanLabel, value: valStr));
  }

  if (raw is List) {
    for (final item in raw) {
      if (item is Map) {
        final label = _readParamKey(
          item,
          ['label', 'paramName', 'param_name', 'name', 'key'],
        );
        final val = item['value'] ??
            item['paramValue'] ??
            item['param_value'] ??
            item['val'];

        if (label.toLowerCase() == 'input' && val != null) {
          addParam(label, val);
        } else if (label.isNotEmpty && val != null) {
          addParam(label, val);
        } else {
          for (final entry in item.entries) {
            final k = entry.key.toString();
            if (k != 'label' && k != 'value') {
              addParam(k, entry.value);
            }
          }
        }
      }
    }
  } else if (raw is Map) {
    for (final entry in raw.entries) {
      addParam(entry.key.toString(), entry.value);
    }
  }

  return result;
}

String _readParamKey(Map map, List<String> candidates) {
  for (final candidate in candidates) {
    final val = map[candidate];
    if (val != null && val.toString().trim().isNotEmpty) {
      return val.toString().trim();
    }
    for (final entry in map.entries) {
      if (entry.key.toString().trim().toLowerCase() ==
          candidate.toLowerCase()) {
        final v = entry.value?.toString().trim() ?? '';
        if (v.isNotEmpty) return v;
      }
    }
  }
  return '';
}
