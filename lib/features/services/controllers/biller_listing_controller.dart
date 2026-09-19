import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../services/logger_service.dart';
import '../../../utils/error_message_utils.dart';
import '../models/biller_listing_state.dart';
import '../repositories/biller_repository.dart';

final billerRepositoryProvider = Provider<BillerRepository>(
  (ref) => BillerRepository(),
);

final billerListingControllerProvider =
    StateNotifierProvider<BillerListingController, BillerListingState>(
  (ref) => BillerListingController(
    repository: ref.watch(billerRepositoryProvider),
  ),
);

class BillerListingController extends StateNotifier<BillerListingState> {
  BillerListingController({required BillerRepository repository})
      : _repository = repository,
        super(const BillerListingState());

  final BillerRepository _repository;
  String? _activeCategoryName;
  String _activeSearchQuery = '';
  Timer? _searchDebounce;

  Future<void> fetchBillers({
    required String categoryName,
    String? searchQuery,
  }) async {
    _activeCategoryName = categoryName;
    _activeSearchQuery = searchQuery?.trim() ?? '';
    state = state.copyWith(
      isFetching: true,
      isFetchingMore: false,
      errorMessage: null,
      currentPage: 1,
      totalPages: 1,
      billers: const [],
    );
    try {
      final page = await _repository.fetchBillers(
        categoryName: categoryName,
        page: 1,
        limit: state.limit,
        search: _activeSearchQuery,
      );
      state = state.copyWith(
        isFetching: false,
        billers: page.billers,
        errorMessage: null,
        currentPage: page.currentPage,
        totalPages: page.totalPages,
        limit: page.limit,
      );
    } catch (e, stackTrace) {
      logger.error(
        'Failed to fetch billers',
        error: e,
        stackTrace: stackTrace,
      );
      state = state.copyWith(
        isFetching: false,
        errorMessage: ErrorMessageUtils.from(
          e,
          fallback: 'Failed to fetch providers. Please try again.',
        ),
      );
    }
  }

  Future<void> fetchNextPage() async {
    final categoryName = _activeCategoryName;
    if (categoryName == null ||
        state.isFetching ||
        state.isFetchingMore ||
        !state.hasMore) {
      return;
    }
    state = state.copyWith(isFetchingMore: true, errorMessage: null);
    try {
      final nextPage = state.currentPage + 1;
      final page = await _repository.fetchBillers(
        categoryName: categoryName,
        page: nextPage,
        limit: state.limit,
        search: _activeSearchQuery,
      );
      state = state.copyWith(
        isFetchingMore: false,
        billers: [...state.billers, ...page.billers],
        currentPage: page.currentPage,
        totalPages: page.totalPages,
        limit: page.limit,
      );
    } catch (e, stackTrace) {
      logger.error(
        'Failed to fetch more billers',
        error: e,
        stackTrace: stackTrace,
      );
      state = state.copyWith(
        isFetchingMore: false,
        errorMessage: ErrorMessageUtils.from(
          e,
          fallback: 'Failed to load more providers. Please try again.',
        ),
      );
    }
  }

  void updateSearch(String query) {
    final categoryName = _activeCategoryName;
    _activeSearchQuery = query.trim();
    _searchDebounce?.cancel();
    if (categoryName == null) return;
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      fetchBillers(
        categoryName: categoryName,
        searchQuery: _activeSearchQuery,
      );
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }
}
