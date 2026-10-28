import 'package:flutter_test/flutter_test.dart';

import 'package:e_rupaiya/features/mobile_prepaid/models/prepaid_transaction_status.dart';
import 'package:e_rupaiya/features/services/models/recharge_status_result.dart';
import 'package:e_rupaiya/widgets/payment_success_flow.dart';

// Mirrors the outcome resolution logic implemented in biller_detail_view & payment_bottom_sheet
String resolveBillerPaymentStatus({
  required bool isSuccess,
  required bool timedOut,
  required RechargeStatusResult? status,
  required bool isGatewayFailure,
}) {
  final normalized = (status?.status.trim().toUpperCase() ?? '');
  if (isSuccess || normalized == 'SUCCESS') {
    return 'SUCCESS';
  } else if (timedOut || status == null) {
    return 'PENDING';
  } else if (normalized == 'PENDING' || normalized == 'PROCESSING') {
    return normalized;
  } else if (isGatewayFailure || normalized == 'FAILED') {
    return 'FAILED';
  } else {
    return normalized.isNotEmpty ? normalized : 'PENDING';
  }
}

void main() {
  group('resolveBillerPaymentStatus — 8 cases audit verification', () {
    test('Case 4: Backend confirms SUCCESS despite gateway failure race', () {
      final status = RechargeStatusResult(
        status: 'SUCCESS',
        message: 'Success',
        transactionId: 'TX1',
        updatedAt: '2026-01-01T00:00:00Z',
        raw: {},
      );
      final result = resolveBillerPaymentStatus(
        isSuccess: true,
        timedOut: false,
        status: status,
        isGatewayFailure: true,
      );
      expect(result, 'SUCCESS');
    });

    test('Case 5: Backend reports genuine PENDING — do not force Failed', () {
      final status = RechargeStatusResult(
        status: 'PENDING',
        message: 'Pending with biller',
        transactionId: 'TX1',
        updatedAt: '2026-01-01T00:00:00Z',
        raw: {},
      );
      final result = resolveBillerPaymentStatus(
        isSuccess: false,
        timedOut: false,
        status: status,
        isGatewayFailure: true,
      );
      expect(result, 'PENDING');
    });

    test('Case 5b: Backend reports genuine PROCESSING — do not force Failed', () {
      final status = RechargeStatusResult(
        status: 'PROCESSING',
        message: 'Awaiting operator response',
        transactionId: 'TX1',
        updatedAt: '2026-01-01T00:00:00Z',
        raw: {},
      );
      final result = resolveBillerPaymentStatus(
        isSuccess: false,
        timedOut: false,
        status: status,
        isGatewayFailure: true,
      );
      expect(result, 'PROCESSING');
    });

    test('Case 6: Backend status API fails (status is null) — safely handled as PENDING', () {
      final result = resolveBillerPaymentStatus(
        isSuccess: false,
        timedOut: false,
        status: null,
        isGatewayFailure: true,
      );
      expect(result, 'PENDING');
    });

    test('Case 6b: Status polling timed out — safely handled as PENDING', () {
      final result = resolveBillerPaymentStatus(
        isSuccess: false,
        timedOut: true,
        status: null,
        isGatewayFailure: true,
      );
      expect(result, 'PENDING');
    });

    test('Case 2 & 3: Gateway confirms failure and backend confirms FAILED → FAILED', () {
      final status = RechargeStatusResult(
        status: 'FAILED',
        message: 'Payment declined',
        transactionId: 'TX1',
        updatedAt: '2026-01-01T00:00:00Z',
        raw: {},
      );
      final result = resolveBillerPaymentStatus(
        isSuccess: false,
        timedOut: false,
        status: status,
        isGatewayFailure: true,
      );
      expect(result, 'FAILED');
    });

    test('Case 7: Normal successful payment without gateway failure', () {
      final status = RechargeStatusResult(
        status: 'SUCCESS',
        message: 'Payment completed',
        transactionId: 'TX1',
        updatedAt: '2026-01-01T00:00:00Z',
        raw: {},
      );
      final result = resolveBillerPaymentStatus(
        isSuccess: true,
        timedOut: false,
        status: status,
        isGatewayFailure: false,
      );
      expect(result, 'SUCCESS');
    });
  });

  group('buildPaymentFlowTransactionEntryFromRechargeStatus', () {
    test('statusOverride takes precedence when backend raw says PROCESSING', () {
      final status = RechargeStatusResult(
        status: 'PROCESSING',
        message: 'Order initiated',
        transactionId: 'TXN123',
        updatedAt: '2026-01-01T00:00:00Z',
        raw: {
          'status': 'PROCESSING',
          'payment_status': 'PROCESSING',
          'amount': '150.00',
        },
      );

      final entry = buildPaymentFlowTransactionEntryFromRechargeStatus(
        status: status,
        fallbackStatus: 'FAILED',
        statusOverride: 'FAILED',
        fallbackPaymentType: 'Electricity',
        fallbackBillerName: 'Tata Power',
        fallbackAmount: 150.00,
        fallbackTransactionId: 'TXN123',
      );

      expect(entry.paymentStatus, 'FAILED');
    });

    test('normal flow preserves SUCCESS from backend', () {
      final status = RechargeStatusResult(
        status: 'SUCCESS',
        message: 'Payment completed',
        transactionId: 'TXN123',
        updatedAt: '2026-01-01T00:00:00Z',
        raw: {
          'status': 'SUCCESS',
          'payment_status': 'SUCCESS',
          'amount': '150.00',
        },
      );

      final entry = buildPaymentFlowTransactionEntryFromRechargeStatus(
        status: status,
        fallbackStatus: 'SUCCESS',
        fallbackPaymentType: 'Electricity',
        fallbackBillerName: 'Tata Power',
        fallbackAmount: 150.00,
        fallbackTransactionId: 'TXN123',
      );

      expect(entry.paymentStatus, 'SUCCESS');
    });
  });

  group('buildPaymentFlowTransactionEntryFromPrepaidStatus', () {
    test('statusOverride takes precedence on gateway failure', () {
      final status = PrepaidTransactionStatus(
        status: 'PROCESSING',
        message: 'Processing recharge',
        transactionId: 'MOB123',
        amount: '299.00',
        mobile: '9876543210',
        operatorName: 'Airtel',
        paymentMode: 'Online',
        walletAmount: '0.00',
        razorpayAmount: '299.00',
        updatedAt: '2026-01-01T00:00:00Z',
        raw: {
          'status': 'PROCESSING',
          'payment_status': 'PROCESSING',
        },
      );

      final entry = buildPaymentFlowTransactionEntryFromPrepaidStatus(
        status: status,
        fallbackStatus: 'FAILED',
        statusOverride: 'FAILED',
        fallbackPaymentType: 'Mobile Prepaid',
        fallbackBillerName: 'Airtel',
        fallbackAmount: 299.00,
        fallbackTransactionId: 'MOB123',
      );

      expect(entry.paymentStatus, 'FAILED');
    });
  });
}
