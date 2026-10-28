import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:e_rupaiya/features/services/controllers/biller_detail_controller.dart';
import 'package:e_rupaiya/features/services/models/bill_response_model.dart';
import 'package:e_rupaiya/features/services/models/biller_detail_model.dart';
import 'package:e_rupaiya/features/services/models/biller_model.dart';
import 'package:e_rupaiya/features/services/models/recharge_status_result.dart';
import 'package:e_rupaiya/features/services/models/service_payment_order_result.dart';
import 'package:e_rupaiya/features/services/repositories/biller_repository.dart';
import 'package:e_rupaiya/utils/polling_deadline.dart';
import 'package:e_rupaiya/widgets/payment_processing_loader.dart';

class FakeBillerRepository implements BillerRepository {
  FakeBillerRepository({
    this.statusResponse,
    this.requestCount = 0,
    this.hungRequest = false,
    this.createOrderResponse,
    this.createOrderShouldFail = false,
    this.createOrderCompleter,
  });

  final RechargeStatusResult? statusResponse;
  int requestCount;
  int createOrderCount = 0;
  bool hungRequest;
  final Completer<RechargeStatusResult> _hungCompleter = Completer<RechargeStatusResult>();
  ServicePaymentOrderResult? createOrderResponse;
  bool createOrderShouldFail;
  final Completer<ServicePaymentOrderResult>? createOrderCompleter;

  @override
  Future<RechargeStatusResult> fetchRechargeStatus({
    required String transactionId,
  }) async {
    requestCount++;
    if (hungRequest) {
      return _hungCompleter.future; // Never completes
    }
    return statusResponse ??
        RechargeStatusResult(
          status: 'PROCESSING',
          message: '',
          transactionId: transactionId,
          updatedAt: DateTime.now().toIso8601String(),
          raw: {},
        );
  }

