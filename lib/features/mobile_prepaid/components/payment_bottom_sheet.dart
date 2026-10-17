// ignore_for_file: deprecated_member_use

import 'package:e_rupaiya/features/mobile_prepaid/models/plan_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/file_constants.dart';
import '../../../constants/routes_constant.dart';

import '../../../widgets/app_snackbar.dart';
import '../../../widgets/custom_elevated_button.dart';
import '../../../widgets/k_dialog.dart';
import '../../../widgets/payment_success_flow.dart';
import '../../../widgets/processing_overlay.dart';
import '../../educationFees/views/education_payment_thank_you_view.dart';
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
  bool isMobileRecharge = false,
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
    final paymentName = paymentTypeOverride?.trim().isNotEmpty == true
        ? paymentTypeOverride!.trim()
        : billerName.trim().isNotEmpty
            ? billerName.trim()
            : 'Mobile Recharge';
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => EducationPaymentThankYouView(
          amount: amount
              .toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 2),
          payableAmount: amount
              .toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 2),
          transactionTime: (transactionDateTime?.isNotEmpty == true)
              ? transactionDateTime!
              : DateTime.now().toIso8601String(),
          paymentType: paymentName,
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

  Future<PaymentProcessingWait<T>> _runWithVerificationLoader<T>(
    Future<T> Function() task,
  ) {
    return showPaymentProcessingWhile<T>(work: task());
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
    final wait = await _runWithVerificationLoader(
      () => controller.verifyPayAllServicesStatus(
        transactionRef: transactionRef,
      ),
    );
    if (!mounted) return;

    // Close the sheet before showing result screen.
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }

    final latestState = ref.read(billerDetailControllerProvider);
    final status = wait.value;
    final normalized = (status?.status ?? '').trim().toUpperCase();
    final outcome = wait.timedOut
        ? _PaymentOutcome.pending
        : (normalized == 'SUCCESS'
            ? _PaymentOutcome.success
            : (normalized == 'PENDING' ||
                    normalized == 'PROCESSING' ||
                    normalized.isEmpty
                ? _PaymentOutcome.pending
                : _PaymentOutcome.failure));
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
      isMobileRecharge: false,
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

  Future<void> _onPayPressed({
    required BillerDetailState detailState,
    required double remainingAmount,
  }) async {
    final controller = ref.read(billerDetailControllerProvider.notifier);
    final billerName = detailState.selectedBiller?.billerName ?? 'Biller';
    final paymentType = _resolvePaymentType(detailState);

    final order = await controller.createPayAllServicesOrder(
      amount: widget.amount,
      paymentType: paymentType,
      useWallet: _useECoins,
      isCreditCardFlow: widget.isCreditCardFlow,
    );

    if (!mounted) return;
    if (order == null ||
        order.orderId.trim().isEmpty ||
        order.key.trim().isEmpty ||
        order.transactionRef.trim().isEmpty) {
      AppSnackbar.show(
        ref.read(billerDetailControllerProvider).payErrorMessage ??
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
        fallbackMessage: 'We are verifying your payment. Please wait a moment.',
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
  }

  @override
  Widget build(BuildContext context) {
    final detailState = ref.watch(billerDetailControllerProvider);
    final isPaying = detailState.isPayingBill;
    final availableECoins = _availableECoins();
    final maxAllowedECoins = _maxECoinsAllowed(availableECoins);
    final canUseECoins = availableECoins > 0;
    final eCoinsApplied = _eCoinsApplied(availableECoins);
    final remainingAmount = _remainingAmount(eCoinsApplied);
    final bottomSafe = MediaQuery.paddingOf(context).bottom;
    final maxSheetH = MediaQuery.sizeOf(context).height * 0.88;

    if (widget.isCreditCardFlow) {
      return _buildCreditCardQuickPay(
        context: context,
        detailState: detailState,
        isPaying: isPaying,
        availableECoins: availableECoins,
        maxAllowedECoins: maxAllowedECoins,
        canUseECoins: canUseECoins,
        eCoinsApplied: eCoinsApplied,
        remainingAmount: remainingAmount,
        bottomSafe: bottomSafe,
        maxSheetH: maxSheetH,
      );
    }

    final buttonLabel = remainingAmount == 0 ? 'Pay Now' : 'Proceed';
    return AbsorbPointer(
      absorbing: isPaying,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 0.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Select Payment Options',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 16.sp,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  '\u20B9 ${widget.amount.toStringAsFixed(0)}',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 16.sp,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Container(
              height: 3.h,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 10.h),
            _PaymentOptionTile(
              icon: Icons.monetization_on_outlined,
              iconAsset: FileConstants.favicon,
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
                  borderRadius: BorderRadius.circular(4.r),
                ),
                onChanged: (canUseECoins && maxAllowedECoins > 0)
                    ? (v) => setState(() => _useECoins = v ?? false)
                    : null,
              ),
              onTap: (canUseECoins && maxAllowedECoins > 0)
                  ? () => setState(() => _useECoins = !_useECoins)
                  : null,
            ),
            SizedBox(height: 10.h),
            SafeArea(
              top: false,
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12.h),
                child: Row(
                  children: [
                    Text(
                      '\u20B9 ${remainingAmount.toStringAsFixed(0)}',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 24.sp,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    CustomElevatedButton(
                      onPressed: isPaying
                          ? null
                          : () => _onPayPressed(
                                detailState: detailState,
                                remainingAmount: remainingAmount,
                              ),
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

  Widget _buildCreditCardQuickPay({
    required BuildContext context,
    required BillerDetailState detailState,
    required bool isPaying,
    required double availableECoins,
    required double maxAllowedECoins,
    required bool canUseECoins,
    required double eCoinsApplied,
    required double remainingAmount,
    required double bottomSafe,
    required double maxSheetH,
  }) {
    final bill = detailState.billResponse;
    final billerName = detailState.selectedBiller?.billerName ?? 'Credit Card';
    final customerName = bill?.accountHolderName.trim() ?? '';
    // Masked last-4 is not always on BillResponse; keep a safe placeholder.
    const maskedSuffix = '****';
    final payLabel = 'PAY ₹${remainingAmount.toStringAsFixed(0)}';

    return AbsorbPointer(
      absorbing: isPaying,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxSheetH),
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, bottomSafe + 12.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Quick Pay',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 18.sp,
                        color: AppColors.textPrimary,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.textPrimary,
                        decorationThickness: 1.5,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.of(context).maybePop(),
                    borderRadius: BorderRadius.circular(20.r),
                    child: Padding(
                      padding: EdgeInsets.all(4.w),
                      child: Icon(Icons.close, size: 22.sp),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              Divider(height: 1, color: AppColors.lightBorder),
              SizedBox(height: 12.h),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.28),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Credit Card • XXXX$maskedSuffix',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13.sp,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                Text(
                                  '₹${widget.amount.toStringAsFixed(0)}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14.sp,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 4.h),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    customerName.isEmpty
                                        ? billerName
                                        : customerName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12.sp,
                                      color: const Color(0xFF71717A),
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => Navigator.of(context).maybePop(),
                                  child: Text(
                                    'View Details',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12.sp,
                                      color: AppColors.primary,
                                      decoration: TextDecoration.underline,
                                      decorationColor: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 12.h),
                      _PaymentOptionTile(
                        icon: Icons.monetization_on_outlined,
                        iconAsset: FileConstants.favicon,
                        iconColor: AppColors.primary,
                        title:
                            'E-Coins (${availableECoins.toStringAsFixed(0)})',
                        subtitle: _useECoins
                            ? 'Use E-Coins For Recharge (Rs.${eCoinsApplied.toStringAsFixed(0)})'
                            : 'Use E-Coins For Recharge (Rs.${maxAllowedECoins.toStringAsFixed(0)})',
                        enabled: canUseECoins && maxAllowedECoins > 0,
                        trailing: Checkbox(
                          value: _useECoins,
                          activeColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          onChanged: (canUseECoins && maxAllowedECoins > 0)
                              ? (v) => setState(() => _useECoins = v ?? false)
                              : null,
                        ),
                        onTap: (canUseECoins && maxAllowedECoins > 0)
                            ? () => setState(() => _useECoins = !_useECoins)
                            : null,
                      ),
                      if (_useECoins && eCoinsApplied > 0) ...[
                        SizedBox(height: 10.h),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 8.h,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F8EF),
                            borderRadius: BorderRadius.circular(20.r),
                            border: Border.all(
                              color: const Color(0xFF86EFAC),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.star_rounded,
                                  size: 16.sp, color: Colors.black87),
                              SizedBox(width: 6.w),
                              Expanded(
                                child: Text.rich(
                                  TextSpan(
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textPrimary,
                                    ),
                                    children: [
                                      const TextSpan(text: 'You saved '),
                                      TextSpan(
                                        text:
                                            '₹${eCoinsApplied.toStringAsFixed(0)}',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primary,
                                          fontSize: 12.sp,
                                        ),
                                      ),
                                      const TextSpan(
                                          text: ' for this transaction'),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      SizedBox(height: 10.h),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 12.h,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.35),
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              'Payable Amount:',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                                fontSize: 13.sp,
                              ),
                            ),
                            const Spacer(),
                            if (_useECoins && eCoinsApplied > 0) ...[
                              Text(
                                '₹${widget.amount.toStringAsFixed(0)}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13.sp,
                                  color: const Color(0xFFA1A1AA),
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                              SizedBox(width: 8.w),
                            ],
                            Text(
                              '₹${remainingAmount.toStringAsFixed(0)}',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                                fontSize: 14.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        'UPI',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 14.sp,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'You will continue with Razorpay checkout for UPI and cards.',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w500,
                          fontSize: 11.sp,
                          color: const Color(0xFF71717A),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              CustomElevatedButton(
                onPressed: isPaying
                    ? null
                    : () => _onPayPressed(
                          detailState: detailState,
                          remainingAmount: remainingAmount,
                        ),
                label: payLabel,
                isLoading: isPaying,
                showArrow: false,
                uppercaseLabel: true,
                height: 48.h,
              ),
            ],
          ),
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

  Future<PaymentProcessingWait<T>> _runWithVerificationLoader<T>(
    Future<T> Function() task,
  ) {
    return showPaymentProcessingWhile<T>(work: task());
  }

  _PaymentOutcome _prepaidOutcome({
    required bool timedOut,
    required PrepaidTransactionStatus? verified,
    required bool nullIsFailure,
  }) {
    if (timedOut) return _PaymentOutcome.pending;
    if (verified == null) {
      return nullIsFailure ? _PaymentOutcome.failure : _PaymentOutcome.pending;
    }
    if (verified.isSuccess) return _PaymentOutcome.success;
    if (verified.isPending || verified.isProcessing) {
      return _PaymentOutcome.pending;
    }
    return _PaymentOutcome.failure;
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
    final state = ref.read(mobilePrepaidControllerProvider);
    final paymentName =
        state.operatorInfo?.operatorName.trim().isNotEmpty == true
            ? '${state.operatorInfo!.operatorName.trim()} Recharge'
            : null;

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
        final wait = await _runWithVerificationLoader(() async {
          await ref
              .read(mobilePrepaidControllerProvider.notifier)
              .verifyRechargeStatus(transactionRef: transactionRef);
        });
        if (!mounted) return;
        final latestState = ref.read(mobilePrepaidControllerProvider);
        final verified = latestState.verifiedTransaction;
        final outcome = _prepaidOutcome(
          timedOut: wait.timedOut,
          verified: verified,
          nullIsFailure: false,
        );
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
          paymentTypeOverride: paymentName,
          isMobileRecharge: true,
        );
        final message = latestState.errorMessage?.trim().toLowerCase();
        if (!wait.timedOut &&
            latestState.errorMessage != null &&
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
        final wait = await _runWithVerificationLoader(() async {
          await ref
              .read(mobilePrepaidControllerProvider.notifier)
              .verifyRechargeStatus(transactionRef: transactionRef);
        });
        if (!mounted) return;
        final latestState = ref.read(mobilePrepaidControllerProvider);
        final verified = latestState.verifiedTransaction;
        final outcome = _prepaidOutcome(
          timedOut: wait.timedOut,
          verified: verified,
          nullIsFailure: true,
        );
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
          paymentTypeOverride: paymentName,
          isMobileRecharge: true,
        );
        final fallbackMessage = message.trim().isEmpty
            ? 'Payment failed. Please try again.'
            : message;
        if (!wait.timedOut &&
            (verified == null || outcome == _PaymentOutcome.failure)) {
          AppSnackbar.show(
            latestState.errorMessage ?? fallbackMessage,
            backgroundColor: Colors.red,
            textColor: Colors.white,
          );
        }
      },
      onExternalWallet: (_) async {
        if (!mounted) return;
        final wait = await _runWithVerificationLoader(() async {
          await ref
              .read(mobilePrepaidControllerProvider.notifier)
              .verifyRechargeStatus(transactionRef: transactionRef);
        });
        if (!mounted) return;
        final latestState = ref.read(mobilePrepaidControllerProvider);
        final verified = latestState.verifiedTransaction;
        final outcome = _prepaidOutcome(
          timedOut: wait.timedOut,
          verified: verified,
          nullIsFailure: false,
        );
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
          paymentTypeOverride: paymentName,
          isMobileRecharge: true,
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

    return AbsorbPointer(
      absorbing: isPaying,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 0.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Select Payment Options',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 16.sp,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  '\u20B9 ${widget.plan.amount}',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 16.sp,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),

            // Orange progress bar
            Container(
              height: 3.h,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 20.h),

            // E-Coins option
            _PaymentOptionTile(
              icon: Icons.monetization_on_outlined,
              iconAsset: FileConstants.favicon,
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
                  borderRadius: BorderRadius.circular(4.r),
                ),
                onChanged: (canUseECoins && maxAllowedECoins > 0)
                    ? (v) => setState(() => _useECoins = v ?? false)
                    : null,
              ),
              onTap: (canUseECoins && maxAllowedECoins > 0)
                  ? () => setState(() => _useECoins = !_useECoins)
                  : null,
            ),

            // SizedBox(height: 20.h),
            SizedBox(height: 16.h),

            // Bottom bar: amount + PROCEED
            SafeArea(
              top: false,
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12.h),
                child: Row(
                  children: [
                    Text(
                      '\u20B9 ${remainingAmount.toStringAsFixed(0)}',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 24.sp,
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
                                final wait = await _runWithVerificationLoader(
                                  () async {
                                    await controller.verifyRechargeStatus(
                                      transactionRef: order.transactionRef,
                                    );
                                  },
                                );
                                if (!context.mounted) return;
                                final latestState =
                                    ref.read(mobilePrepaidControllerProvider);
                                Navigator.of(context).pop();
                                final verified =
                                    latestState.verifiedTransaction;
                                final outcome = _prepaidOutcome(
                                  timedOut: wait.timedOut,
                                  verified: verified,
                                  nullIsFailure: false,
                                );
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
                                  isMobileRecharge: true,
                                );
                                if (!wait.timedOut &&
                                    latestState.errorMessage != null) {
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
                      label: 'Proceed',
                      isLoading: isPaying,
                      showArrow: false,
                      uppercaseLabel: false,
                      width: null,
                      labelStyle: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 14.sp,
                        color: Colors.white,
                      ),
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
    this.icon,
    this.iconAsset,
    required this.iconColor,
    required this.title,
    required this.trailing,
    this.subtitle,
    this.onTap,
    this.enabled = true,
  });

  final IconData? icon;
  final String? iconAsset;
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
      borderRadius: BorderRadius.circular(12.r),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 10.h),
        child: Row(
          children: [
            Container(
              width: 44.r,
              height: 44.r,
              decoration: BoxDecoration(
                color: effectiveIconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12.r),
              ),
              alignment: Alignment.center,
              child: iconAsset != null
                  ? Padding(
                      padding: EdgeInsets.all(10.w),
                      child: Image.asset(
                        iconAsset!,
                        fit: BoxFit.contain,
                      ),
                    )
                  : Icon(icon, color: effectiveIconColor, size: 24.sp),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      color: titleColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 14.sp,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: GoogleFonts.plusJakartaSans(
                        color: subtitleColor,
                        fontSize: 12.sp,
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
