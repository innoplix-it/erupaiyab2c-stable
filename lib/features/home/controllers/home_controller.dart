import 'package:dio/dio.dart';
import 'package:e_rupaiya/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../services/logger_service.dart';
import '../models/credit_card_item.dart';
import '../models/home_state.dart';
import '../models/quick_actions_model.dart';
import '../repositories/home_repository.dart';
import '../services/home_quick_actions_cache.dart';

final homeRepositoryProvider = Provider<HomeRepository>(
  (ref) => HomeRepository(),
);

final homeControllerProvider = StateNotifierProvider<HomeController, HomeState>(
  (ref) => HomeController(
    repository: ref.watch(homeRepositoryProvider),
  ),
);

class HomeController extends StateNotifier<HomeState> {
  HomeController({required HomeRepository repository})
      : _repository = repository,
        _quickActionsCache = HomeQuickActionsCache(),
        super(const HomeState());

  final HomeRepository _repository;
  final HomeQuickActionsCache _quickActionsCache;

  DateTime? _lastQuickActionsFetchedAt;
  DateTime? _lastAllQuickActionsFetchedAt;
  Future<void>? _quickActionsInFlight;
  Future<void>? _allQuickActionsInFlight;
  bool _didHydrateQuickActionsFromCache = false;

  Future<void> _hydrateQuickActionsFromCacheIfNeeded() async {
    if (_didHydrateQuickActionsFromCache) return;
    _didHydrateQuickActionsFromCache = true;
    if (state.quickActions != null) return;
    final cached = await _quickActionsCache.read();
    if (cached == null) return;
    state = state.copyWith(
      quickActions: cached.categories,
      banners: cached.banners,
      isNameEmailExist: cached.isNameEmailExist,
      isServerUnavailable: false,
      errorMessage: null,
    );
  }

  Future<void> fetchQuickActionsIfNeeded({
    Duration ttl = const Duration(minutes: 5),
    bool force = false,
  }) async {
    await _hydrateQuickActionsFromCacheIfNeeded();
    final now = DateTime.now();
    final hasFreshCache = !force &&
        state.quickActions != null &&
        _lastQuickActionsFetchedAt != null &&
        now.difference(_lastQuickActionsFetchedAt!) < ttl;
    if (hasFreshCache) return;

    if (_quickActionsInFlight != null) return _quickActionsInFlight!;
    final shouldShowLoading = state.quickActions == null;
    final future = _fetchQuickActions(showLoading: shouldShowLoading)
        .whenComplete(() => _quickActionsInFlight = null);
    _quickActionsInFlight = future;
    return future;
  }

  Future<void> fetchQuickActions() => _fetchQuickActions(showLoading: true);

  Future<void> _fetchQuickActions({required bool showLoading}) async {
    await _hydrateQuickActionsFromCacheIfNeeded();
    if (showLoading) {
      state = state.copyWith(isFetching: true, errorMessage: null);
    }
    try {
      final result = await _repository.fetchQuickActions();
      _lastQuickActionsFetchedAt = DateTime.now();
      state = state.copyWith(
        isFetching: showLoading ? false : state.isFetching,
        quickActions: result.categories,
        banners: result.banners,
        isNameEmailExist: result.isNameEmailExist,
        isServerUnavailable: false,
        errorMessage: null,
      );
      await _quickActionsCache.write(
        HomeQuickActionsCachePayload(
          categories: result.categories,
          banners: result.banners,
          isNameEmailExist: result.isNameEmailExist,
          cachedAt: DateTime.now(),
        ),
      );
    } catch (e, stackTrace) {
      logger.error(
        'Failed to fetch quick actions',
        error: e,
        stackTrace: stackTrace,
      );
      final cached = await _quickActionsCache.read();
      if (cached != null &&
          (state.quickActions == null || state.quickActions!.isEmpty)) {
        state = state.copyWith(
          isFetching: false,
          quickActions: cached.categories,
          banners: cached.banners,
          isNameEmailExist: cached.isNameEmailExist,
          isServerUnavailable: false,
          errorMessage: null,
        );
        return;
      }

      final isServerUnavailable = _isServerUnavailableError(e);
      if (showLoading || state.quickActions == null) {
        state = state.copyWith(
          isFetching: false,
          isServerUnavailable: isServerUnavailable,
          errorMessage: 'Failed to fetch services. Please try again.',
        );
        return;
      }

      state = state.copyWith(isFetching: state.isFetching);
    }
  }

