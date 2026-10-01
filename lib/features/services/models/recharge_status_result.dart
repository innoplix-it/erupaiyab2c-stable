import '../../profile/models/transaction_history_entry.dart';

class RechargeStatusResult {
  const RechargeStatusResult({
    required this.status,
    required this.message,
    required this.transactionId,
    required this.updatedAt,
    required this.raw,
    this.customerParams = const [],
    this.amountBreakdown = const {},
  });

  final String status;
  final String message;
  final String transactionId;
  final String updatedAt;
  final Map<String, dynamic> raw;
  final List<TransactionCustomerParam> customerParams;
  final Map<String, dynamic> amountBreakdown;

  bool get isSuccess => status.trim().toUpperCase() == 'SUCCESS';
  bool get isFailed => status.trim().toUpperCase() == 'FAILED';
  bool get isPending => status.trim().toUpperCase() == 'PENDING';
  bool get isProcessing => status.trim().toUpperCase() == 'PROCESSING';

  factory RechargeStatusResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map
        ? (json['data'] as Map)
            .map((key, value) => MapEntry(key.toString(), value))
        : const <String, dynamic>{};

    String read(String key) {
      final nested = (data[key] ?? '').toString().trim();
      if (nested.isNotEmpty) return nested;
      return (json[key] ?? '').toString().trim();
    }

    final rawStatus = json['status'];
    final resolvedStatus = rawStatus is bool
        ? read('status')
        : (json['status'] ?? '').toString().trim();

    final rawCustomerParams =
        data['customer_params'] ?? json['customer_params'];
    final customerParams = parseTransactionCustomerParams(rawCustomerParams);

    final rawAmountBreakdown =
        data['amount_breakdown'] ?? json['amount_breakdown'];
    final amountBreakdown = rawAmountBreakdown is Map
        ? rawAmountBreakdown.map(
            (key, value) => MapEntry(key.toString(), value),
          )
        : const <String, dynamic>{};

    return RechargeStatusResult(
      status: resolvedStatus,
      message: read('message'),
      transactionId: read('transaction_id').isNotEmpty
          ? read('transaction_id')
          : (read('transactionId').isNotEmpty
              ? read('transactionId')
              : read('transaction_ref')),
      updatedAt: read('updated_at'),
      raw: json,
      customerParams: customerParams,
      amountBreakdown: amountBreakdown,
    );
  }
}
