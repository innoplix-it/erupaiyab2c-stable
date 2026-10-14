import '../../../constants/routes_constant.dart';
import '../../../services/logger_service.dart';
import '../../profile/models/transaction_history_entry.dart';
import '../../profile/repositories/transaction_history_repository.dart';
import '../../services/models/credit_card_transaction.dart';
import '../../services/repositories/credit_card_transactions_repository.dart';
import '../models/notification_item.dart';

/// Existing details route and its `extra` for a resolved transaction.
class NotificationTransactionTarget {
  const NotificationTransactionTarget(this.route, this.extra);

  final String route;
  final Object extra;
}

enum NotificationLookupStatus { found, notFound, failed }

/// Result of looking up what a notification refers to. [failed] means the
/// API could not be reached, as opposed to the item not existing.
class NotificationLookup<T> {
  const NotificationLookup.found(T this.value)
      : status = NotificationLookupStatus.found;
  const NotificationLookup.notFound()
      : value = null,
        status = NotificationLookupStatus.notFound;
  const NotificationLookup.failed()
      : value = null,
        status = NotificationLookupStatus.failed;

  final T? value;
  final NotificationLookupStatus status;
}

/// Finds the transaction a notification refers to, from any module, using
/// the shared transaction history API, and picks that module's existing
/// details screen.
///
/// Only an exact identifier match is returned. When nothing matches, or more
/// than one different transaction matches, the result is null so the caller
/// never opens another transaction's details.
class NotificationTransactionResolver {
  NotificationTransactionResolver(
    this._repository, {
    CreditCardTransactionsRepository? creditCards,
  }) : _creditCards = creditCards;

  final TransactionHistoryRepository _repository;
  final CreditCardTransactionsRepository? _creditCards;

  static const int pageLimit = 50;
  static const int maxPages = 10;
  static const int creditCardPageLimit = 20;
  static const int creditCardMaxPages = 5;

  /// Notifications usually arrive shortly after the payment; the extra days
  /// cover pending payments that settle later.
  static const Duration lookBack = Duration(days: 30);

  /// The details screen to open for [item], or null when its transaction
  /// cannot be identified exactly.
  Future<NotificationTransactionTarget?> resolveTarget(
    NotificationItem item,
  ) async =>
      (await lookupTarget(item)).value;

  Future<NotificationLookup<NotificationTransactionTarget>> lookupTarget(
    NotificationItem item,
  ) async {
    final TransactionHistoryEntry? entry;
    try {
      entry = await _find(item);
    } catch (e, stackTrace) {
      logger.error(
        'Failed to resolve notification transaction',
        error: e,
        stackTrace: stackTrace,
      );
      return const NotificationLookup.failed();
    }
    if (entry == null) return const NotificationLookup.notFound();
    return NotificationLookup.found(await _targetFor(entry));
  }

  Future<NotificationTransactionTarget> _targetFor(
    TransactionHistoryEntry entry,
  ) async {
    final creditCard = await _creditCardTransactionFor(entry);
    if (creditCard != null) {
      return NotificationTransactionTarget(
        RouteConstants.creditCardTransactionDetail,
        creditCard,
      );
    }
    return NotificationTransactionTarget(
      RouteConstants.transactionDetailForStatus(entry.paymentStatus),
      entry,
    );
  }

  Future<TransactionHistoryEntry?> resolve(NotificationItem item) async {
    try {
      return await _find(item);
    } catch (e, stackTrace) {
      logger.error(
        'Failed to resolve notification transaction',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  Future<TransactionHistoryEntry?> _find(NotificationItem item) async {
    final id = item.transactionReferenceId;
    if (id == null) return null;

    final createdAt = item.createdAt;
    final fromDate = createdAt?.subtract(lookBack);
    final toDate = createdAt?.add(const Duration(days: 1));

    for (var page = 1; page <= maxPages; page++) {
      final result = await _repository.fetchHistoryPage(
        page: page,
        limit: pageLimit,
        fromDate: fromDate,
        toDate: toDate,
        lastYears: createdAt == null ? 1 : null,
      );
      final matches = result.items.where((e) => matchesId(e, id)).toList();
      if (matches.isNotEmpty) return _single(matches);
      if (!result.hasMore || result.items.isEmpty) return null;
    }
    return null;
  }

  static bool isCreditCardPayment(TransactionHistoryEntry entry) {
    final type =
        entry.paymentType.toLowerCase().replaceAll(RegExp(r'[\s_-]'), '');
    return type.contains('creditcard');
  }

  /// Credit card payments have their own details screen, fed by the card's
  /// transaction list. Falls back to null (generic details) when the card
  /// list does not hold exactly this payment.
  Future<CreditCardTransaction?> _creditCardTransactionFor(
    TransactionHistoryEntry entry,
  ) async {
    final repository = _creditCards;
    final card = entry.maskedIdentifier.trim();
    if (repository == null || card.isEmpty || !isCreditCardPayment(entry)) {
      return null;
    }
    final ids = {
      entry.transactionId,
      entry.pgTransactionId,
      entry.bankReferenceId,
      entry.rrn,
    }.map((v) => v.trim().toLowerCase()).where((v) => v.isNotEmpty).toSet();
    if (ids.isEmpty) return null;

    bool sameIds(CreditCardTransaction t) => [
          t.paymentTransactionId,
          t.bankReferenceId,
          t.rrn,
        ].any((v) => ids.contains(v.trim().toLowerCase()));

    try {
      for (var page = 1; page <= creditCardMaxPages; page++) {
        final result = await repository.fetchTransactions(
          maskedIdentifier: card,
          page: page,
          limit: creditCardPageLimit,
        );
        final matches = result.items.where(sameIds).toList();
        if (matches.isNotEmpty) {
          final first = matches.first;
          final single = matches.every(
            (t) => t.paymentTransactionId == first.paymentTransactionId,
          );
          return single ? first : null;
        }
        if (page >= result.totalPages || result.items.isEmpty) return null;
      }
    } catch (e, stackTrace) {
      logger.error(
        'Failed to load credit card transaction for notification',
        error: e,
        stackTrace: stackTrace,
      );
    }
    return null;
  }

  static bool matchesId(TransactionHistoryEntry entry, String id) {
    final target = id.trim().toLowerCase();
    return [
      entry.referenceId,
      entry.transactionId,
      entry.pgTransactionId,
      entry.ecoinsTransactionId,
      entry.bankReferenceId,
      entry.rrn,
    ].any((value) {
      final candidate = value.trim().toLowerCase();
      return candidate.isNotEmpty && candidate == target;
    });
  }

  static TransactionHistoryEntry? _single(
    List<TransactionHistoryEntry> matches,
  ) {
    final first = matches.first;
    final sameTransaction = matches.every(
      (e) =>
          e.transactionId == first.transactionId &&
          e.referenceId == first.referenceId,
    );
    return sameTransaction ? first : null;
  }
}
