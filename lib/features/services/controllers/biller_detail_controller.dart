import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../services/logger_service.dart';
import '../../../utils/error_message_utils.dart';
import '../models/biller_detail_model.dart';
import '../models/biller_detail_state.dart';
import '../models/biller_model.dart';
import '../models/recharge_status_result.dart';
import '../models/service_payment_order_result.dart';
import '../repositories/biller_repository.dart';

final billerDetailControllerProvider =
    StateNotifierProvider<BillerDetailController, BillerDetailState>(
  (ref) => BillerDetailController(
    repository: ref.watch(
      Provider<BillerRepository>((ref) => BillerRepository()),
    ),
  ),
);

class BillerDetailController extends StateNotifier<BillerDetailState> {
  BillerDetailController({required BillerRepository repository})
      : _repository = repository,
        super(const BillerDetailState());

  final BillerRepository _repository;
  static const Duration _processingPollInterval = Duration(seconds: 2);

  Future<RechargeStatusResult> _fetchStatusWithProcessingPoll({
    required String transactionRef,
  }) async {
    RechargeStatusResult status =
        await _repository.fetchRechargeStatus(transactionId: transactionRef);
    if (!status.isProcessing) return status;

    while (status.isProcessing) {
      await Future.delayed(_processingPollInterval);
      status =
          await _repository.fetchRechargeStatus(transactionId: transactionRef);
    }
    return status;
  }

  Map<String, String> _withServiceNameIfNeeded({
    required Biller biller,
    required BillerDetail detail,
    required Map<String, String> customerParams,
  }) {
    if (customerParams.containsKey('service_name')) return customerParams;
    final dynamicServiceName =
        (state.selectedCategoryName ?? '').trim().isNotEmpty
            ? state.selectedCategoryName!.trim()
            : (detail.billerCategoryName.trim().isNotEmpty
                ? detail.billerCategoryName.trim()
                : biller.billerName.trim());
    return {
      ...customerParams,
      'service_name': dynamicServiceName,
    };
  }

  void selectBiller(Biller biller, {String? categoryName}) {
    state = const BillerDetailState().copyWith(
      selectedBiller: biller,
      selectedCategoryName: categoryName?.trim(),
    );
    _fetchBillerDetail(
      biller.billerId,
      categoryName: categoryName,
    );
  }

  Future<void> _fetchBillerDetail(
    String billerId, {
    String? categoryName,
  }) async {
    state = state.copyWith(isFetchingDetail: true, errorMessage: null);
    try {
      final detail = await _repository.fetchBillerDetails(
        billerId: billerId,
        categoryName: categoryName,
      );
      state = state.copyWith(
        isFetchingDetail: false,
        billerDetail: detail,
        errorMessage: null,
      );
    } catch (e, stackTrace) {
      logger.error(
        'Failed to fetch biller detail',
        error: e,
        stackTrace: stackTrace,
      );
      state = state.copyWith(
        isFetchingDetail: false,
        errorMessage: ErrorMessageUtils.from(
          e,
          fallback: 'Failed to fetch provider details.',
        ),
      );
    }
  }

  Future<void> fetchBill({
    required Map<String, String> customerParams,
  }) async {
    final biller = state.selectedBiller;
    final detail = state.billerDetail;
    if (biller == null || detail == null) return;

    state = state.copyWith(
      isFetchingBill: true,
      errorMessage: null,
      billFetchNote: null,
      customerParamsInput: customerParams,
    );
    try {
      final paramsForApi = _withServiceNameIfNeeded(
        biller: biller,
        detail: detail,
        customerParams: customerParams,
      );
      final bill = await _repository.fetchBill(
        billerId: biller.billerId,
        customerParams: paramsForApi,
        planMdmRequirement: detail.planMdmRequirement.isNotEmpty
            ? detail.planMdmRequirement
            : 'NOT_SUPPORTED',
      );
      state = state.copyWith(
        isFetchingBill: false,
        billResponse: bill,
        errorMessage: null,
        billFetchNote: null,
      );
    } on BillerApiException catch (e, stackTrace) {
      logger.error(
        'Failed to fetch bill',
        error: e,
        stackTrace: stackTrace,
      );
      state = state.copyWith(
        isFetchingBill: false,
        errorMessage: e.message,
        billFetchNote: (e.note ?? '').trim().isEmpty ? null : e.note!.trim(),
      );
    } catch (e, stackTrace) {
      logger.error(
        'Failed to fetch bill',
        error: e,
        stackTrace: stackTrace,
      );
      state = state.copyWith(
        isFetchingBill: false,
        errorMessage: ErrorMessageUtils.from(
          e,
          fallback: 'Something went wrong. Please try again.',
        ),
        billFetchNote: null,
      );
    }
  }

