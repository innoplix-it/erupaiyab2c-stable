import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../models/credit_card_month_section.dart';
import '../models/credit_card_transaction.dart';
import '../repositories/credit_card_transactions_repository.dart';

final creditCardTransactionsRepositoryProvider =
    Provider<CreditCardTransactionsRepository>(
  (ref) => CreditCardTransactionsRepository(),
);

final creditCardTransactionsControllerProvider = StateNotifierProvider<
    CreditCardTransactionsController, CreditCardTransactionsState>(
  (ref) => CreditCardTransactionsController(
    repository: ref.watch(creditCardTransactionsRepositoryProvider),
  ),
);

class CreditCardTransactionsState {
  const CreditCardTransactionsState({
    this.isLoading = false,
    this.isRefreshing = false,
    this.items = const [],
    this.errorMessage,
    this.currentPage = 1,
    this.totalPages = 1,
    this.totalRecords = 0,
    this.activeMaskedIdentifier = '',
  });

  final bool isLoading;
  final bool isRefreshing;
  final List<CreditCardTransaction> items;
  final String? errorMessage;
  final int currentPage;
  final int totalPages;
  final int totalRecords;
  final String activeMaskedIdentifier;

  List<CreditCardMonthSection> get monthSections =>
      groupCreditCardTransactionsByMonth(items);

  CreditCardTransactionsState copyWith({
    bool? isLoading,
    bool? isRefreshing,
    List<CreditCardTransaction>? items,
    String? errorMessage,
    int? currentPage,
    int? totalPages,
    int? totalRecords,
    String? activeMaskedIdentifier,
  }) {
    return CreditCardTransactionsState(
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      items: items ?? this.items,
      errorMessage: errorMessage,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      totalRecords: totalRecords ?? this.totalRecords,
      activeMaskedIdentifier:
          activeMaskedIdentifier ?? this.activeMaskedIdentifier,
    );
  }
}

class CreditCardTransactionsController
    extends StateNotifier<CreditCardTransactionsState> {
  CreditCardTransactionsController({
    required CreditCardTransactionsRepository repository,
  })  : _repository = repository,
        super(const CreditCardTransactionsState());

  final CreditCardTransactionsRepository _repository;
  int _requestCounter = 0;

  Future<void> fetchTransactions({
    required String maskedIdentifier,
    bool isRefresh = false,
    int limit = 10,
    int? page,
  }) async {
    final cleanMasked = maskedIdentifier.trim();
    if (cleanMasked.isEmpty) {
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        items: const [],
        errorMessage: 'Masked identifier is missing.',
        activeMaskedIdentifier: '',
      );
      return;
    }

    final requestId = ++_requestCounter;
    final isDifferentCard = state.activeMaskedIdentifier != cleanMasked;

    if (isDifferentCard || !isRefresh) {
      state = CreditCardTransactionsState(
        isLoading: true,
        isRefreshing: false,
        items: const [],
        errorMessage: null,
        activeMaskedIdentifier: cleanMasked,
      );
    } else {
      state = state.copyWith(
        isRefreshing: true,
        errorMessage: null,
        activeMaskedIdentifier: cleanMasked,
      );
    }

    try {
      final requestedPage = page ?? 1;
      // 1. Fetch first page
      final firstPage = await _repository.fetchTransactions(
        maskedIdentifier: cleanMasked,
        page: requestedPage,
        limit: limit,
      );

      if (_requestCounter != requestId) return;

      final allItems = <CreditCardTransaction>[...firstPage.items];
      final seenIds = <String>{};
      for (final item in firstPage.items) {
        final id = _transactionId(item);
        if (id.isNotEmpty) seenIds.add(id);
      }

      final totalPages = firstPage.totalPages;
      int currentPage = requestedPage;

      // 2. Fetch all subsequent pages if caller did not restrict to a single page
      if (page == null) {
        const maxPages = 50;
        bool hasMore(int p, int lastPageCount, int declaredTotal) {
          if (declaredTotal > 1) {
            return p < declaredTotal;
          }
          return lastPageCount >= limit;
        }

        while (hasMore(currentPage, firstPage.items.length, totalPages) &&
            currentPage < maxPages) {
          currentPage++;
          final nextPage = await _repository.fetchTransactions(
            maskedIdentifier: cleanMasked,
            page: currentPage,
            limit: limit,
          );

          if (_requestCounter != requestId) return;

          if (nextPage.items.isEmpty) {
            break;
          }

          for (final item in nextPage.items) {
            final id = _transactionId(item);
            if (id.isEmpty || seenIds.add(id)) {
              allItems.add(item);
            }
          }

          if (nextPage.items.length < limit && totalPages <= 1) {
            break;
          }
        }
      }

      if (_requestCounter != requestId) return;

      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        items: allItems,
        currentPage: currentPage,
        totalPages: totalPages > currentPage ? totalPages : currentPage,
        totalRecords: firstPage.totalRecords > allItems.length
            ? firstPage.totalRecords
            : allItems.length,
        errorMessage: null,
        activeMaskedIdentifier: cleanMasked,
      );
    } catch (e) {
      if (_requestCounter != requestId) return;
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        errorMessage: 'Failed to fetch transactions. Please try again.',
        items: (isRefresh && !isDifferentCard) ? state.items : const [],
      );
    }
  }

  static String _transactionId(CreditCardTransaction item) {
    if (item.paymentTransactionId.trim().isNotEmpty) {
      return item.paymentTransactionId.trim();
    }
    if (item.bankReferenceId.trim().isNotEmpty) {
      return item.bankReferenceId.trim();
    }
    if (item.rrn.trim().isNotEmpty) {
      return item.rrn.trim();
    }
    return '${item.billerName}_${item.transactionTime}_${item.amount}_${item.maskedIdentifier}';
  }
}
