import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../constants/routes_constant.dart';
import '../../../services/logger_service.dart';
import '../../services/controllers/biller_detail_controller.dart';
import '../../services/models/biller_detail_args.dart';
import '../../services/models/biller_model.dart';
import '../models/bill_reminder_model.dart';
import '../models/notification_item.dart';
import '../repositories/home_repository.dart';
import 'notification_transaction_resolver.dart';

/// Value prefilled in the biller form for [data]: the registered mobile for
/// credit cards and mobile recharges, otherwise the consumer/account number.
String reminderPrefillValue(BillReminderItem data) {
  final paymentType = data.paymentType.trim().toLowerCase();
  final masked = data.maskedIdentifier.trim();
  final mobile = data.customerMobile.trim();
  if (paymentType.contains('credit')) {
    return mobile;
  }
  if (paymentType.contains('mobile') || paymentType.contains('recharge')) {
    if (mobile.isNotEmpty) return mobile;
    return masked;
  }
  if (masked.isNotEmpty) return masked;
  return mobile;
}

/// Arguments for the existing biller payment screen, built from a bill
/// reminder returned by `GET /api/bill-reminders`.
BillerDetailArgs billerDetailArgsForReminder(BillReminderItem reminder) {
  final paymentType = reminder.paymentType.trim();
  final isCreditCard = paymentType.toLowerCase().contains('credit');
  final maskedDigits = reminder.maskedIdentifier.replaceAll(RegExp(r'\D'), '');
  final cardLast4 = maskedDigits.length >= 4
      ? maskedDigits.substring(maskedDigits.length - 4)
      : null;
  final identifier = reminderPrefillValue(reminder);
  final mobile = reminder.customerMobile.trim();
  final prefill = isCreditCard ? mobile : identifier;
  return BillerDetailArgs(
    biller: Biller(
      billerId: reminder.billerId,
      billerName: reminder.billerName,
      icon: reminder.billerIcon,
    ),
    isCreditCard: isCreditCard,
    paymentType: paymentType.isNotEmpty ? paymentType : null,
    mobileNumber: prefill.isNotEmpty ? prefill : null,
    cardLast4: cardLast4,
    autoFetchBill: isCreditCard
        ? mobile.isNotEmpty && cardLast4 != null
        : identifier.isNotEmpty,
    autoOpenPaymentSheet: false,
  );
}

/// Opens the existing biller payment flow for [reminder].
Future<void> openBillReminderPayment(
  BuildContext context,
  WidgetRef ref,
  BillReminderItem reminder,
) {
  final args = billerDetailArgsForReminder(reminder);
  ref
      .read(billerDetailControllerProvider.notifier)
      .selectBiller(args.biller, categoryName: args.paymentType);
  return context.push(RouteConstants.billerDetail, extra: args);
}

/// Finds the bill reminder a "Pay Now" notification refers to. The
/// notification payload carries no biller details, so its `reference_id`
/// must equal the reminder's `id` from `GET /api/bill-reminders`.
class NotificationBillPaymentResolver {
  NotificationBillPaymentResolver(this._repository);

  final HomeRepository _repository;

  static const int pageLimit = 20;
  static const int maxPages = 5;

  Future<NotificationLookup<BillReminderItem>> resolve(
    NotificationItem item,
  ) async {
    final id = item.transactionReferenceId;
    if (id == null) return const NotificationLookup.notFound();
    try {
      for (var page = 1; page <= maxPages; page++) {
        final response = await _repository.fetchBillReminders(
          page: page,
          limit: pageLimit,
        );
        final matches =
            response.items.where((r) => r.id.toString() == id).toList();
        if (matches.length == 1) return NotificationLookup.found(matches.first);
        if (matches.length > 1) return const NotificationLookup.notFound();
        if (page >= response.totalPages || response.items.isEmpty) break;
      }
    } catch (e, stackTrace) {
      logger.error(
        'Failed to resolve bill reminder for notification',
        error: e,
        stackTrace: stackTrace,
      );
      return const NotificationLookup.failed();
    }
    return const NotificationLookup.notFound();
  }
}