  // Deprecated: old API `api/bill/pay` is no longer used.
  // Use `createPayAllServicesOrder(...)` + `verifyPayAllServicesStatus(...)`.

  Future<ServicePaymentOrderResult?> createPayAllServicesOrder({
    required double amount,
    required String paymentType,
    bool useWallet = false,
    bool isCreditCardFlow = false,
  }) async {
    final biller = state.selectedBiller;
    final detail = state.billerDetail;
    final bill = state.billResponse;
    final customerParams = state.customerParamsInput ?? {};
    if (biller == null || detail == null || bill == null) return null;

    state = state.copyWith(
      isPayingBill: true,
      payErrorMessage: null,
      payResponse: null,
    );
    try {
      final order = await _repository.createPayAllServicesOrder(
        billerId: biller.billerId,
        customerParams: customerParams,
        maskedIdentifier: _resolveMaskedIdentifier(
          detail.customerParams,
          customerParams,
          forceSecondIndex: isCreditCardFlow,
        ),
        amount: amount.toStringAsFixed(2),
        refId: bill.refId,
        fetchRefId: bill.fetchRefId,
        paymentModes: detail.paymentModes
            .map((mode) => mode.paymentMode)
            .where((mode) => mode.trim().isNotEmpty)
            .toList(),
        billerName: biller.billerName,
        paymentType: paymentType,
        useWallet: useWallet,
      );
      state = state.copyWith(isPayingBill: false);
      if (!order.isSuccess) {
        state = state.copyWith(
          payErrorMessage: order.message.isNotEmpty
              ? order.message
              : 'Failed to create order. Please try again.',
        );
        return null;
      }
      return order;
    } catch (e, stackTrace) {
      logger.error(
        'Failed to create pay-allservices order',
        error: e,
        stackTrace: stackTrace,
      );
      state = state.copyWith(
        isPayingBill: false,
        payErrorMessage: 'Failed to create order. Please try again.',
      );
      return null;
    }
  }

  Future<RechargeStatusResult?> verifyPayAllServicesStatus({
    required String transactionRef,
  }) async {
    state = state.copyWith(isPayingBill: true, payErrorMessage: null);
    try {
      final status =
          await _fetchStatusWithProcessingPoll(transactionRef: transactionRef);
      state = state.copyWith(isPayingBill: false);
      return status;
    } catch (e, stackTrace) {
      logger.error(
        'Failed to verify pay-allservices status',
        error: e,
        stackTrace: stackTrace,
      );
      state = state.copyWith(
        isPayingBill: false,
        payErrorMessage: 'Unable to verify payment status. Please try again.',
      );
      return null;
    }
  }

  String _resolveMaskedIdentifier(
      List<BillerCustomerParam> params, Map<String, String> input,
      {bool forceSecondIndex = false}) {
    if (forceSecondIndex && params.length > 1) {
      final param = params[1];
      final value = input[param.paramName]?.trim() ?? '';
      if (value.isNotEmpty) return value;
    }
    for (final param in params) {
      if (!param.visibility || param.optional) continue;
      final value = input[param.paramName]?.trim() ?? '';
      if (value.isNotEmpty) return value;
    }
    return '';
  }

  void toggleFullDetails() {
    state = state.copyWith(showFullDetails: !state.showFullDetails);
  }

  void clearBill() {
    state = state.copyWith(
      billResponse: null,
      customerParamsInput: null,
      showFullDetails: false,
      isFetchingBill: false,
      payResponse: null,
      payErrorMessage: null,
      errorMessage: null,
    );
  }

  void reset() {
    state = const BillerDetailState();
  }
}