  @override
  Future<ServicePaymentOrderResult> createPayAllServicesOrder({
    required String billerId,
    required Map<String, String> customerParams,
    required String maskedIdentifier,
    required String amount,
    required String refId,
    required String fetchRefId,
    required List<String> paymentModes,
    required String billerName,
    required String paymentType,
    bool useWallet = false,
    String accountHolderName = '',
    String dueDate = '',
  }) async {
    createOrderCount++;
    if (createOrderShouldFail) {
      throw Exception('Create order failed');
    }
    if (createOrderCompleter != null) {
      return createOrderCompleter!.future;
    }
    return createOrderResponse ??
        ServicePaymentOrderResult(
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

  group('BillerDetailController - Polling Timeout', () {
    test('1. Always-PROCESSING repository stops polling at short deadline', () async {
      final fakeRepo = FakeBillerRepository(
        statusResponse: RechargeStatusResult(
          status: 'PROCESSING',
          message: '',
          transactionId: 'txn123',
          updatedAt: DateTime.now().toIso8601String(),
          raw: {},
        ),
      );

      final controller = BillerDetailController(repository: fakeRepo);
      final fakeClock = FakeClock();
      final shortDeadline = PollingDeadline.fake(
        const Duration(milliseconds: 100),
        clock: fakeClock,
      );

      // Call public method with fake deadline
      final result = await controller.verifyPayAllServicesStatus(
        transactionRef: 'txn123',
        deadline: shortDeadline,
      );

      // Verify polling stopped and returned PROCESSING
      expect(result, isNotNull);
      expect(result!.isProcessing, true);
      
      // With 100ms deadline and 10ms per request + 2s poll interval,
      // only the initial request should complete before deadline check
      expect(fakeRepo.requestCount, 1);
    });

    test('2. No additional repository call after deadline is exceeded', () async {
      final fakeRepo = FakeBillerRepository(
        statusResponse: RechargeStatusResult(
          status: 'PROCESSING',
          message: '',
          transactionId: 'txn123',
          updatedAt: DateTime.now().toIso8601String(),
          raw: {},
        ),
      );

      final controller = BillerDetailController(repository: fakeRepo);
      final fakeClock = FakeClock();
      
      // Set deadline to 50ms - only enough for initial request
      final shortDeadline = PollingDeadline.fake(
        const Duration(milliseconds: 50),
        clock: fakeClock,
      );

      final result = await controller.verifyPayAllServicesStatus(
        transactionRef: 'txn123',
        deadline: shortDeadline,
      );

      expect(result, isNotNull);
      expect(result!.isProcessing, true);
      expect(fakeRepo.requestCount, 1); // Only initial request
    });

    test('3. Fast SUCCESS reaches expected success state', () async {
      final fakeRepo = FakeBillerRepository(
        statusResponse: RechargeStatusResult(
          status: 'SUCCESS',
          message: 'Payment successful',
          transactionId: 'txn123',
          updatedAt: DateTime.now().toIso8601String(),
          raw: {},
        ),
      );

      final controller = BillerDetailController(repository: fakeRepo);

      // Call the public verifyPayAllServicesStatus method
      final result = await controller.verifyPayAllServicesStatus(
        transactionRef: 'txn123',
      );

      expect(result, isNotNull);
      expect(result!.isSuccess, true);
      expect(result.status, 'SUCCESS');
      expect(fakeRepo.requestCount, 1); // Only one request for immediate success
    });

    test('4. Real FAILURE follows existing failure path', () async {
      final fakeRepo = FakeBillerRepository(
        statusResponse: RechargeStatusResult(
          status: 'FAILED',
          message: 'Payment failed',
          transactionId: 'txn123',
          updatedAt: DateTime.now().toIso8601String(),
          raw: {},
        ),
      );

      final controller = BillerDetailController(repository: fakeRepo);

      final result = await controller.verifyPayAllServicesStatus(
        transactionRef: 'txn123',
      );

      expect(result, isNotNull);
      expect(result!.isFailed, true);
      expect(result.status, 'FAILED');
      expect(fakeRepo.requestCount, 1);
    });

    test('5. Hung request returns at deadline without waiting indefinitely', () async {
      final fakeRepo = FakeBillerRepository(
        statusResponse: RechargeStatusResult(
          status: 'PROCESSING',
          message: '',
          transactionId: 'txn123',
          updatedAt: DateTime.now().toIso8601String(),
          raw: {},
        ),
        hungRequest: true,
      );

      final controller = BillerDetailController(repository: fakeRepo);
      final fakeClock = FakeClock();
      
      // Set deadline to 50ms - request will hang but should return at deadline
      final shortDeadline = PollingDeadline.fake(
        const Duration(milliseconds: 50),
        clock: fakeClock,
      );

      final result = await controller.verifyPayAllServicesStatus(
        transactionRef: 'txn123',
        deadline: shortDeadline,
      );

      // Verify it returned PROCESSING (timeout fallback) despite hung request
      expect(result, isNotNull);
      expect(result!.isProcessing, true);
      expect(fakeRepo.requestCount, 1); // Only one request started
    });

    test('6. paymentProcessingDuration is 60 seconds', () {
      expect(paymentProcessingDuration, const Duration(seconds: 60));
    });

    group('Single-Flight Payment Protection', () {
      test('7. Two rapid Pay taps trigger exactly one create-order request', () async {
        final orderCompleter = Completer<ServicePaymentOrderResult>();
        final fakeRepo = FakeBillerRepository(
          createOrderCompleter: orderCompleter,
          createOrderResponse: ServicePaymentOrderResult(
            isSuccess: true,
            orderId: 'order123',
            key: 'key123',
            transactionRef: 'txn123',
            txnId: 123,
            message: '',
          ),
        );

        final controller = BillerDetailController(repository: fakeRepo);
        
        // Reset state to ensure clean test
        controller.reset();
        
        // Setup required state
        controller.state = controller.state.copyWith(
          selectedBiller: const Biller(
            billerId: 'biller1',
            billerName: 'Test Biller',
          ),
          billerDetail: const BillerDetail(
            billerId: 'biller1',
            billerName: 'Test Biller',
            billerAliasName: '',
            billerCategoryName: 'Test Category',
            fetchRequirement: '',
            planMdmRequirement: '',
            paymentAmountExactness: '',
            customerParams: [],
            additionalInfo: [],
            paymentModes: [],
          ),
          billResponse: const BillResponse(
            refId: 'ref123',
            fetchRefId: 'fetch123',
            amountInPaisa: '10000',
            accountHolderName: 'Test User',
            dueDate: '2024-01-01',
            billDate: '2024-01-01',
            billPeriod: 'JAN2024',
            billNumber: '123',
            otherDetails: {},
            additionalParams: {},
            approvalRefNum: '',
            note: '',
          ),
          customerParamsInput: {'param1': 'value1'},
        );

        // Start first call (will hang on completer)
        final firstCall = controller.createPayAllServicesOrder(
          amount: 100.0,
          paymentType: 'BILLPAY',
        );
        
        // Give the first call time to set the guard
        await Future.delayed(const Duration(milliseconds: 10));
        
        // Verify guard is set
        expect(controller.state.isPaymentInFlight, true);
        expect(fakeRepo.createOrderCount, 1);

        // Second call while guard is active should be blocked immediately
        final secondCall = controller.createPayAllServicesOrder(
          amount: 100.0,
          paymentType: 'BILLPAY',
        );
        expect(secondCall, completes);
        final secondResult = await secondCall;
        expect(secondResult, isNull); // Blocked by guard
        expect(fakeRepo.createOrderCount, 1); // Still only 1 request

        // Complete the first call
        orderCompleter.complete(ServicePaymentOrderResult(
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
        final fakeRepo = FakeBillerRepository(
          createOrderShouldFail: true,
        );

        final controller = BillerDetailController(repository: fakeRepo);
        
        controller.state = controller.state.copyWith(
          selectedBiller: const Biller(
            billerId: 'biller1',
            billerName: 'Test Biller',
          ),
          billerDetail: const BillerDetail(
            billerId: 'biller1',
            billerName: 'Test Biller',
            billerAliasName: '',
            billerCategoryName: 'Test Category',
            fetchRequirement: '',
            planMdmRequirement: '',
            paymentAmountExactness: '',
            customerParams: [],
            additionalInfo: [],
            paymentModes: [],
          ),
          billResponse: const BillResponse(
            refId: 'ref123',
            fetchRefId: 'fetch123',
            amountInPaisa: '10000',
            accountHolderName: 'Test User',
            dueDate: '2024-01-01',
            billDate: '2024-01-01',
            billPeriod: 'JAN2024',
            billNumber: '123',
            otherDetails: {},
            additionalParams: {},
            approvalRefNum: '',
            note: '',
          ),
          customerParamsInput: {'param1': 'value1'},
        );

        // First call fails
        final result1 = await controller.createPayAllServicesOrder(
          amount: 100.0,
          paymentType: 'BILLPAY',
        );
        expect(result1, isNull);
        expect(controller.state.payErrorMessage, isNotEmpty);
        expect(controller.state.isPaymentInFlight, false);

        // Now make it succeed
        fakeRepo.createOrderShouldFail = false;
        fakeRepo.createOrderResponse = ServicePaymentOrderResult(
          isSuccess: true,
          orderId: 'order123',
          key: 'key123',
          transactionRef: 'txn123',
          txnId: 123,
          message: '',
        );

        // Retry should succeed
        final result2 = await controller.createPayAllServicesOrder(
          amount: 100.0,
          paymentType: 'BILLPAY',
        );
        expect(result2, isNotNull);
        expect(result2!.isSuccess, true);
      });
    });
  });
}
