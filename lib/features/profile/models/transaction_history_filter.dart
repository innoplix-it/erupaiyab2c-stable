class TransactionHistoryFilter {
  const TransactionHistoryFilter({
    this.status,
    this.paymentType,
    this.month,
    this.fromDate,
    this.toDate,
    this.service,
    this.minAmount,
    this.maxAmount,
    this.consumerId,
  });

  final String? status;
  final String? paymentType;
  final String? month; // format: YYYY-MM
  final DateTime? fromDate;
  final DateTime? toDate;
  final String? service;
  final double? minAmount;
  final double? maxAmount;
  final String? consumerId;

  bool get isEmpty =>
      (status == null || status!.isEmpty) &&
      (paymentType == null || paymentType!.isEmpty) &&
      (month == null || month!.isEmpty) &&
      fromDate == null &&
      toDate == null &&
      (service == null || service!.isEmpty) &&
      (consumerId == null || consumerId!.isEmpty) &&
      minAmount == null &&
      maxAmount == null;

  TransactionHistoryFilter copyWith({
    String? status,
    String? paymentType,
    String? month,
    DateTime? fromDate,
    DateTime? toDate,
    String? service,
    double? minAmount,
    double? maxAmount,
    String? consumerId,
  }) {
    return TransactionHistoryFilter(
      status: status ?? this.status,
      paymentType: paymentType ?? this.paymentType,
      month: month ?? this.month,
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
      service: service ?? this.service,
      minAmount: minAmount ?? this.minAmount,
      maxAmount: maxAmount ?? this.maxAmount,
      consumerId: consumerId ?? this.consumerId,
    );
  }
}
