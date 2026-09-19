import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../constants/app_error_messages.dart';
import '../../../services/logger_service.dart';
import '../../../utils/error_message_utils.dart';
import '../../home/models/banner_model.dart';
import '../models/latest_transaction.dart';
import '../models/mobile_prepaid_state.dart';
import '../models/my_number_info.dart';
import '../models/operator_info.dart';
import '../models/plan_item.dart';
import '../models/prepaid_transaction_status.dart';
import '../models/recharge_order_result.dart';
import '../repositories/mobile_prepaid_repository.dart';

final mobilePrepaidRepositoryProvider = Provider<MobilePrepaidRepository>(
  (ref) => MobilePrepaidRepository(),
);

final mobilePrepaidControllerProvider =
    StateNotifierProvider<MobilePrepaidController, MobilePrepaidState>(
  (ref) => MobilePrepaidController(
    repository: ref.watch(mobilePrepaidRepositoryProvider),
  ),
);

final latestRechargeTransactionsProvider =
    FutureProvider.autoDispose<List<LatestTransaction>>(
  (ref) async {
    final repo = ref.watch(mobilePrepaidRepositoryProvider);
    return repo.fetchLatestTransactions(service: 'recharge');
  },
);

final mobilePrepaidBannersProvider =
    FutureProvider.autoDispose<List<BannerModel>>(
  (ref) async {
    final repo = ref.watch(mobilePrepaidRepositoryProvider);
    return repo.fetchMobilePrepaidBanners(lang: 'en');
  },
);

final mobilePrepaidMyNumberProvider =
    FutureProvider.autoDispose.family<MyNumberInfo, String>(
  (ref, number) async {
    final repo = ref.watch(mobilePrepaidRepositoryProvider);
    return repo.fetchMyNumber(number: number);
  },
);

class MobilePrepaidController extends StateNotifier<MobilePrepaidState> {
  MobilePrepaidController({required MobilePrepaidRepository repository})
      : _repository = repository,
        super(const MobilePrepaidState());

  final MobilePrepaidRepository _repository;
  static const Duration _processingPollInterval = Duration(seconds: 2);
  static const int _plansPageLimit = 20;

  Future<PrepaidTransactionStatus> _fetchRechargeStatusWithProcessingPoll({
    required String transactionId,
  }) async {
    PrepaidTransactionStatus verified =
        await _repository.fetchRechargeStatus(transactionId: transactionId);
    if (!verified.isProcessing) return verified;

    while (verified.isProcessing) {
      await Future.delayed(_processingPollInterval);
      verified =
          await _repository.fetchRechargeStatus(transactionId: transactionId);
    }
    return verified;
  }

  void reset() {
    state = const MobilePrepaidState();
  }

  void updatePlanSearch(String query) {
    final trimmedQuery = query.trim();
    state = state.copyWith(
      planSearchQuery: query,
      selectedCategory: trimmedQuery.isNotEmpty && state.categories.isNotEmpty
          ? kAllPlansCategory
          : state.selectedCategory,
    );
  }

  void clearError() {
    if (state.errorMessage == null) return;
    state = state.copyWith(errorMessage: null);
  }

  void selectCategory(String category) {
    state = state.copyWith(
      selectedCategory: category,
      selectedPlan: null,
    );
  }

  void selectPlan(PlanItem plan) {
    state = state.copyWith(selectedPlan: plan);
  }

  void deselectPlan() {
    state = MobilePrepaidState(
      mobile: state.mobile,
      operatorInfo: state.operatorInfo,
      plansByCategory: state.plansByCategory,
      validityFilters: state.validityFilters,
      dataFilters: state.dataFilters,
      filterTags: state.filterTags,
      appliedFilters: state.appliedFilters,
      selectedCategory: state.selectedCategory,
      planSearchQuery: state.planSearchQuery,
      ecoinsRestrictionsPercent: state.ecoinsRestrictionsPercent,
      currentPlansPage: state.currentPlansPage,
      totalPlansPages: state.totalPlansPages,
      totalPlansRecords: state.totalPlansRecords,
      plansPageLimit: state.plansPageLimit,
      hasMorePlans: state.hasMorePlans,
    );
  }

