import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:e_rupaiya/features/mobile_prepaid/controllers/mobile_prepaid_controller.dart';
import 'package:e_rupaiya/features/mobile_prepaid/models/operator_info.dart';
import 'package:e_rupaiya/features/mobile_prepaid/models/plan_item.dart';
import 'package:e_rupaiya/features/mobile_prepaid/models/prepaid_transaction_status.dart';
import 'package:e_rupaiya/features/mobile_prepaid/models/recharge_order_result.dart';
import 'package:e_rupaiya/features/mobile_prepaid/repositories/mobile_prepaid_repository.dart';
import 'package:e_rupaiya/utils/polling_deadline.dart';
import 'package:e_rupaiya/widgets/payment_processing_loader.dart';

class FakeMobilePrepaidRepository implements MobilePrepaidRepository {
  FakeMobilePrepaidRepository({
    this.statusResponse,
    this.requestCount = 0,
    this.hungRequest = false,
    this.createOrderResponse,
    this.createOrderShouldFail = false,
    this.createOrderCompleter,
  });

  final PrepaidTransactionStatus? statusResponse;
  int requestCount;
  int createOrderCount = 0;
  bool hungRequest;
  final Completer<PrepaidTransactionStatus> _hungCompleter = Completer<PrepaidTransactionStatus>();
  RechargeOrderResult? createOrderResponse;
  bool createOrderShouldFail;
  final Completer<RechargeOrderResult>? createOrderCompleter;

  @override
  Future<PrepaidTransactionStatus> fetchRechargeStatus({
    required String transactionId,
  }) async {
    requestCount++;
    if (hungRequest) {
      return _hungCompleter.future; // Never completes
    }
    return statusResponse ??
        PrepaidTransactionStatus(
          status: 'PROCESSING',
          message: '',
          amount: '100.00',
          operatorName: 'Test Operator',
          mobile: '9876543210',
          paymentMode: 'Online',
          walletAmount: '0.00',
          razorpayAmount: '100.00',
          transactionId: transactionId,
          updatedAt: DateTime.now().toIso8601String(),
          raw: {},
        );
  }

  @override
  Future<RechargeOrderResult> createRechargeOrder({
    required String mobile,
    required int amount,
    required String operatorName,
    required String desc,
    bool useWallet = false,
  }) async {
    createOrderCount++;
    if (createOrderShouldFail) {
      throw Exception('Create order failed');
    }
    if (createOrderCompleter != null) {
      return createOrderCompleter!.future;
    }
    return createOrderResponse ??
        RechargeOrderResult(
          isSuccess: true,
          orderId: 'order123',
          key: 'key123',
          transactionRef: 'txn123',
          txnId: 123,
          message: '',
        );
  }

  @override
  noSuchMethod(Invocation invocation) => UnimplementedError();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MobilePrepaidController - Polling Timeout', () {
    test('1. Always-PROCESSING repository stops polling at short deadline', () async {
      final fakeRepo = FakeMobilePrepaidRepository(
        statusResponse: PrepaidTransactionStatus(
          status: 'PROCESSING',
          message: '',
          amount: '100.00',
          operatorName: 'Test Operator',
          mobile: '9876543210',
          paymentMode: 'Online',
          walletAmount: '0.00',
          razorpayAmount: '100.00',
          transactionId: 'txn123',
          updatedAt: DateTime.now().toIso8601String(),
          raw: {},
        ),
      );

      final controller = MobilePrepaidController(repository: fakeRepo);
      final fakeClock = FakeClock();
      final shortDeadline = PollingDeadline.fake(
        const Duration(milliseconds: 100),
        clock: fakeClock,
      );

      // Call public method with fake deadline
      await controller.verifyRechargeStatus(
        transactionRef: 'txn123',
        deadline: shortDeadline,
      );

      // Verify polling stopped and returned PROCESSING
      expect(controller.state.rechargeStatus, 'PROCESSING');
      expect(controller.state.verifiedTransaction?.isProcessing, true);
      
      // With 100ms deadline and 10ms per request + 2s poll interval,
      // only the initial request should complete before deadline check
      expect(fakeRepo.requestCount, 1);
    });

