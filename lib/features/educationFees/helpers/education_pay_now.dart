import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../widgets/app_snackbar.dart';
import '../../../widgets/processing_overlay.dart';
import '../../paymentgateway/razorpay_guard.dart';
import '../../paymentgateway/razorpay_service.dart';
import '../models/education_fees_responses.dart';
import '../models/education_fees_state.dart';
import '../repositories/education_fees_repository.dart';
import 'education_payment_reconcile.dart';

/// Shared "Pay" hand-off for the education fees flow.
///
/// Creates the backend order, opens Razorpay checkout and routes the result
/// to the processing / reconciliation screens. Used by the payment screen and
/// by the payment summary sheet opened from the tutor profile screen, so both
/// keep exactly the same behaviour.
Future<void> runEducationPayNow({
  required BuildContext context,
  required WidgetRef ref,
  required EducationFeesRepository repository,
  required EducationFeesState state,
  required double amount,
  required double payable,
  String? recipientName,
  String? accountNo,
  String? ifsc,
}) async {
  if (!await RazorpayGuard.ensureProfileReadyAndNotPaused(ref)) return;

  // The tutor profile screen carries the recipient details on screen instead
  // of in the shared controller state, so explicit values win when present.
  final name = _firstNonEmpty(recipientName, state.recipientName);
  final account = _firstNonEmpty(accountNo, state.accountNumber);
  final ifscCode = _firstNonEmpty(ifsc, state.ifsc);

  EducationCreateOrderResponse order;
  try {
    order = await repository.createOrder(
      recipientName: name,
      accountNo: account,
      ifsc: ifscCode,
      amount: amount,
      feeType: state.feeType,
    );
  } catch (e) {
    AppSnackbar.show(
      'Failed to create order. Please try again.',
      backgroundColor: Colors.red,
      textColor: Colors.white,
    );
    return;
  }

  if (!order.status || order.orderId.isEmpty || order.key.isEmpty) {
    AppSnackbar.show(
      order.message.isNotEmpty ? order.message : 'Failed to create order. Please try again.',
      backgroundColor: Colors.red,
      textColor: Colors.white,
    );
    return;
  }

  // Guards against the gateway firing both callbacks (or a callback after the
  // user already left) and starting two processing flows.
  var navigationStarted = false;

  await RazorpayService.instance.openCheckout(
    amount: payable,
    name: name.isEmpty ? 'Education Fees' : name,
    description: 'Tuition fee payment',
    orderId: order.orderId,
    keyOverride: order.key,
    onSuccess: (paymentId) {
      if (navigationStarted) return;
      navigationStarted = true;
      openEducationPaymentProcessing({
        'transactionRefId': order.transactionRefId,
        'paymentType': state.feeType ?? 'Education Fees',
        'recipientName': name,
        'maskedAccount': maskEducationAccount(account),
        'fallbackAmount': payable.toStringAsFixed(2),
        'paymentId': paymentId,
      });
    },
    onFailure: (message) async {
      if (navigationStarted) return;
      navigationStarted = true;
      // A gateway-confirmed failure (user cancelled, card declined, etc.)
      // should NOT start the 60-second polling loop. Instead, do a
      // single-shot backend reconciliation and navigate to the correct
      // status screen immediately.
      await reconcileEducationPaymentOnFailure(
        context: context,
        repository: repository,
        transactionRefId: order.transactionRefId,
        paymentType: state.feeType ?? 'Education Fees',
        recipientName: name,
        maskedAccount: maskEducationAccount(account),
        fallbackAmount: payable.toStringAsFixed(2),
      );
    },
  );
}

/// `****1234` style mask used by the processing and thank-you screens.
String maskEducationAccount(String value) {
  final digits = value.replaceAll(RegExp(r'\D'), '');
  if (digits.length <= 4) return '****';
  final suffix = digits.substring(digits.length - 4);
  return '****$suffix';
}

String _firstNonEmpty(String? primary, String fallback) {
  final value = primary?.trim() ?? '';
  return value.isNotEmpty ? value : fallback;
}