  Future<void> fetchOperatorAndPlans(String mobileInput) async {
    await fetchOperatorAndPlansWithFilters(mobileInput);
  }

  Future<void> fetchOperatorAndPlansWithFilters(
    String mobileInput, {
    String search = '',
    List<String> filters = const [],
  }) async {
    final mobile = _sanitizeMobile(mobileInput);
    if (mobile.length < 10) {
      state = state.copyWith(
        errorMessage: 'Please enter a valid 10 digit mobile number.',
      );
      return;
    }
    state = state.copyWith(
      isFetching: true,
      isRefreshingPlans: false,
      errorMessage: null,
      rechargeMessage: null,
      mobile: mobile,
      operatorInfo: null,
      plansByCategory: const {},
      validityFilters: const [],
      dataFilters: const [],
      filterTags: const [],
      appliedFilters: filters,
      selectedCategory: '',
      selectedPlan: null,
      planSearchQuery: search,
      ecoinsRestrictionsPercent: null,
      currentPlansPage: 1,
      totalPlansPages: 1,
      totalPlansRecords: 0,
      plansPageLimit: _plansPageLimit,
      hasMorePlans: false,
      isFetchingMorePlans: false,
    );
    try {
      final operatorInfo = await _repository.checkOperator(mobile: mobile);
      final result = await _repository.fetchPlans(
        mobile: mobile,
        operatorName: operatorInfo.operatorName,
        circleCode: operatorInfo.circleCode,
        search: search,
        filters: filters,
        page: 1,
        limit: _plansPageLimit,
      );
      final categories = result.plansByCategory.keys.toList();
      state = state.copyWith(
        isFetching: false,
        isRefreshingPlans: false,
        operatorInfo: operatorInfo,
        plansByCategory: result.plansByCategory,
        validityFilters: result.validityFilters,
        dataFilters: result.dataFilters,
        filterTags: result.filterTags,
        ecoinsRestrictionsPercent: result.ecoinsRestrictionsPercent,
        appliedFilters: filters.isNotEmpty ? filters : const ['All'],
        selectedCategory: categories.isNotEmpty ? kAllPlansCategory : '',
        currentPlansPage: result.currentPage,
        totalPlansPages: result.totalPages,
        totalPlansRecords: result.totalRecords,
        plansPageLimit: result.limit,
        hasMorePlans: result.hasMorePages,
      );
    } catch (e, stackTrace) {
      logger.error(
        'Failed to load operator/plans',
        error: e,
        stackTrace: stackTrace,
      );
      state = state.copyWith(
        isFetching: false,
        isRefreshingPlans: false,
        errorMessage: 'Failed to fetch plans. Please try again.',
      );
    }
  }

