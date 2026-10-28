import 'operator_info.dart';
import 'plan_item.dart';
import 'prepaid_transaction_status.dart';

const String kAllPlansCategory = 'All';

class MobilePrepaidState {
  const MobilePrepaidState({
    this.isFetching = false,
    this.isRefreshingPlans = false,
    this.isFetchingMorePlans = false,
    this.isRecharging = false,
    this.isPaymentInFlight = false,
    this.mobile = '',
    this.operatorInfo,
    this.plansByCategory = const {},
    this.validityFilters = const [],
    this.dataFilters = const [],
    this.filterTags = const [],
    this.appliedFilters = const [],
    this.selectedCategory = '',
    this.planSearchQuery = '',
    this.selectedPlan,
    this.errorMessage,
    this.rechargeMessage,
    this.rechargeStatus,
    this.rechargeTransactionId,
    this.rechargeDateTime,
    this.verifiedTransaction,
    this.ecoinsRestrictionsPercent,
    this.currentPlansPage = 1,
    this.totalPlansPages = 1,
    this.totalPlansRecords = 0,
    this.plansPageLimit = 20,
    this.hasMorePlans = false,
  });

  final bool isFetching;
  final bool isRefreshingPlans;
  final bool isFetchingMorePlans;
  final bool isRecharging;
  final bool isPaymentInFlight;
  final String mobile;
  final OperatorInfo? operatorInfo;
  final Map<String, List<PlanItem>> plansByCategory;
  final List<String> validityFilters;
  final List<String> dataFilters;
  final List<String> filterTags;
  final List<String> appliedFilters;
  final String selectedCategory;
  final String planSearchQuery;
  final PlanItem? selectedPlan;
  final String? errorMessage;
  final String? rechargeMessage;
  final String? rechargeStatus;
  final String? rechargeTransactionId;
  final String? rechargeDateTime;
  final PrepaidTransactionStatus? verifiedTransaction;
  final double? ecoinsRestrictionsPercent;
  final int currentPlansPage;
  final int totalPlansPages;
  final int totalPlansRecords;
  final int plansPageLimit;
  final bool hasMorePlans;

  List<String> get categories => plansByCategory.isEmpty
      ? const <String>[]
      : <String>[kAllPlansCategory, ...plansByCategory.keys];

  List<PlanItem> get allPlans =>
      plansByCategory.values.expand((plans) => plans).toList();

  List<PlanItem> get currentPlans =>
      selectedCategory.isEmpty || selectedCategory == kAllPlansCategory
          ? allPlans
          : plansByCategory[selectedCategory] ?? const <PlanItem>[];

  List<PlanItem> get filteredPlans {
    if (planSearchQuery.isEmpty) return currentPlans;
    final query = planSearchQuery.toLowerCase();
    return currentPlans.where((plan) {
      return plan.amount.toString().contains(query) ||
          plan.validity.toLowerCase().contains(query) ||
          plan.description.toLowerCase().contains(query);
    }).toList();
  }

  List<PlanItem> get visiblePlans {
    if (isRefreshingPlans && currentPlans.isNotEmpty) {
      return currentPlans;
    }
    return filteredPlans;
  }

  static const _sentinel = Object();

  MobilePrepaidState copyWith({
    bool? isFetching,
    bool? isRefreshingPlans,
    bool? isFetchingMorePlans,
    bool? isRecharging,
    bool? isPaymentInFlight,
    String? mobile,
    OperatorInfo? operatorInfo,
    Map<String, List<PlanItem>>? plansByCategory,
    List<String>? validityFilters,
    List<String>? dataFilters,
    List<String>? filterTags,
    List<String>? appliedFilters,
    String? selectedCategory,
    String? planSearchQuery,
    PlanItem? selectedPlan,
    Object? errorMessage = _sentinel,
    Object? rechargeMessage = _sentinel,
    Object? rechargeStatus = _sentinel,
    Object? rechargeTransactionId = _sentinel,
    Object? rechargeDateTime = _sentinel,
    Object? verifiedTransaction = _sentinel,
    Object? ecoinsRestrictionsPercent = _sentinel,
    int? currentPlansPage,
    int? totalPlansPages,
    int? totalPlansRecords,
    int? plansPageLimit,
    bool? hasMorePlans,
  }) {
    return MobilePrepaidState(
      isFetching: isFetching ?? this.isFetching,
      isRefreshingPlans: isRefreshingPlans ?? this.isRefreshingPlans,
      isFetchingMorePlans: isFetchingMorePlans ?? this.isFetchingMorePlans,
      isRecharging: isRecharging ?? this.isRecharging,
      isPaymentInFlight: isPaymentInFlight ?? this.isPaymentInFlight,
      mobile: mobile ?? this.mobile,
      operatorInfo: operatorInfo ?? this.operatorInfo,
      plansByCategory: plansByCategory ?? this.plansByCategory,
      validityFilters: validityFilters ?? this.validityFilters,
      dataFilters: dataFilters ?? this.dataFilters,
      filterTags: filterTags ?? this.filterTags,
      appliedFilters: appliedFilters ?? this.appliedFilters,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      planSearchQuery: planSearchQuery ?? this.planSearchQuery,
      selectedPlan: selectedPlan ?? this.selectedPlan,
      errorMessage: errorMessage == _sentinel
          ? this.errorMessage
          : errorMessage as String?,
      rechargeMessage: rechargeMessage == _sentinel
          ? this.rechargeMessage
          : rechargeMessage as String?,
      rechargeStatus: rechargeStatus == _sentinel
          ? this.rechargeStatus
          : rechargeStatus as String?,
      rechargeTransactionId: rechargeTransactionId == _sentinel
          ? this.rechargeTransactionId
          : rechargeTransactionId as String?,
      rechargeDateTime: rechargeDateTime == _sentinel
          ? this.rechargeDateTime
          : rechargeDateTime as String?,
      verifiedTransaction: verifiedTransaction == _sentinel
          ? this.verifiedTransaction
          : verifiedTransaction as PrepaidTransactionStatus?,
      ecoinsRestrictionsPercent: ecoinsRestrictionsPercent == _sentinel
          ? this.ecoinsRestrictionsPercent
          : ecoinsRestrictionsPercent as double?,
      currentPlansPage: currentPlansPage ?? this.currentPlansPage,
      totalPlansPages: totalPlansPages ?? this.totalPlansPages,
      totalPlansRecords: totalPlansRecords ?? this.totalPlansRecords,
      plansPageLimit: plansPageLimit ?? this.plansPageLimit,
      hasMorePlans: hasMorePlans ?? this.hasMorePlans,
    );
  }
}