  Future<void> fetchAllQuickActionsIfNeeded({
    Duration ttl = const Duration(minutes: 10),
    bool force = false,
  }) async {
    final now = DateTime.now();
    final hasFreshCache = !force &&
        state.allQuickActions != null &&
        _lastAllQuickActionsFetchedAt != null &&
        now.difference(_lastAllQuickActionsFetchedAt!) < ttl;
    if (hasFreshCache) return;

    if (_allQuickActionsInFlight != null) return _allQuickActionsInFlight!;
    final shouldShowLoading = state.allQuickActions == null;
    final future = _fetchAllQuickActions(showLoading: shouldShowLoading)
        .whenComplete(() => _allQuickActionsInFlight = null);
    _allQuickActionsInFlight = future;
    return future;
  }

  Future<void> fetchAllQuickActions() =>
      _fetchAllQuickActions(showLoading: true);

  Future<void> _fetchAllQuickActions({required bool showLoading}) async {
    if (showLoading) {
      state = state.copyWith(
        isFetching: true,
        isServerUnavailable: false,
        errorMessage: null,
      );
    }
    try {
      final userId = await Utils.getUserId() ?? '';
      final data = await _repository.fetchAllQuickAction(userId);
      _lastAllQuickActionsFetchedAt = DateTime.now();
      state = state.copyWith(
        isFetching: showLoading ? false : state.isFetching,
        allQuickActions: data.data,
        isServerUnavailable: false,
        errorMessage: null,
      );
    } catch (e, stackTrace) {
      logger.error(
        'Failed to fetch all quick actions',
        error: e,
        stackTrace: stackTrace,
      );
      final isServerUnavailable = _isServerUnavailableError(e);
      if (showLoading || state.allQuickActions == null) {
        state = state.copyWith(
          isFetching: false,
          isServerUnavailable: isServerUnavailable,
          errorMessage: 'Failed to fetch services. Please try again.',
        );
      } else {
        state = state.copyWith(isFetching: state.isFetching);
      }
    }
  }

  Future<void> fetchCreditCardActions() async {
    state = state.copyWith(
      isFetchingCreditCards: true,
      creditCardActions: null,
    );
    try {
      final userId = await Utils.getUserId() ?? '';
      final data = await _repository.fetchCreditCardActions(userId);
      state = state.copyWith(
        isFetchingCreditCards: false,
        creditCardActions: data,
      );
    } catch (e, stackTrace) {
      logger.error(
        'Failed to fetch credit card actions',
        error: e,
        stackTrace: stackTrace,
      );
      state = state.copyWith(
        isFetchingCreditCards: false,
        creditCardActions: const <CreditCardItem>[],
      );
    }
  }

  Future<void> fetchRechargeActions() async {
    state = state.copyWith(
      isFetchingRecharge: true,
      rechargeActions: null,
    );
    try {
      final userId = await Utils.getUserId() ?? '';
      final data = await _repository.fetchRechargeActions(userId);
      state = state.copyWith(
        isFetchingRecharge: false,
        rechargeActions: data,
      );
    } catch (e, stackTrace) {
      logger.error(
        'Failed to fetch recharge actions',
        error: e,
        stackTrace: stackTrace,
      );
      state = state.copyWith(
        isFetchingRecharge: false,
        rechargeActions: const <Data>[],
      );
    }
  }

  void showServerUnavailable() {
    state = state.copyWith(
      isFetching: false,
      isServerUnavailable: true,
      errorMessage: 'Server unavailable',
      quickActions: null,
    );
  }

  Future<bool>? _removeCreditCardInFlight;

  Future<bool> removeCreditCard(String maskedIdentifier) {
    final existing = _removeCreditCardInFlight;
    if (existing != null) return existing;
    final future = _removeCreditCard(maskedIdentifier);
    _removeCreditCardInFlight = future;
    return future.whenComplete(() {
      if (identical(_removeCreditCardInFlight, future)) {
        _removeCreditCardInFlight = null;
      }
    });
  }

  Future<bool> _removeCreditCard(String maskedIdentifier) async {
    final id = maskedIdentifier.trim();
    if (id.isEmpty) return false;
    final previousCards = state.creditCardActions;
    state = state.copyWith(isFetchingCreditCards: true);
    try {
      final ok = await _repository.removeCreditCard(id);
      if (!ok) {
        state = state.copyWith(
          isFetchingCreditCards: false,
          creditCardActions: previousCards,
        );
        return false;
      }
      final userId = await Utils.getUserId() ?? '';
      final data = await _repository.fetchCreditCardActions(userId);
      state = state.copyWith(
        isFetchingCreditCards: false,
        creditCardActions: data,
      );
      return true;
    } catch (e, stackTrace) {
      logger.error(
        'Failed to remove credit card',
        error: e,
        stackTrace: stackTrace,
      );
      state = state.copyWith(
        isFetchingCreditCards: false,
        creditCardActions: previousCards,
      );
      return false;
    }
  }
}

bool _isServerUnavailableError(Object error) {
  return error is DioException && error.response?.statusCode == 503;
}