  Future<void> fetchPlansForSelection({
    required String mobileInput,
    required String operatorName,
    required String circleName,
    required String circleCode,
    String? iconUrl,
    String search = '',
    List<String> filters = const [],
  }) async {
    final mobile = _sanitizeMobile(mobileInput);
    if (mobile.length < 10) {
      state = state.copyWith(
        errorMessage: 'Please enter a valid 10 digit mobile number.',
      );
      return;
    }
    final hasExistingPlans =
        state.operatorInfo != null && state.plansByCategory.isNotEmpty;
    state = state.copyWith(
      isFetching: !hasExistingPlans,
      isRefreshingPlans: hasExistingPlans,
      errorMessage: null,
      rechargeMessage: null,
      mobile: mobile,
      operatorInfo: OperatorInfo.fromSelection(
        operatorName: operatorName,
        circle: circleName,
        circleCode: circleCode,
        iconUrl: iconUrl,
      ),
      plansByCategory: hasExistingPlans ? null : const {},
      validityFilters: hasExistingPlans ? null : const [],
      dataFilters: hasExistingPlans ? null : const [],
      filterTags: hasExistingPlans ? null : const [],
      appliedFilters: filters,
      selectedCategory: hasExistingPlans ? state.selectedCategory : '',
      selectedPlan: null,
      planSearchQuery: search,
      ecoinsRestrictionsPercent:
          hasExistingPlans ? state.ecoinsRestrictionsPercent : null,
      currentPlansPage: hasExistingPlans ? state.currentPlansPage : 1,
      totalPlansPages: hasExistingPlans ? state.totalPlansPages : 1,
      totalPlansRecords: hasExistingPlans ? state.totalPlansRecords : 0,
      plansPageLimit: hasExistingPlans ? state.plansPageLimit : _plansPageLimit,
      hasMorePlans: hasExistingPlans ? state.hasMorePlans : false,
      isFetchingMorePlans: false,
    );
    try {
      final result = await _repository.fetchPlans(
        mobile: mobile,
        operatorName: operatorName,
        circleCode: circleCode,
        search: search,
        filters: filters,
        page: 1,
        limit: _plansPageLimit,
      );
      final categories = result.plansByCategory.keys.toList();
      state = state.copyWith(
        isFetching: false,
        isRefreshingPlans: false,
        plansByCategory: result.plansByCategory,
        validityFilters: result.validityFilters,
        dataFilters: result.dataFilters,
        filterTags: result.filterTags,
        ecoinsRestrictionsPercent: result.ecoinsRestrictionsPercent,
        appliedFilters: filters.isNotEmpty ? filters : const ['All'],
        selectedCategory: categories.isNotEmpty ? kAllPlansCategory : '',
        currentPlansPage: result.currentPage,
        totalPlansPages: result.totalPages,
        totalPlansRecords: result.totalRecords,
        plansPageLimit: result.limit,
        hasMorePlans: result.hasMorePages,
      );
    } catch (e, stackTrace) {
      logger.error(
        'Failed to load operator/plans',
        error: e,
        stackTrace: stackTrace,
      );
      state = state.copyWith(
        isFetching: false,
        isRefreshingPlans: false,
        errorMessage: 'Failed to fetch plans. Please try again.',
      );
    }
  }

  Future<void> loadNextPlansPage() async {
    final info = state.operatorInfo;
    if (info == null ||
        state.isFetching ||
        state.isRefreshingPlans ||
        state.isFetchingMorePlans ||
        !state.hasMorePlans) {
      return;
    }

    state = state.copyWith(
      isFetchingMorePlans: true,
      errorMessage: null,
    );

    try {
      final nextPage = state.currentPlansPage + 1;
      final result = await _repository.fetchPlans(
        mobile: state.mobile,
        operatorName: info.operatorName,
        circleCode: info.circleCode,
        search: state.planSearchQuery,
        filters: state.appliedFilters.where((e) => e != 'All').toList(),
        page: nextPage,
        limit: state.plansPageLimit,
      );

      state = state.copyWith(
        isFetchingMorePlans: false,
        plansByCategory: _mergePlansByCategory(
          existing: state.plansByCategory,
          incoming: result.plansByCategory,
        ),
        validityFilters: result.validityFilters,
        dataFilters: result.dataFilters,
        filterTags: result.filterTags,
        ecoinsRestrictionsPercent: result.ecoinsRestrictionsPercent,
        currentPlansPage: result.currentPage,
        totalPlansPages: result.totalPages,
        totalPlansRecords: result.totalRecords,
        plansPageLimit: result.limit,
        hasMorePlans: result.hasMorePages,
      );
    } catch (e, stackTrace) {
      logger.error(
        'Failed to load next plans page',
        error: e,
        stackTrace: stackTrace,
      );
      state = state.copyWith(
        isFetchingMorePlans: false,
        errorMessage: 'Failed to fetch more plans. Please try again.',
      );
    }
  }

