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
  });

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
    final customerParams = rawCustomerParams is List
        ? rawCustomerParams
            .whereType<Map>()
            .map(
              (e) => TransactionCustomerParam.fromJson(
                e.map((key, value) => MapEntry(key.toString(), value)),
              ),
            )
            .toList()
        : const <TransactionCustomerParam>[];
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
    ['Service Charge', 'service_charge'],
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
