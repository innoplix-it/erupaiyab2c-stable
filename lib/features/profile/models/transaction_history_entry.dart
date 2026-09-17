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
    return TransactionHistoryEntry(
      paymentStatus: _stringOrEmpty(json['payment_status']),
      paymentType: _stringOrEmpty(json['payment_type']),
      billerName: _stringOrEmpty(json['biller_name']),
      maskedIdentifier: _stringOrEmpty(json['masked_identifier']),
      amount: _stringOrEmpty(json['amount']),
      platformFees: _stringOrEmpty(json['platform_fees']),
      totalAmountCharged: _stringOrEmpty(json['total_amount_charged']),
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
      customerParams: customerParams,
      amountBreakdown: amountBreakdown,
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
  final text = value.toString();
  return text == 'null' ? '' : text;
}
