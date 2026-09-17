// ignore_for_file: deprecated_member_use

import 'package:e_rupaiya/features/mobile_prepaid/models/plan_item.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/routes_constant.dart';
import '../../../widgets/app_snackbar.dart';
import '../../../widgets/custom_elevated_button.dart';
import '../../../widgets/k_dialog.dart';
import '../../../widgets/payment_processing_loader.dart';
import '../../../widgets/payment_success_flow.dart';
import '../../paymentgateway/razorpay_guard.dart';
import '../../paymentgateway/razorpay_service.dart';
import '../../profile/controllers/profile_controller.dart';
import '../../profile/views/transaction_detail_screen.dart';
import '../../services/controllers/biller_detail_controller.dart';
import '../../services/models/biller_detail_state.dart';
import '../../services/models/recharge_status_result.dart';
import '../controllers/mobile_prepaid_controller.dart';
import '../models/prepaid_transaction_status.dart';

enum _PaymentOutcome {
  success,
  pending,
  failure,
  insufficient,
}

void _openPaymentResultFlow(
  BuildContext context, {
  required _PaymentOutcome outcome,
  required double amount,
  required String billerName,
  required String txId,
  String? transactionDateTime,
  PrepaidTransactionStatus? prepaidStatus,
  RechargeStatusResult? rechargeStatus,
  String? paymentTypeOverride,
}) {
  final fallbackStatus = switch (outcome) {
    _PaymentOutcome.success => 'SUCCESS',
    _PaymentOutcome.pending => 'PENDING',
    _PaymentOutcome.failure || _PaymentOutcome.insufficient => 'FAILED',
  };
  final entry = rechargeStatus != null
      ? buildPaymentFlowTransactionEntryFromRechargeStatus(
          status: rechargeStatus,
          fallbackStatus: fallbackStatus,
          fallbackPaymentType: (paymentTypeOverride?.trim().isNotEmpty ?? false)
              ? paymentTypeOverride!.trim()
              : 'BILLPAY',
          fallbackBillerName: billerName,
          fallbackAmount: amount,
          fallbackTransactionId: txId,
          fallbackTransactionTime: transactionDateTime,
        )
      : buildPaymentFlowTransactionEntryFromPrepaidStatus(
          status: prepaidStatus,
          fallbackStatus: fallbackStatus,
          fallbackPaymentType: (paymentTypeOverride?.trim().isNotEmpty ?? false)
              ? paymentTypeOverride!.trim()
              : 'Mobile Prepaid',
          fallbackBillerName: billerName,
          fallbackAmount: amount,
          fallbackTransactionId: txId,
          fallbackTransactionTime: transactionDateTime,
        );

  void goHome(BuildContext localContext) {
    // Refresh wallet balance when returning home after any payment
    try {
      ProviderScope.containerOf(localContext)
          .read(profileControllerProvider.notifier)
          .fetchProfile();
    } catch (_) {}
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!localContext.mounted) return;
      localContext.go(RouteConstants.home);
    });
  }

  final isFailure = outcome == _PaymentOutcome.failure ||
      outcome == _PaymentOutcome.insufficient;
  void Function(BuildContext) onContinue = isFailure
      ? (screenContext) {
          Navigator.of(screenContext).pop();
        }
      : goHome;

  if (outcome == _PaymentOutcome.success) {
    final amountText =
        '\u20B9${amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 2)}';
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PaymentThankYouScreen(
          title: 'Thank You',
          subtitle: 'for your $amountText payment for mobile recharge',
          highlightedSubtitleText: amountText,
          playSound: true,
          autoNavigateAfter: const Duration(seconds: 2),
          onAutoNavigate: (screenContext) {
            Navigator.of(screenContext).pushReplacement(
              MaterialPageRoute(
                builder: (_) => TransactionDetailScreen(
                  entry: entry,
                  doneLabel: isFailure ? 'Retry Payment' : 'Continue to Home',
                  onDone: isFailure ? () => onContinue(screenContext) : null,
                  onBack: isFailure ? () => goHome(screenContext) : null,
                  navigateHomeOnExit: !isFailure,
                ),
              ),
            );
          },
        ),
      ),
    );
  } else {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TransactionDetailScreen(
          entry: entry,
          doneLabel: isFailure ? 'Retry Payment' : 'Continue to Home',
          onDone: isFailure ? () => onContinue(context) : null,
          onBack: isFailure ? () => goHome(context) : null,
          navigateHomeOnExit: !isFailure,
        ),
      ),
    );
  }
}

