import '../../services/models/biller_model.dart';

class LatestTransaction extends Biller {
  const LatestTransaction({
    required this.id,
    super.billerId = '',
    required this.paymentType,
    required super.billerName,
    required this.amount,
    required this.status,
    required this.transactionRef,
    required this.serviceNo,
    this.serviceNoFull,
    String? icon = '',
    this.createdAt,
    this.expiresAt,
    this.dueDate,
    this.transactionTime,
    this.daysLeft,
    this.customerName = '',
    this.accountHolderName = '',
    this.autoPayActive = false,
  }) : super(icon: icon);

  final String id;
  final String paymentType;
  final num amount;
  final String status;
  final String transactionRef;
  final String serviceNo;
  final String? serviceNoFull;
  @override
  String get icon => super.icon ?? '';
  final String? createdAt;
  final String? expiresAt;
  final String? dueDate;
  final String? transactionTime;
  final int? daysLeft;
  final String customerName;
  final String accountHolderName;
  final bool autoPayActive;

  factory LatestTransaction.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic>? billerResponse =
        (json['payload']?['billerResponse'] ?? json['billerResponse']) as Map<String, dynamic>?;

    return LatestTransaction(
      id: (json['id'] ?? '').toString(),
      billerId: (json['biller_id'] ?? json['provider_id'] ?? '').toString(),
      paymentType: (json['payment_type'] ?? '').toString(),
      billerName: (json['biller_name'] ?? '').toString(),
      amount: () {
        final val = billerResponse?['amount'] ??
            json['amount'] ??
            json['bill_amount'] ??
            json['paid_amount'] ??
            json['total_amount'] ??
            json['amount_in_rupees'];
        if (val is num) return val;
        return num.tryParse((val ?? '0').toString()) ?? 0;
      }(),
      status: (json['status'] ?? '').toString(),
      transactionRef: (json['transaction_ref'] ?? '').toString(),
      serviceNo: (json['service_no'] ?? '').toString(),
      serviceNoFull: () {
        final val = (json['service_no_full'] ?? json['serviceNoFull'])
            ?.toString()
            .trim();
        if (val == null || val.isEmpty || val.toLowerCase() == 'null') {
          return null;
        }
        return val;
      }(),
      icon: (json['icon'] ?? '').toString(),
      createdAt: json['created_at']?.toString(),
      expiresAt: (json['expires_at'] ??
              json['expiry_date'] ??
              json['expire_date'] ??
              json['valid_till'] ??
              json['next_due'] ??
              json['nextDue'])
          ?.toString(),
      dueDate: (billerResponse?['dueDate'] ??
              billerResponse?['due_date'] ??
              json['due_date'] ??
              json['dueDate'] ??
              json['next_due'] ??
              json['nextDue'] ??
              json['billDueDate'] ??
              json['bill_due_date'] ??
              json['billDue'] ??
              json['bill_due'] ??
              json['data']?['dueDate'] ??
              json['data']?['due_date'] ??
              json['payload']?['dueDate'] ??
              json['payload']?['due_date'])
          ?.toString(),
      transactionTime: json['transaction_time']?.toString(),
      daysLeft: _parseDaysLeft(json['days_left'] ?? json['daysLeft']),
      customerName: _readCustomerName(json),
      accountHolderName: () {
        final val = billerResponse?['accountHolderName'] ??
            billerResponse?['account_holder_name'] ??
            json['accountHolderName'] ??
            json['account_holder_name'];
        if (val != null && val.toString().trim().isNotEmpty) {
          return val.toString().trim();
        }
        return _readCustomerName(json);
      }(),
      autoPayActive: _parseAutoPay(json),
    );
  }

  /// Returns the full unmasked consumer/service number if available,
  /// otherwise falls back to [serviceNo].
  String get primaryConsumerNumber {
    final full = serviceNoFull?.trim();
    if (full != null && full.isNotEmpty && full.toLowerCase() != 'null') {
      return full;
    }
    return serviceNo.trim();
  }

  /// Alias for [primaryConsumerNumber] representing the full consumer/service number.
  String get service_no_full => primaryConsumerNumber;

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
