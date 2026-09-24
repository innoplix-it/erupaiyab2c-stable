// ignore_for_file: deprecated_member_use

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/file_constants.dart';
import '../../../utils/error_message_utils.dart';
import '../../../widgets/app_snackbar.dart';
import '../../../widgets/custom_elevated_button.dart';
import '../../../widgets/processing_overlay.dart';
import '../../paymentgateway/razorpay_guard.dart';
import '../../paymentgateway/razorpay_service.dart';
import '../../profile/controllers/profile_controller.dart';
import '../models/digital_gold_otp_response.dart';
import '../models/digital_gold_preview.dart';
import '../models/digital_gold_purchase_receipt.dart';
import '../models/digital_metal.dart';
import '../repo/digital_gold_repo.dart';

class GoldPaymentSummarySheet extends HookConsumerWidget {
  const GoldPaymentSummarySheet({
    super.key,
    required this.amount,
    required this.onBuyNow,
    this.metal = DigitalMetal.gold,
    required this.preview,
  });

  final double amount;
  final ValueChanged<DigitalGoldPurchaseReceipt> onBuyNow;
  final DigitalMetal metal;
  final DigitalGoldPreview preview;
  static const int _otpLength = 6;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileControllerProvider);
    final walletBalance = profileState.profile?.walletBalance ?? 0.0;
    final theme = DigitalMetalTheme.of(metal);
    final walletController = useTextEditingController(text: '0');
    final walletUsedInput = useState<int>(0);
    final isOtpMode = useState<bool>(false);
    final otpController = useTextEditingController();
    final otpResponse = useState<DigitalGoldOtpResponse?>(null);
    final isSubmitting = useState<bool>(false);
    Timer? debounce;

    void onWalletUsedChanged(String value) {
      final parsed = int.tryParse(value.replaceAll(RegExp(r'\D'), '')) ?? 0;
      final maxAllowedByBalance = (walletBalance * 0.05).floor();
      final maxAllowed =
          maxAllowedByBalance.clamp(0, preview.totalAmount.floor());
      final clamped =
          parsed.clamp(0, walletBalance.toInt()).clamp(0, maxAllowed);
      if (walletController.text != clamped.toString()) {
        walletController.text = clamped.toString();
        walletController.selection = TextSelection.fromPosition(
          TextPosition(offset: walletController.text.length),
        );
      }
      walletUsedInput.value = clamped;
      debounce?.cancel();
      debounce = Timer(const Duration(milliseconds: 150), () {});
    }

    useEffect(() {
      Future.microtask(
        () =>
            ref.read(profileControllerProvider.notifier).fetchProfileIfNeeded(),
      );
      return () {
        debounce?.cancel();
      };
    }, const []);

    final walletUsed = walletUsedInput.value.toDouble();
    final payable =
        (preview.totalAmount - walletUsed).clamp(0, double.infinity).toDouble();
    final maxAllowedWalletByBalance =
        (walletBalance * 0.05).floorToDouble().clamp(0, preview.totalAmount);

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 16.h + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34.w,
                height: 34.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.lightBorder),
                  color: Colors.white,
                ),
                padding: EdgeInsets.all(6.w),
                child: Image.asset(FileConstants.mmtcPamp),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Buying From MMTC-PAMP',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      theme.providerSubtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textPrimary.withOpacity(0.6),
                          ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            'Purchase Details',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
          ),
          SizedBox(height: 8.h),
          _SummaryRow(
            label: 'Pre Tax Amount',
            value: '₹${preview.preTaxAmount.toStringAsFixed(2)}',
          ),
          SizedBox(height: 6.h),
          _SummaryRow(
            label: 'GST 3%',
            value: '₹${preview.gstAmount.toStringAsFixed(2)}',
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              Image.asset(FileConstants.coin_3d, width: 20.w, height: 20.h),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  'Balance ${walletBalance.toStringAsFixed(0)} Coins (Max ${maxAllowedWalletByBalance.toStringAsFixed(0)})',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textPrimary,
                      ),
                ),
              ),
              SizedBox(width: 56.w,
                child: TextField(
                  controller: walletController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: '0',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 6.h,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                      borderSide:
                          const BorderSide(color: AppColors.lightBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                      borderSide:
                          const BorderSide(color: AppColors.lightBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                  onChanged: onWalletUsedChanged,
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          _SummaryRow(
            label:
                'You Used ${walletUsed.toStringAsFixed(0)} E-Coins (Max ${maxAllowedWalletByBalance.toStringAsFixed(0)})',
            value: '-₹${walletUsed.toStringAsFixed(2)}',
            valueColor: Colors.red,
          ),
          Divider(height: 22.h, color: AppColors.lightBorder),
          _SummaryRow(
            label: 'Total',
            value: '₹${payable.toStringAsFixed(2)}',
            isBold: true,
          ),
          SizedBox(height: 12.h),
          if (isOtpMode.value) ...[
            Text(
              'Enter OTP',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
            ),
            SizedBox(height: 8.h),
            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              maxLength: _otpLength,
              decoration: InputDecoration(
                hintText: 'Enter $_otpLength-digit OTP',
                counterText: '',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: const BorderSide(color: AppColors.lightBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: const BorderSide(color: AppColors.lightBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
            SizedBox(height: 12.h),
          ],
          CustomElevatedButton(
            onPressed: isSubmitting.value
                ? null
                : () async {
                    if (isOtpMode.value) {
                      // Handle OTP submission and payment
                      if (otpController.text.trim().isEmpty ||
                          otpController.text.trim().length != _otpLength) {
                        AppSnackbar.show(
                          'Please enter a valid $_otpLength-digit OTP',
                          type: AppSnackbarType.error,
                        );
                        return;
                      }

                      if (!await RazorpayGuard.ensureProfileReadyAndNotPaused(
                        ref,
                      )) {
                        return;
                      }

                      isSubmitting.value = true;
                      try {
                        // Open Razorpay first
                        await RazorpayService.instance.openCheckout(
                          amount: payable,
                          name: '${theme.label} Purchase',
                          description: '${theme.label} buy',
                          keyOverride: '',
                          onSuccess: (_) async {
                            // Call buy API only after Razorpay success
                            try {
                              final otpData = otpResponse.value;
                              final billingAddressId = preview.billingAddressId;
                              final customerId = preview.customerId;
                              final quoteId = preview.quoteId;
                              if (otpData == null ||
                                  billingAddressId == null ||
                                  customerId == null ||
                                  quoteId == null) {
                                AppSnackbar.show(
                                  'Missing payment verification details. Please try again.',
                                  type: AppSnackbarType.error,
                                );
                                return;
                              }
                              final repository =
                                  ref.read(digitalGoldRepoProvider);
                              final wait = await showPaymentProcessingWhile(
                                work: repository.buyGold(
                                  refId: otpData.refId,
                                  billingAddressId: billingAddressId,
                                  customerId: customerId,
                                  quoteId: quoteId,
                                  stateResp: otpData.stateResp,
                                  otp: otpController.text.trim(),
                                ),
                              );
                              if (!context.mounted) return;
                              if (wait.timedOut) {
                                AppSnackbar.show(
                                  'Your payment is being processed. Please wait a moment.',
                                );
                                return;
                              }
                              final receipt = wait.value;
                              if (receipt == null) return;
                              Navigator.of(context).maybePop();
                              onBuyNow(receipt);
                            } catch (e) {
                              AppSnackbar.show(
                                ErrorMessageUtils.from(
                                  e,
                                  fallback:
                                      'Payment failed. Please try again.',
                                ),
                                type: AppSnackbarType.error,
                              );
                            }
                          },
                          onFailure: (message) {
                            AppSnackbar.show(
                              message,
                              backgroundColor: Colors.red,
                              textColor: Colors.white,
                            );
                          },
                        );
                      } catch (e) {
                        AppSnackbar.show(
                          ErrorMessageUtils.from(
                            e,
                            fallback: 'Payment failed. Please try again.',
                          ),
                          type: AppSnackbarType.error,
                        );
                      } finally {
                        isSubmitting.value = false;
                      }
                    } else {
                      // Send OTP first
                      if (preview.customerId == null ||
                          preview.billingAddressId == null ||
                          preview.quoteId == null) {
                        AppSnackbar.show(
                          'Missing required information. Please try again.',
                          type: AppSnackbarType.error,
                        );
                        return;
                      }

                      isSubmitting.value = true;
                      try {
                        final repository = ref.read(digitalGoldRepoProvider);
                        final response = await repository.sendOtp(
                          customerId: preview.customerId!,
                          billingAddressId: preview.billingAddressId!,
                          quoteId: preview.quoteId!,
                        );
                        otpResponse.value = response;
                        isOtpMode.value = true;
                        AppSnackbar.show(
                          'OTP sent successfully',
                          type: AppSnackbarType.success,
                        );
                      } catch (e) {
                        AppSnackbar.show(
                          ErrorMessageUtils.from(
                            e,
                            fallback: 'Failed to send OTP. Please try again.',
                          ),
                          type: AppSnackbarType.error,
                        );
                      } finally {
                        isSubmitting.value = false;
                      }
                    }
                  },
            label: isOtpMode.value ? 'Proceed to Payment' : 'Buy Now',
            uppercaseLabel: false,
            height: 42.h,
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.isBold = false,
    this.valueColor,
  });

  final String label;
  final String value;
  final bool isBold;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.textPrimary),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: valueColor ?? AppColors.textPrimary,
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
              ),
        ),
      ],
    );
  }
}
