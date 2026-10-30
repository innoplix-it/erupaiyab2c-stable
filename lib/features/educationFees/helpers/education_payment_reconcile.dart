// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/routes_constant.dart';
import '../../../widgets/processing_overlay.dart';
import '../../profile/models/transaction_history_entry.dart';
import '../models/education_fees_responses.dart';
import '../repositories/education_fees_repository.dart';
import '../views/education_payment_thank_you_view.dart';

/// Performs a single-shot backend status reconciliation after a
/// gateway-confirmed payment failure (Razorpay `onFailure`).
///
/// Shows the processing overlay while calling [fetchPaymentStatus] once,
/// then navigates directly to the appropriate status screen:
/// - SUCCESS → [EducationPaymentThankYouView]
/// - FAILED / other terminal → `transactionDetailForStatus(FAILED)`
/// - PENDING / PROCESSING / timeout / error → `transactionDetailForStatus(PENDING)`
///
/// This avoids the full 60-second polling loop (`openEducationPaymentProcessing`)
/// being triggered for payments the gateway has already confirmed as failed.
Future<void> reconcileEducationPaymentOnFailure({
  required BuildContext context,
  required EducationFeesRepository repository,
  required String transactionRefId,
  required String paymentType,
  required String recipientName,
  required String maskedAccount,
  required String fallbackAmount,
  String paymentId = '',
}) async {
  EducationPaymentStatusResponse? result;
  bool timedOut = false;

  try {
    final wait =
        await showPaymentProcessingWhile<EducationPaymentStatusResponse>(
      work: repository.fetchPaymentStatus(transactionRefId: transactionRefId),
      message: 'Verifying Payment',
    );
    result = wait.value;
    timedOut = wait.timedOut;
  } catch (_) {
    // On network error, treat as indeterminate → PENDING.
    timedOut = true;
  }

  if (!context.mounted) return;

  // If a definitive SUCCESS came back (e.g. concurrent success from another
  // session), navigate to the thank-you view — this is rare but correct.
  if (result != null && result.isSuccess) {
    final dynamicPaymentName = result.paymentType.trim().isNotEmpty
        ? result.paymentType.trim()
        : paymentType.trim();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => EducationPaymentThankYouView(
          amount: result!.amount.isNotEmpty ? result.amount : fallbackAmount,
          payableAmount:
              result.amount.isNotEmpty ? result.amount : fallbackAmount,
          transactionTime: result.updatedAt.isNotEmpty
              ? result.updatedAt
              : DateTime.now().toIso8601String(),
          paymentType: dynamicPaymentName,
        ),
      ),
    );
    return;
  }

  // For all non-success outcomes (FAILED, PENDING, PROCESSING, timeout),
  // navigate to the status detail screen with the resolved or fallback status.
  final resolvedStatus = timedOut || result == null
      ? 'PENDING'
      : (result.isPending || result.isProcessing)
          ? result.paymentStatus.trim().toUpperCase()
          : 'FAILED';

  final amount = _fmtEduAmount(
    result?.amount.isNotEmpty == true ? result!.amount : fallbackAmount,
  );
  final payableAmountStr = _fmtEduAmount(
    result?.payableAmount.isNotEmpty == true
        ? result!.payableAmount
        : (result?.amount.isNotEmpty == true ? result!.amount : fallbackAmount),
  );
  final transactionId = result?.transactionId.isNotEmpty == true
      ? result!.transactionId
      : transactionRefId;
  final resolvedPaymentType = result?.paymentType.trim().isNotEmpty == true
      ? result!.paymentType.trim()
      : paymentType;

  final entry = TransactionHistoryEntry(
    paymentStatus: resolvedStatus,
    paymentType: resolvedPaymentType,
    feeType: paymentType.trim().isNotEmpty ? paymentType.trim() : null,
    billerName: recipientName.trim().isEmpty ? paymentType : recipientName,
    maskedIdentifier:
        maskedAccount.trim().isEmpty ? transactionRefId : maskedAccount,
    amount: amount,
    platformFees: '',
    totalAmountCharged: payableAmountStr,
    customerMobile: '',
    iconUrl: '',
    pgTransactionId: paymentId.trim().isEmpty ? transactionRefId : paymentId,
    ecoinsTransactionId: '',
    transactionId: transactionId,
    bankReferenceId: '',
    referenceId: transactionRefId,
    transactionTime: result?.updatedAt.isNotEmpty == true
        ? result!.updatedAt
        : DateTime.now().toIso8601String(),
    method: 'Razorpay / Online',
    methodIcon: '',
    paymentMode: 'Online',
    vpa: '',
    rrn: '',
    customerParams: ensurePaymentTypeCustomerParam(
      params: [
        TransactionCustomerParam(
          label: 'Payment to',
          value:
              recipientName.trim().isEmpty ? paymentType : recipientName.trim(),
        ),
      ],
      paymentType: resolvedPaymentType,
    ),
    amountBreakdown: composeTransactionAmountBreakdown(
      source: {
        'amount': amount,
        'service_charge': result?.serviceCharge ?? '',
        'gst_on_service_charge': result?.gstOnServiceCharge ?? '',
        'payable_amount': result?.payableAmount ?? '',
      },
      fallbackBillAmount: amount,
      fallbackTotal: payableAmountStr,
      billAmountLabel: 'Bill Amount',
    ),
  );

  context.go(
    RouteConstants.transactionDetailForStatus(resolvedStatus),
    extra: <String, dynamic>{
      'entry': entry,
      'fromPaymentFlow': true,
    },
  );
}

String _fmtEduAmount(String raw) {
  final value = raw.trim();
  final parsed = double.tryParse(value.replaceAll(',', ''));
  if (parsed == null) return value;
  return parsed.toStringAsFixed(parsed.truncateToDouble() == parsed ? 0 : 2);
}
