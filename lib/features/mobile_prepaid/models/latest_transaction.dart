class LatestTransaction {
  const LatestTransaction({
    required this.id,
    this.billerId = '',
    required this.paymentType,
    required this.billerName,
    required this.amount,
    required this.status,
    required this.transactionRef,
    required this.serviceNo,
    this.serviceNoFull,
    required this.icon,
    this.createdAt,
    this.expiresAt,
    this.dueDate,
    this.transactionTime,
    this.daysLeft,
    this.customerName = '',
    this.autoPayActive = false,
  });

  final String id;
  final String billerId;
  final String paymentType;
  final String billerName;
  final num amount;
  final String status;
  final String transactionRef;
  final String serviceNo;
  final String? serviceNoFull;
  final String icon;
  final String? createdAt;
  final String? expiresAt;
  final String? dueDate;
  final String? transactionTime;
  final int? daysLeft;
  final String customerName;
  final bool autoPayActive;

  factory LatestTransaction.fromJson(Map<String, dynamic> json) {
    return LatestTransaction(
      id: (json['id'] ?? '').toString(),
      billerId: (json['biller_id'] ?? json['provider_id'] ?? '').toString(),
      paymentType: (json['payment_type'] ?? '').toString(),
      billerName: (json['biller_name'] ?? '').toString(),
      amount: json['amount'] is num
          ? (json['amount'] as num)
          : num.tryParse((json['amount'] ?? '0').toString()) ?? 0,
      status: (json['status'] ?? '').toString(),
      transactionRef: (json['transaction_ref'] ?? '').toString(),
      serviceNo: (json['service_no'] ?? '').toString(),
      serviceNoFull:
          (json['service_no_full'] ?? json['serviceNoFull'])?.toString(),
      icon: (json['icon'] ?? '').toString(),
      createdAt: json['created_at']?.toString(),
      expiresAt: (json['expires_at'] ??
              json['expiry_date'] ??
              json['expire_date'] ??
              json['valid_till'] ??
              json['next_due'] ??
              json['nextDue'])
          ?.toString(),
      dueDate: json['due_date']?.toString(),
      transactionTime: json['transaction_time']?.toString(),
      daysLeft: _parseDaysLeft(json['days_left'] ?? json['daysLeft']),
      customerName: _readCustomerName(json),
      autoPayActive: _parseAutoPay(json),
    );
  }

  bool get isSuccess => status.trim().toLowerCase() == 'success';

  static String _readCustomerName(Map<String, dynamic> json) {
    const keys = [
      'customer_name',
      'user_name',
      'consumer_name',
      'customerName',
      'userName',
    ];
    for (final key in keys) {
      final text = json[key]?.toString().trim() ?? '';
      if (text.isNotEmpty) return text;
    }
    final name = (json['name'] ?? '').toString().trim();
    final biller = (json['biller_name'] ?? '').toString().trim();
    if (name.isNotEmpty && name.toLowerCase() != biller.toLowerCase()) {
      return name;
    }
    return '';
  }

  static bool _parseAutoPay(Map<String, dynamic> json) {
    final value = json['autopay'] ??
        json['auto_pay'] ??
        json['autopay_status'] ??
        json['is_autopay'] ??
        json['autopayActive'];
    if (value is bool) return value;
    final text = value?.toString().trim().toLowerCase() ?? '';
    return text == 'true' ||
        text == '1' ||
        text == 'active' ||
        text == 'yes' ||
        text == 'enabled';
  }

  static int? _parseDaysLeft(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value.toString().trim());
  }
}
