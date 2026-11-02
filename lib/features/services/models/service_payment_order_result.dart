class ServicePaymentOrderResult {
  const ServicePaymentOrderResult({
    required this.isSuccess,
    required this.message,
    required this.transactionRef,
    required this.txnId,
    required this.orderId,
    required this.key,
    this.gateway,
    this.encRequest,
    this.accessCode,
    this.paymentUrl,
    this.redirectUrl,
    this.cancelUrl,
  });

  final bool isSuccess;
  final String message;
  final String transactionRef;
  final int txnId;
  final String orderId;
  final String key;
  final String? gateway;
  final String? encRequest;
  final String? accessCode;
  final String? paymentUrl;
  final String? redirectUrl;
  final String? cancelUrl;

  bool get isCcavenue => gateway?.trim().toUpperCase() == 'CCAVENUE';
  bool get isRazorpay => gateway?.trim().toUpperCase() != 'CCAVENUE';

  factory ServicePaymentOrderResult.fromJson(Map<String, dynamic> json) {
    final statusValue = json['status'];
    final isSuccess =
        statusValue == true || statusValue?.toString().toLowerCase() == 'true';
    return ServicePaymentOrderResult(
      isSuccess: isSuccess,
      message: (json['message'] ?? '').toString().trim(),
      transactionRef: (json['transaction_ref'] ?? '').toString().trim(),
      txnId: int.tryParse((json['txn_id'] ?? '').toString()) ?? 0,
      orderId: (json['order_id'] ?? '').toString().trim(),
      key: (json['key'] ?? '').toString().trim(),
      gateway: (json['gateway'] ?? '').toString().trim(),
      encRequest: (json['encRequest'] ?? '').toString().trim(),
      accessCode: (json['access_code'] ?? '').toString().trim(),
      paymentUrl: (json['payment_url'] ?? '').toString().trim(),
      redirectUrl: (json['redirect_url'] ?? '').toString().trim(),
      cancelUrl: (json['cancel_url'] ?? '').toString().trim(),
    );
  }
}