    test('2. No additional repository call after deadline is exceeded', () async {
      final fakeRepo = FakeMobilePrepaidRepository(
        statusResponse: PrepaidTransactionStatus(
          status: 'PROCESSING',
          message: '',
          amount: '100.00',
          operatorName: 'Test Operator',
          mobile: '9876543210',
          paymentMode: 'Online',
          walletAmount: '0.00',
          razorpayAmount: '100.00',
          transactionId: 'txn123',
          updatedAt: DateTime.now().toIso8601String(),
          raw: {},
        ),
      );

      final controller = MobilePrepaidController(repository: fakeRepo);
      final fakeClock = FakeClock();
      
      // Set deadline to 50ms - only enough for initial request
      final shortDeadline = PollingDeadline.fake(
        const Duration(milliseconds: 50),
        clock: fakeClock,
      );

      await controller.verifyRechargeStatus(
        transactionRef: 'txn123',
        deadline: shortDeadline,
      );

      expect(controller.state.rechargeStatus, 'PROCESSING');
      expect(controller.state.verifiedTransaction?.isProcessing, true);
      expect(fakeRepo.requestCount, 1); // Only initial request
    });

    test('3. Fast SUCCESS reaches expected success state', () async {
      final fakeRepo = FakeMobilePrepaidRepository(
        statusResponse: PrepaidTransactionStatus(
          status: 'SUCCESS',
          message: 'Recharge successful',
          amount: '100.00',
          operatorName: 'Test Operator',
          mobile: '9876543210',
          paymentMode: 'Online',
          walletAmount: '0.00',
          razorpayAmount: '100.00',
          transactionId: 'txn123',
          updatedAt: DateTime.now().toIso8601String(),
          raw: {},
        ),
      );

      final controller = MobilePrepaidController(repository: fakeRepo);

      // Call the public verifyRechargeStatus method
      await controller.verifyRechargeStatus(transactionRef: 'txn123');

      expect(controller.state.rechargeStatus, 'SUCCESS');
      expect(controller.state.verifiedTransaction?.isSuccess, true);
      expect(fakeRepo.requestCount, 1); // Only one request for immediate success
    });

    test('4. Real FAILURE follows existing failure path', () async {
      final fakeRepo = FakeMobilePrepaidRepository(
        statusResponse: PrepaidTransactionStatus(
          status: 'FAILED',
          message: 'Recharge failed',
          amount: '100.00',
          operatorName: 'Test Operator',
          mobile: '9876543210',
          paymentMode: 'Online',
          walletAmount: '0.00',
          razorpayAmount: '100.00',
          transactionId: 'txn123',
          updatedAt: DateTime.now().toIso8601String(),
          raw: {},
        ),
      );

      final controller = MobilePrepaidController(repository: fakeRepo);

      await controller.verifyRechargeStatus(transactionRef: 'txn123');

      expect(controller.state.rechargeStatus, 'FAILED');
      expect(controller.state.verifiedTransaction?.isFailed, true);
      expect(fakeRepo.requestCount, 1);
    });

    test('5. Hung request returns at deadline without waiting indefinitely', () async {
      final fakeRepo = FakeMobilePrepaidRepository(
        statusResponse: PrepaidTransactionStatus(
          status: 'PROCESSING',
          message: '',
          amount: '100.00',
          operatorName: 'Test Operator',
          mobile: '9876543210',
          paymentMode: 'Online',
          walletAmount: '0.00',
          razorpayAmount: '100.00',
          transactionId: 'txn123',
          updatedAt: DateTime.now().toIso8601String(),
          raw: {},
        ),
        hungRequest: true,
      );

      final controller = MobilePrepaidController(repository: fakeRepo);
      final fakeClock = FakeClock();
      
      // Set deadline to 50ms - request will hang but should return at deadline
      final shortDeadline = PollingDeadline.fake(
        const Duration(milliseconds: 50),
        clock: fakeClock,
      );

      await controller.verifyRechargeStatus(
        transactionRef: 'txn123',
        deadline: shortDeadline,
      );

      // Verify it returned PROCESSING (timeout fallback) despite hung request
      expect(controller.state.rechargeStatus, 'PROCESSING');
      expect(controller.state.verifiedTransaction?.isProcessing, true);
      expect(fakeRepo.requestCount, 1); // Only one request started
    });