  Map<String, List<PlanItem>> _mergePlansByCategory({
    required Map<String, List<PlanItem>> existing,
    required Map<String, List<PlanItem>> incoming,
  }) {
    final merged = <String, List<PlanItem>>{};
    final keys = <String>{...existing.keys, ...incoming.keys};
    for (final key in keys) {
      merged[key] = <PlanItem>[
        ...?existing[key],
        ...?incoming[key],
      ];
    }
    return merged;
  }

  Future<RechargeOrderResult?> createRechargeOrderWithPlan({
    required PlanItem plan,
    bool useWallet = false,
  }) async {
    if (state.operatorInfo == null || state.mobile.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Please select an operator before proceeding.',
      );
      return null;
    }

    state = state.copyWith(
      isRecharging: true,
      errorMessage: null,
      rechargeMessage: null,
      rechargeStatus: null,
      rechargeTransactionId: null,
      rechargeDateTime: null,
      verifiedTransaction: null,
    );
    try {
      final order = await _repository.createRechargeOrder(
        mobile: state.mobile,
        amount: plan.amount,
        desc: plan.description,
        operatorName: state.operatorInfo!.operatorName,
        useWallet: useWallet,
      );
      state = state.copyWith(isRecharging: false);
      if (!order.isSuccess) {
        state = state.copyWith(
          errorMessage: order.message.isNotEmpty
              ? order.message
              : 'Failed to create order. Please try again.',
        );
        return null;
      }
      return order;
    } catch (e, stackTrace) {
      logger.error(
        'Failed to create recharge order',
        error: e,
        stackTrace: stackTrace,
      );
      state = state.copyWith(
        isRecharging: false,
        errorMessage: _errorMessageFromException(e),
      );
      return null;
    }
  }

  Future<void> verifyRechargeStatus({required String transactionRef}) async {
    state = state.copyWith(
      isRecharging: true,
      errorMessage: null,
      rechargeMessage: null,
      rechargeStatus: null,
      rechargeTransactionId: null,
      rechargeDateTime: null,
      verifiedTransaction: null,
    );
    try {
      final verified = await _fetchRechargeStatusWithProcessingPoll(
        transactionId: transactionRef,
      );
      final effectiveSuccess = verified.isSuccess;
      final isPendingOrProcessing = verified.isPending || verified.isProcessing;
      final effectiveMessage = verified.message.trim();
      state = state.copyWith(
        isRecharging: false,
        rechargeStatus: verified.status,
        rechargeTransactionId: verified.transactionId.isNotEmpty
            ? verified.transactionId
            : transactionRef,
        rechargeDateTime: verified.updatedAt,
        verifiedTransaction: verified,
        rechargeMessage: effectiveSuccess ? effectiveMessage : null,
        errorMessage: isPendingOrProcessing
            ? null
            : (effectiveSuccess
                ? null
                : (effectiveMessage.isEmpty ? null : effectiveMessage)),
      );
    } catch (e, stackTrace) {
      logger.error(
        'Failed to verify recharge status',
        error: e,
        stackTrace: stackTrace,
      );
      state = state.copyWith(
        isRecharging: false,
        errorMessage: _errorMessageFromException(e),
      );
    }
  }

  String _sanitizeMobile(String input) {
    var digits = input.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 10) {
      // Common case: "+91" numbers coming from UI/contacts.
      if (digits.startsWith('91') && digits.length >= 12) {
        digits = digits.substring(digits.length - 10);
      } else {
        digits = digits.substring(digits.length - 10);
      }
    }
    return digits;
  }

  String _errorMessageFromException(Object error) {
    final message = ErrorMessageUtils.from(
      error,
      fallback: 'Recharge failed. Please try again.',
    );
    if (RegExp(r'^\d{3}$').hasMatch(message)) {
      return 'Recharge failed. Please try again.';
    }
    if (message == AppErrorMessages.generic) {
      return 'Recharge failed. Please try again.';
    }
    return message;
  }
}