class PaymentBottomSheet extends ConsumerStatefulWidget {
  const PaymentBottomSheet({
    super.key,
    required this.amount,
    this.isCreditCardFlow = false,
    this.paymentTypeOverride,
    this.ecoinsRestrictionsPercent,
  });

  final double amount;
  final bool isCreditCardFlow;
  final String? paymentTypeOverride;
  final double? ecoinsRestrictionsPercent;

  @override
  ConsumerState<PaymentBottomSheet> createState() => _PaymentBottomSheetState();
}

class _PaymentBottomSheetState extends ConsumerState<PaymentBottomSheet> {
  bool _useECoins = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(profileControllerProvider.notifier).fetchProfileIfNeeded(),
    );
  }

  double _availableECoins() {
    final balance =
        ref.watch(profileControllerProvider).profile?.walletBalance ?? 0;
    return balance.toDouble();
  }

  double _maxECoinsAllowed(double availableECoins) {
    final percent = widget.ecoinsRestrictionsPercent;
    final ratio = percent == null ? 0.05 : (percent / 100.0);
    final restrictionBase = widget.amount;
    final maxAllowed = restrictionBase * ratio;
    if (maxAllowed.isNaN || maxAllowed.isInfinite) return 0;
    final capped = maxAllowed > widget.amount ? widget.amount : maxAllowed;
    return capped.floorToDouble();
  }

  double _eCoinsApplied(double available) {
    if (!_useECoins) return 0.0;
    final maxAllowed = _maxECoinsAllowed(available);
    if (maxAllowed <= 0) return 0.0;
    final allowed = available < maxAllowed ? available : maxAllowed;
    return allowed;
  }

  double _restrictionPercent() {
    final raw = widget.ecoinsRestrictionsPercent;
    if (raw == null || raw.isNaN || raw.isInfinite) return 5;
    if (raw <= 0) return 0;
    return raw;
  }

  double _remainingAmount(double applied) {
    final remaining = widget.amount - applied;
    return remaining < 0 ? 0 : remaining;
  }

  Future<void> _runWithVerificationLoader(Future<void> Function() task) async {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return PopScope(
          canPop: false,
          child: Dialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 36),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
              child: Row(
                children: [
                  const PaymentProcessingLoader(size: 48),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Verifying payment…',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    try {
      await task();
    } finally {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }
  }

  String _resolvePaymentType(BillerDetailState detailState) {
    final override = widget.paymentTypeOverride?.trim() ?? '';
    if (override.isNotEmpty) return override;
    final category = detailState.billerDetail?.billerCategoryName.trim() ?? '';
    if (category.isNotEmpty) return category;
    return 'BILLPAY';
  }

  Future<void> _verifyAndShow({
    required String transactionRef,
    required double amount,
    required String billerName,
    required String fallbackMessage,
  }) async {
    final controller = ref.read(billerDetailControllerProvider.notifier);
    RechargeStatusResult? status;
    await _runWithVerificationLoader(() async {
      status = await controller.verifyPayAllServicesStatus(
        transactionRef: transactionRef,
      );
    });
    if (!mounted) return;

    // Close the sheet before showing result screen.
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }

    final latestState = ref.read(billerDetailControllerProvider);
    final normalized = (status?.status ?? '').trim().toUpperCase();
    final outcome = normalized == 'SUCCESS'
        ? _PaymentOutcome.success
        : (normalized == 'PENDING'
            ? _PaymentOutcome.pending
            : _PaymentOutcome.failure);
    final txId = (status?.transactionId.trim().isNotEmpty == true)
        ? status!.transactionId.trim()
        : transactionRef;

    _openPaymentResultFlow(
      navigatorKey.currentContext ?? context,
      outcome: outcome,
      amount: amount,
      billerName: billerName,
      txId: txId,
      transactionDateTime: status?.updatedAt,
      rechargeStatus: status,
      paymentTypeOverride: _resolvePaymentType(latestState),
    );

    if (outcome == _PaymentOutcome.failure &&
        latestState.payErrorMessage?.trim().isNotEmpty == true) {
      AppSnackbar.show(
        latestState.payErrorMessage!,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } else if (outcome == _PaymentOutcome.failure &&
        fallbackMessage.isNotEmpty) {
      AppSnackbar.show(
        fallbackMessage,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  Future<void> _startRazorpay({
    required double amount,
    required String billerName,
    required String orderId,
    required String keyOverride,
    required String transactionRef,
  }) async {
    if (!await RazorpayGuard.ensureProfileReadyAndNotPaused(ref)) return;
    await RazorpayService.instance.openCheckout(
      amount: amount,
      name: billerName,
      description: 'Bill payment',
      orderId: orderId,
      keyOverride: keyOverride,
      onSuccess: (_) async {
        await _verifyAndShow(
          transactionRef: transactionRef,
          amount: widget.amount,
          billerName: billerName,
          fallbackMessage: 'Your payment was completed successfully.',
        );
      },
      onFailure: (message) async {
        await _verifyAndShow(
          transactionRef: transactionRef,
          amount: widget.amount,
          billerName: billerName,
          fallbackMessage:
              message.isEmpty ? 'Payment failed. Please try again.' : message,
        );
      },
      onExternalWallet: (_) async {
        await _verifyAndShow(
          transactionRef: transactionRef,
          amount: widget.amount,
          billerName: billerName,
          fallbackMessage:
              'We are verifying your payment. Please wait a moment.',
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final detailState = ref.watch(billerDetailControllerProvider);
    final controller = ref.read(billerDetailControllerProvider.notifier);
    final isPaying = detailState.isPayingBill;
    final availableECoins = _availableECoins();
    final maxAllowedECoins = _maxECoinsAllowed(availableECoins);
    final canUseECoins = availableECoins > 0;
    final eCoinsApplied = _eCoinsApplied(availableECoins);
    final remainingAmount = _remainingAmount(eCoinsApplied);
    final buttonLabel = remainingAmount == 0 ? 'Pay Now' : 'Proceed';
    return AbsorbPointer(
      absorbing: isPaying,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select Payment Options',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                ),
                Text(
                  '\u20B9 ${widget.amount.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Orange progress bar
            Container(
              height: 3,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 10),

            // E-Coins option
            _PaymentOptionTile(
              icon: Icons.monetization_on_outlined,
              iconColor: AppColors.primary,
              title:
                  'E-Coins (${availableECoins.toStringAsFixed(0)}) (Max ${_restrictionPercent().round()}%)',
              subtitle: _useECoins
                  ? 'Using \u20B9${eCoinsApplied.toStringAsFixed(0)} (Max \u20B9${maxAllowedECoins.toStringAsFixed(0)})'
                  : 'Use E-Coins for payment',
              enabled: canUseECoins && maxAllowedECoins > 0,
              trailing: Checkbox(
                value: _useECoins,
                activeColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                onChanged: (canUseECoins && maxAllowedECoins > 0)
                    ? (v) => setState(() => _useECoins = v ?? false)
                    : null,
              ),
              onTap: (canUseECoins && maxAllowedECoins > 0)
                  ? () => setState(() => _useECoins = !_useECoins)
                  : null,
            ),

            const SizedBox(height: 10),
            // const SizedBox(height: 16),

            // Bottom bar: amount + PAY NOW
            SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Text(
                      '\u20B9 ${remainingAmount.toStringAsFixed(0)}',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                    ),
                    const Spacer(),
                    CustomElevatedButton(
                      onPressed: isPaying
                          ? null
                          : () async {
                              final billerName =
                                  detailState.selectedBiller?.billerName ??
                                      'Biller';
                              final paymentType =
                                  _resolvePaymentType(detailState);

                              final order =
                                  await controller.createPayAllServicesOrder(
                                amount: widget.amount,
                                paymentType: paymentType,
                                useWallet: _useECoins,
                                isCreditCardFlow: widget.isCreditCardFlow,
                              );

                              if (!context.mounted) return;
                              if (order == null ||
                                  order.orderId.trim().isEmpty ||
                                  order.key.trim().isEmpty ||
                                  order.transactionRef.trim().isEmpty) {
                                AppSnackbar.show(
                                  ref
                                          .read(billerDetailControllerProvider)
                                          .payErrorMessage ??
                                      'Unable to start payment. Please try again.',
                                  backgroundColor: Colors.red,
                                  textColor: Colors.white,
                                );
                                return;
                              }

                              if (remainingAmount <= 0) {
                                await _verifyAndShow(
                                  transactionRef: order.transactionRef,
                                  amount: widget.amount,
                                  billerName: billerName,
                                  fallbackMessage:
                                      'We are verifying your payment. Please wait a moment.',
                                );
                                return;
                              }

                              await _startRazorpay(
                                amount: remainingAmount,
                                billerName: billerName,
                                orderId: order.orderId,
                                keyOverride: order.key,
                                transactionRef: order.transactionRef,
                              );
                            },
                      label: buttonLabel,
                      isLoading: isPaying,
                      showArrow: false,
                      uppercaseLabel: true,
                      width: null,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PrepaidPaymentBottomSheet extends ConsumerStatefulWidget {
  const PrepaidPaymentBottomSheet({
    super.key,
    required this.plan,
    this.billerName = 'Mobile Prepaid',
    this.ecoinsRestrictionsPercent,
  });

  final PlanItem plan;
  final String billerName;
  final double? ecoinsRestrictionsPercent;

  @override
  ConsumerState<PrepaidPaymentBottomSheet> createState() =>
      _PrepaidPaymentBottomSheetState();
}

class _PrepaidPaymentBottomSheetState
    extends ConsumerState<PrepaidPaymentBottomSheet> {
  bool _useECoins = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(profileControllerProvider.notifier).fetchProfileIfNeeded(),
    );
  }

  double _restrictionPercent() {
    final raw = widget.ecoinsRestrictionsPercent;
    if (raw == null || raw.isNaN || raw.isInfinite) return 5;
    if (raw <= 0) return 0;
    return raw;
  }

  Future<void> _runWithVerificationLoader(Future<void> Function() task) async {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return PopScope(
          canPop: false,
          child: Dialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 36),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
              child: Row(
                children: [
                  const PaymentProcessingLoader(size: 48),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Verifying payment…',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    try {
      await task();
    } finally {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }
  }

  double _availableECoins() {
    final balance =
        ref.watch(profileControllerProvider).profile?.walletBalance ?? 0;
    return balance.toDouble();
  }

  double _maxECoinsAllowed(double availableECoins) {
    final percent = widget.ecoinsRestrictionsPercent;
    final ratio = percent == null ? 0.05 : (percent / 100.0);
    final restrictionBase = widget.plan.amount.toDouble();
    final maxAllowed = restrictionBase * ratio;
    if (maxAllowed.isNaN || maxAllowed.isInfinite) return 0;
    final capped = maxAllowed > widget.plan.amount
        ? widget.plan.amount.toDouble()
        : maxAllowed;
    // Keep max as whole rupees.
    return capped.floorToDouble();
  }

  double _eCoinsApplied(double available) {
    if (!_useECoins) return 0.0;
    final maxAllowed = _maxECoinsAllowed(available);
    if (maxAllowed <= 0) return 0.0;
    final allowed = available < maxAllowed ? available : maxAllowed;
    return allowed;
  }

  double _remainingAmount(double applied) {
    final remaining = widget.plan.amount - applied;
    return remaining < 0 ? 0 : remaining.toDouble();
  }

  Future<void> _startRazorpay({
    required double amount,
    required String billerName,
    required double walletAmount,
    required double razorpayAmount,
    required String orderId,
    required String keyOverride,
    required String transactionRef,
    Map<String, String>? prefill,
  }) async {
    if (!await RazorpayGuard.ensureProfileReadyAndNotPaused(ref)) return;
    await RazorpayService.instance.openCheckout(
      amount: amount,
      name: billerName,
      description: 'Recharge',
      orderId: orderId,
      keyOverride: keyOverride,
      prefill: prefill,
      onSuccess: (paymentId) async {
        if (!mounted) return;
        await _runWithVerificationLoader(() async {
          await ref
              .read(mobilePrepaidControllerProvider.notifier)
              .verifyRechargeStatus(transactionRef: transactionRef);
        });
        if (!mounted) return;
        final latestState = ref.read(mobilePrepaidControllerProvider);
        final verified = latestState.verifiedTransaction;
        final outcome = verified == null
            ? _PaymentOutcome.pending
            : (verified.isSuccess
                ? _PaymentOutcome.success
                : ((verified.isPending || verified.isProcessing)
                    ? _PaymentOutcome.pending
                    : _PaymentOutcome.failure));
        final resolvedTxId =
            (latestState.rechargeTransactionId ?? '').isNotEmpty
                ? latestState.rechargeTransactionId!
                : paymentId;
        _openPaymentResultFlow(
          context,
          outcome: outcome,
          amount: widget.plan.amount.toDouble(),
          billerName: billerName,
          txId: resolvedTxId,
          transactionDateTime: latestState.rechargeDateTime,
          prepaidStatus: verified,
        );
        final message = latestState.errorMessage?.trim().toLowerCase();
        if (latestState.errorMessage != null &&
            message != 'unable to process recharge') {
          AppSnackbar.show(
            latestState.errorMessage!,
            backgroundColor: Colors.red,
            textColor: Colors.white,
          );
        }
      },
      onFailure: (message) async {
        if (!mounted) return;
        await _runWithVerificationLoader(() async {
          await ref
              .read(mobilePrepaidControllerProvider.notifier)
              .verifyRechargeStatus(transactionRef: transactionRef);
        });
        if (!mounted) return;
        final latestState = ref.read(mobilePrepaidControllerProvider);
        final verified = latestState.verifiedTransaction;
        final outcome = verified == null
            ? _PaymentOutcome.failure
            : (verified.isSuccess
                ? _PaymentOutcome.success
                : ((verified.isPending || verified.isProcessing)
                    ? _PaymentOutcome.pending
                    : _PaymentOutcome.failure));
        final resolvedTxId =
            (latestState.rechargeTransactionId ?? '').isNotEmpty
                ? latestState.rechargeTransactionId!
                : transactionRef;
        _openPaymentResultFlow(
          context,
          outcome: outcome,
          amount: widget.plan.amount.toDouble(),
          billerName: billerName,
          txId: resolvedTxId,
          transactionDateTime: latestState.rechargeDateTime,
          prepaidStatus: verified,
        );
        final fallbackMessage = message.trim().isEmpty
            ? 'Payment failed. Please try again.'
            : message;
        if (verified == null || outcome == _PaymentOutcome.failure) {
          AppSnackbar.show(
            latestState.errorMessage ?? fallbackMessage,
            backgroundColor: Colors.red,
            textColor: Colors.white,
          );
        }
      },
      onExternalWallet: (_) async {
        if (!mounted) return;
        await _runWithVerificationLoader(() async {
          await ref
              .read(mobilePrepaidControllerProvider.notifier)
              .verifyRechargeStatus(transactionRef: transactionRef);
        });
        if (!mounted) return;
        final latestState = ref.read(mobilePrepaidControllerProvider);
        final verified = latestState.verifiedTransaction;
        final outcome = verified == null
            ? _PaymentOutcome.pending
            : (verified.isSuccess
                ? _PaymentOutcome.success
                : ((verified.isPending || verified.isProcessing)
                    ? _PaymentOutcome.pending
                    : _PaymentOutcome.failure));
        final resolvedTxId =
            (latestState.rechargeTransactionId ?? '').isNotEmpty
                ? latestState.rechargeTransactionId!
                : transactionRef;
        _openPaymentResultFlow(
          context,
          outcome: outcome,
          amount: widget.plan.amount.toDouble(),
          billerName: billerName,
          txId: resolvedTxId,
          transactionDateTime: latestState.rechargeDateTime,
          prepaidStatus: verified,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.read(mobilePrepaidControllerProvider.notifier);
    final state = ref.watch(mobilePrepaidControllerProvider);
    final isPaying = state.isRecharging;
    final availableECoins = _availableECoins();
    final maxAllowedECoins = _maxECoinsAllowed(availableECoins);
    final canUseECoins = availableECoins > 0;
    final eCoinsApplied = _eCoinsApplied(availableECoins);
    final remainingAmount = _remainingAmount(eCoinsApplied);
    final buttonLabel = remainingAmount == 0 ? 'Pay Now' : 'Proceed';

    return AbsorbPointer(
      absorbing: isPaying,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select Payment Options',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                ),
                Text(
                  '\u20B9 ${widget.plan.amount}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Orange progress bar
            Container(
              height: 3,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // E-Coins option
            _PaymentOptionTile(
              icon: Icons.monetization_on_outlined,
              iconColor: AppColors.primary,
              title:
                  'E-Coins (${availableECoins.toStringAsFixed(0)}) (Max ${_restrictionPercent().round()}%)',
              subtitle: _useECoins
                  ? 'Using \u20B9${eCoinsApplied.toStringAsFixed(0)} (Max \u20B9${maxAllowedECoins.toStringAsFixed(0)})'
                  : 'Use E-Coins for payment',
              enabled: canUseECoins && maxAllowedECoins > 0,
              trailing: Checkbox(
                value: _useECoins,
                activeColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                onChanged: (canUseECoins && maxAllowedECoins > 0)
                    ? (v) => setState(() => _useECoins = v ?? false)
                    : null,
              ),
              onTap: (canUseECoins && maxAllowedECoins > 0)
                  ? () => setState(() => _useECoins = !_useECoins)
                  : null,
            ),

            // const SizedBox(height: 20),
            const SizedBox(height: 16),

            // Bottom bar: amount + PAY NOW
            SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Text(
                      '\u20B9 ${remainingAmount.toStringAsFixed(0)}',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                    ),
                    const Spacer(),
                    CustomElevatedButton(
                      onPressed: isPaying
                          ? null
                          : () async {
                              if (_useECoins && remainingAmount == 0) {
                                final order = await controller
                                    .createRechargeOrderWithPlan(
                                  plan: widget.plan,
                                  useWallet: _useECoins,
                                );
                                if (!context.mounted) return;
                                if (order == null) {
                                  final latest = ref.read(
                                    mobilePrepaidControllerProvider,
                                  );
                                  AppSnackbar.show(
                                    latest.errorMessage ??
                                        'Failed to create order. Please try again.',
                                    backgroundColor: Colors.red,
                                    textColor: Colors.white,
                                  );
                                  return;
                                }
                                await _runWithVerificationLoader(() async {
                                  await controller.verifyRechargeStatus(
                                    transactionRef: order.transactionRef,
                                  );
                                });
                                if (!context.mounted) return;
                                final latestState =
                                    ref.read(mobilePrepaidControllerProvider);
                                Navigator.of(context).pop();
                                final verified =
                                    latestState.verifiedTransaction;
                                final outcome = verified == null
                                    ? _PaymentOutcome.pending
                                    : (verified.isSuccess
                                        ? _PaymentOutcome.success
                                        : ((verified.isPending ||
                                                verified.isProcessing)
                                            ? _PaymentOutcome.pending
                                            : _PaymentOutcome.failure));
                                final resolvedTxId =
                                    (latestState.rechargeTransactionId ?? '')
                                            .isNotEmpty
                                        ? latestState.rechargeTransactionId!
                                        : '';
                                _openPaymentResultFlow(
                                  context,
                                  outcome: outcome,
                                  amount: widget.plan.amount.toDouble(),
                                  billerName: widget.billerName,
                                  txId: resolvedTxId,
                                  transactionDateTime:
                                      latestState.rechargeDateTime,
                                  prepaidStatus: verified,
                                );
                                if (latestState.errorMessage != null) {
                                  AppSnackbar.show(
                                    latestState.errorMessage!,
                                    backgroundColor: Colors.red,
                                    textColor: Colors.white,
                                  );
                                }
                                return;
                              }

                              final order =
                                  await controller.createRechargeOrderWithPlan(
                                plan: widget.plan,
                                useWallet: _useECoins,
                              );
                              if (!context.mounted) return;
                              if (order == null) {
                                final latest = ref.read(
                                  mobilePrepaidControllerProvider,
                                );
                                AppSnackbar.show(
                                  latest.errorMessage ??
                                      'Failed to create order. Please try again.',
                                  backgroundColor: Colors.red,
                                  textColor: Colors.white,
                                );
                                return;
                              }
                              if (order.orderId.trim().isEmpty ||
                                  order.key.trim().isEmpty) {
                                AppSnackbar.show(
                                  order.message.isNotEmpty
                                      ? order.message
                                      : 'Unable to start payment right now. Please try again.',
                                  backgroundColor: Colors.red,
                                  textColor: Colors.white,
                                );
                                return;
                              }
                              await _startRazorpay(
                                amount: remainingAmount,
                                billerName: widget.billerName,
                                walletAmount: _useECoins ? eCoinsApplied : 0,
                                razorpayAmount: remainingAmount,
                                orderId: order.orderId,
                                keyOverride: order.key,
                                transactionRef: order.transactionRef,
                                prefill: () {
                                  final contact = state.mobile
                                      .replaceAll(RegExp(r'\D'), '')
                                      .trim();
                                  if (contact.isEmpty) return null;
                                  return {'contact': contact};
                                }(),
                              );
                            },
                      label: buttonLabel,
                      isLoading: isPaying,
                      showArrow: false,
                      uppercaseLabel: true,
                      width: null,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentOptionTile extends StatelessWidget {
  const _PaymentOptionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.trailing,
    this.subtitle,
    this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Widget trailing;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor =
        enabled ? iconColor : AppColors.textPrimary.withOpacity(0.35);
    final titleColor = enabled
        ? AppColors.textPrimary
        : AppColors.textPrimary.withOpacity(0.45);
    final subtitleColor = enabled
        ? AppColors.textPrimary.withOpacity(0.5)
        : AppColors.textPrimary.withOpacity(0.35);

    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: effectiveIconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: effectiveIconColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: titleColor,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: subtitleColor,
                          ),
                    ),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}