    test('6. paymentProcessingDuration is 60 seconds', () {
      expect(paymentProcessingDuration, const Duration(seconds: 60));
    });

    group('Single-Flight Payment Protection', () {
      test('7. Two rapid Pay taps trigger exactly one create-order request', () async {
        final orderCompleter = Completer<RechargeOrderResult>();
        final fakeRepo = FakeMobilePrepaidRepository(
          createOrderCompleter: orderCompleter,
          createOrderResponse: RechargeOrderResult(
            isSuccess: true,
            orderId: 'order123',
            key: 'key123',
            transactionRef: 'txn123',
            txnId: 123,
            message: '',
          ),
        );

        final controller = MobilePrepaidController(repository: fakeRepo);
        
        // Setup required state
        controller.state = controller.state.copyWith(
          mobile: '9876543210',
          operatorInfo: const OperatorInfo(
            operatorName: 'Test Operator',
            circle: 'Test Circle',
            circleCode: 'TC',
          ),
        );

        final plan = const PlanItem(
          amount: 100,
          validity: '30 days',
          description: 'Test Plan',
        );

        // Start first call (will hang on completer)
        final firstCall = controller.createRechargeOrderWithPlan(plan: plan);
        
        // Give the first call time to set the guard
        await Future.delayed(const Duration(milliseconds: 10));
        
        // Verify guard is set
        expect(controller.state.isPaymentInFlight, true);
        expect(fakeRepo.createOrderCount, 1);

        // Second call while guard is active should be blocked immediately
        final secondCall = controller.createRechargeOrderWithPlan(plan: plan);
        expect(secondCall, completes);
        final secondResult = await secondCall;
        expect(secondResult, isNull); // Blocked by guard
        expect(fakeRepo.createOrderCount, 1); // Still only 1 request

        // Complete the first call
        orderCompleter.complete(RechargeOrderResult(
          isSuccess: true,
          orderId: 'order123',
          key: 'key123',
          transactionRef: 'txn123',
          txnId: 123,
          message: '',
        ));
        
        final firstResult = await firstCall;
        expect(firstResult, isNotNull);
        expect(firstResult!.isSuccess, true);
      });

      test('8. Payment failure releases guard and allows retry', () async {
        final fakeRepo = FakeMobilePrepaidRepository(
          createOrderShouldFail: true,
        );

        final controller = MobilePrepaidController(repository: fakeRepo);
        
        // Setup required state
        controller.state = controller.state.copyWith(
          mobile: '9876543210',
          operatorInfo: const OperatorInfo(
            operatorName: 'Test Operator',
            circle: 'Test Circle',
            circleCode: 'TC',
          ),
        );

        final plan = const PlanItem(
          amount: 100,
          validity: '30 days',
          description: 'Test Plan',
        );

        // First call fails
        final result1 = await controller.createRechargeOrderWithPlan(plan: plan);
        expect(result1, isNull);
        expect(controller.state.errorMessage, isNotEmpty);
        expect(controller.state.isPaymentInFlight, false);

        // Now make it succeed
        fakeRepo.createOrderShouldFail = false;
        fakeRepo.createOrderResponse = RechargeOrderResult(
          isSuccess: true,
          orderId: 'order123',
          key: 'key123',
          transactionRef: 'txn123',
          txnId: 123,
          message: '',
        );

        // Retry should succeed
        final result2 = await controller.createRechargeOrderWithPlan(plan: plan);
        expect(result2, isNotNull);
        expect(result2!.isSuccess, true);
      });
    });
  });
}
