import 'package:e_rupaiya/features/mobile_prepaid/controllers/mobile_prepaid_controller.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../utils/error_message_utils.dart';
import '../models/operator_option.dart';
import '../models/region_option.dart';
import '../repositories/mobile_prepaid_repository.dart';

class PrepaidMetaState {
  const PrepaidMetaState({
    this.isLoadingOperators = false,
    this.isLoadingRegions = false,
    this.operators = const [],
    this.regions = const [],
    this.errorMessage,
  });

  final bool isLoadingOperators;
  final bool isLoadingRegions;
  final List<OperatorOption> operators;
  final List<RegionOption> regions;
  final String? errorMessage;

  PrepaidMetaState copyWith({
    bool? isLoadingOperators,
    bool? isLoadingRegions,
    List<OperatorOption>? operators,
    List<RegionOption>? regions,
    String? errorMessage,
  }) {
    return PrepaidMetaState(
      isLoadingOperators: isLoadingOperators ?? this.isLoadingOperators,
      isLoadingRegions: isLoadingRegions ?? this.isLoadingRegions,
      operators: operators ?? this.operators,
      regions: regions ?? this.regions,
      errorMessage: errorMessage,
    );
  }
}

final prepaidMetaControllerProvider =
    StateNotifierProvider<PrepaidMetaController, PrepaidMetaState>(
  (ref) => PrepaidMetaController(
    repository: ref.watch(mobilePrepaidRepositoryProvider),
  ),
);

class PrepaidMetaController extends StateNotifier<PrepaidMetaState> {
  PrepaidMetaController({required MobilePrepaidRepository repository})
      : _repository = repository,
        super(const PrepaidMetaState());

  final MobilePrepaidRepository _repository;

  bool _operatorsLoaded = false;
  bool _regionsLoaded = false;

  Future<void> loadOperatorsIfNeeded() async {
    if (_operatorsLoaded || state.isLoadingOperators) return;
    await _loadOperators();
  }

  Future<void> loadRegionsIfNeeded() async {
    if (_regionsLoaded || state.isLoadingRegions) return;
    await _loadRegions();
  }

  Future<void> refreshOperators() async {
    await _loadOperators(force: true);
  }

  Future<void> refreshRegions() async {
    await _loadRegions(force: true);
  }

  Future<void> _loadOperators({bool force = false}) async {
    if (state.isLoadingOperators) return;
    if (_operatorsLoaded && !force) return;
    state = state.copyWith(isLoadingOperators: true, errorMessage: null);
    try {
      final list = await _repository.fetchOperators();
      if (!mounted) return;
      _operatorsLoaded = true;
      state = state.copyWith(
        isLoadingOperators: false,
        operators: list,
        errorMessage: null,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoadingOperators: false,
        errorMessage: ErrorMessageUtils.from(
          e,
          fallback: 'Failed to load operators. Please try again.',
        ),
      );
    }
  }

  Future<void> _loadRegions({bool force = false}) async {
    if (state.isLoadingRegions) return;
    if (_regionsLoaded && !force) return;
    state = state.copyWith(isLoadingRegions: true, errorMessage: null);
    try {
      final list = await _repository.fetchRegions();
      if (!mounted) return;
      _regionsLoaded = true;
      state = state.copyWith(
        isLoadingRegions: false,
        regions: list,
        errorMessage: null,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoadingRegions: false,
        errorMessage: ErrorMessageUtils.from(
          e,
          fallback: 'Failed to load regions. Please try again.',
        ),
      );
    }
  }
}
