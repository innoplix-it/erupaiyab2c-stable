import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../models/transaction_history_entry.dart';
import '../models/transaction_history_filter.dart';
import '../repositories/transaction_history_repository.dart';

class TransactionHistoryState {
  const TransactionHistoryState({
    this.isLoading = false,
    this.isFetchingMore = false,
    this.items = const [],
    this.errorMessage,
    this.selectedDays = 30,
    this.selectedLastYears,
    this.selectedRange,
    this.currentPage = 1,
    this.totalPages = 1,
    this.limit = 20,
  });

  final bool isLoading;
  final bool isFetchingMore;
  final List<TransactionHistoryEntry> items;
  final String? errorMessage;
  final int selectedDays;
  final int? selectedLastYears;
  final DateTimeRange? selectedRange;
  final int currentPage;
  final int totalPages;
  final int limit;

  bool get hasMore => currentPage < totalPages;

  static const _sentinel = Object();

  TransactionHistoryState copyWith({
    bool? isLoading,
    bool? isFetchingMore,
    List<TransactionHistoryEntry>? items,
    String? errorMessage,
    int? selectedDays,
    Object? selectedLastYears = _sentinel,
    Object? selectedRange = _sentinel,
    int? currentPage,
    int? totalPages,
    int? limit,
  }) {
    return TransactionHistoryState(
      isLoading: isLoading ?? this.isLoading,
      isFetchingMore: isFetchingMore ?? this.isFetchingMore,
      items: items ?? this.items,
      errorMessage: errorMessage,
      selectedDays: selectedDays ?? this.selectedDays,
      selectedLastYears: selectedLastYears == _sentinel
          ? this.selectedLastYears
          : selectedLastYears as int?,
      selectedRange: selectedRange == _sentinel
          ? this.selectedRange
          : selectedRange as DateTimeRange?,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      limit: limit ?? this.limit,
    );
  }
}

final transactionHistoryRepositoryProvider =
    Provider<TransactionHistoryRepository>(
  (ref) => TransactionHistoryRepository(),
);

final transactionHistoryControllerProvider =
    StateNotifierProvider<TransactionHistoryController, TransactionHistoryState>(
  (ref) => TransactionHistoryController(
    repository: ref.watch(transactionHistoryRepositoryProvider),
  ),
);

class TransactionHistoryController
    extends StateNotifier<TransactionHistoryState> {
  TransactionHistoryController({required TransactionHistoryRepository repository})
      : _repository = repository,
        super(const TransactionHistoryState());

  final TransactionHistoryRepository _repository;
  TransactionHistoryFilter? _activeFilter;

  /// Single source of truth for the currently applied filter (e.g. the
  /// consumer/service_full_no scope of a View History flow). Persists
  /// across refresh, pagination and retry; only replaced by the next
  /// fetchHistory/applyFilter call.
  TransactionHistoryFilter? get activeFilter => _activeFilter;

  Future<void> fetchHistory({
    int? days,
    DateTimeRange? range,
    int? lastYears,
    TransactionHistoryFilter? filter,
  }) async {
    final resolvedDays = days ?? state.selectedDays;
    _activeFilter = filter;
    state = state.copyWith(
      isLoading: true,
      isFetchingMore: false,
      errorMessage: null,
      currentPage: 1,
      totalPages: 1,
      items: const [],
    );
    try {
      final page = await _repository.fetchHistoryPage(
        days: filter == null && lastYears == null && range == null
            ? resolvedDays
            : null,
        page: 1,
        limit: state.limit,
        fromDate: filter?.fromDate ?? range?.start,
        toDate: filter?.toDate ?? range?.end,
        lastYears: lastYears,
        month: filter?.month,
        status: filter?.status,
        service: filter?.service,
        paymentType: filter?.paymentType,
        minAmount: filter?.minAmount,
        maxAmount: filter?.maxAmount,
        consumerId: filter?.consumerId,
      );
      state = state.copyWith(
        isLoading: false,
        items: page.items,
        selectedDays: resolvedDays,
        selectedLastYears: lastYears,
        selectedRange: range,
        currentPage: page.currentPage,
        totalPages: page.totalPages,
        limit: page.limit,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load transactions. Please try again.',
      );
    }
  }

  Future<void> fetchNextPage() async {
    if (state.isLoading || state.isFetchingMore || !state.hasMore) return;
    state = state.copyWith(isFetchingMore: true, errorMessage: null);
    try {
      final nextPage = state.currentPage + 1;
      final filter = _activeFilter;
      final page = await _repository.fetchHistoryPage(
        days: filter == null && state.selectedLastYears == null && state.selectedRange == null
            ? state.selectedDays
            : null,
        page: nextPage,
        limit: state.limit,
        fromDate: filter?.fromDate ?? state.selectedRange?.start,
        toDate: filter?.toDate ?? state.selectedRange?.end,
        lastYears: state.selectedLastYears,
        month: filter?.month,
        status: filter?.status,
        service: filter?.service,
        paymentType: filter?.paymentType,
        minAmount: filter?.minAmount,
        maxAmount: filter?.maxAmount,
        consumerId: filter?.consumerId,
      );
      state = state.copyWith(
        isFetchingMore: false,
        // Append only genuinely-new rows: server pages can overlap when new
        // transactions shift the pagination window mid-session.
        items: [...state.items, ..._withoutDuplicates(state.items, page.items)],
        currentPage: page.currentPage,
        totalPages: page.totalPages,
        limit: page.limit,
      );
    } catch (_) {
      state = state.copyWith(
        isFetchingMore: false,
        errorMessage: 'Failed to load more transactions.',
      );
    }
  }

  Future<void> applyDaysFilter(int days) async {
    await fetchHistory(days: days, range: null, lastYears: null);
  }

  Future<void> applyDateRange(DateTimeRange range) async {
    await fetchHistory(range: range, lastYears: null);
  }

  Future<void> applyLastYears(int years) async {
    await fetchHistory(lastYears: years, range: null);
  }

  Future<void> applyFilter(TransactionHistoryFilter filter) async {
    await fetchHistory(filter: filter, range: null, lastYears: null);
  }
}

/// Identity keys of a transaction entry (empty ids ignored).
List<String> _entryIds(TransactionHistoryEntry item) => [
      item.transactionId,
      item.pgTransactionId,
      item.ecoinsTransactionId,
      item.referenceId,
      item.bankReferenceId,
    ].map((id) => id.trim()).where((id) => id.isNotEmpty).toList(growable: false);

/// Filters out incoming items whose id already exists in [current].
List<TransactionHistoryEntry> _withoutDuplicates(
  List<TransactionHistoryEntry> current,
  List<TransactionHistoryEntry> incoming,
) {
  final seen = <String>{for (final item in current) ..._entryIds(item)};
  if (seen.isEmpty) return incoming;
  final fresh = <TransactionHistoryEntry>[];
  for (final item in incoming) {
    final ids = _entryIds(item);
    if (ids.isNotEmpty && ids.any(seen.contains)) continue;
    seen.addAll(ids);
    fresh.add(item);
  }
  return fresh;
}
