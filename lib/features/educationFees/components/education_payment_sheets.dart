// ignore_for_file: deprecated_member_use

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../constants/app_colors.dart';
import '../../../services/payment_device_context_service.dart';
import '../../../widgets/custom_elevated_button.dart';
import '../controllers/education_fees_controller.dart';
import '../models/education_fees_responses.dart';

class EducationAddCardSheet extends StatelessWidget {
  const EducationAddCardSheet({
    super.key,
    required this.amount,
    required this.name,
    required this.onContinue,
  });

  final double amount;
  final String name;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 20.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Enter Credit Card Details',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            SizedBox(height: 6.h),
            Text(
              'Pay ₹${amount.toStringAsFixed(2)} For Tuition Fee To ${name.isEmpty ? 'Recipient' : name}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textPrimary.withOpacity(0.6),
                  ),
            ),
            SizedBox(height: 16.h),
            const _Label(text: 'Card Number'),
            SizedBox(height: 8.h),
            const _InputField(
              hint: '**** **** **** ****',
              suffix: Icon(Icons.credit_card, size: 18),
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _Label(text: 'Valid Upto'),
                      SizedBox(height: 8.h),
                      const _InputField(hint: '12/26'),
                    ],
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _Label(text: 'CVV'),
                      SizedBox(height: 8.h),
                      const _InputField(
                        hint: '123',
                        suffix: Icon(Icons.visibility, size: 18),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F1F1),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Row(
                children: [
                  Container(
                    height: 16.r,
                    width: 16.r,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child:
                        const Icon(Icons.check, size: 12, color: Colors.white),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'Secure my card as per RBI guidelines',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textPrimary.withOpacity(0.6),
                          ),
                    ),
                  ),
                  Text(
                    'Learn More',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            CustomElevatedButton(
              onPressed: () {
                Navigator.of(context).maybePop();
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  onContinue();
                });
              },
              label: 'Continue',
              uppercaseLabel: false,
              showArrow: false,
              height: 54.h,
            ),
          ],
        ),
      ),
    );
  }
}

class EducationPaymentSummarySheet extends HookConsumerWidget {
  const EducationPaymentSummarySheet({
    super.key,
    required this.amount,
    required this.onPayNow,
    this.initialSummary,
  });

  final double amount;
  final Future<void> Function(double payable) onPayNow;
  final EducationPaymentSummaryData? initialSummary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.read(educationFeesRepositoryProvider);
    final summary = useState<EducationPaymentSummaryData?>(initialSummary);
    final isLoading = useState(initialSummary == null);
    final isPaying = useState(false);
    final error = useState<String?>(null);
    final initialWalletUsed = (initialSummary?.walletUsed ?? 0).toInt();
    final walletController = useTextEditingController(
      text: initialWalletUsed.toString(),
    );
    final walletUsedInput = useState<int>(initialWalletUsed);
    Timer? debounce;

    Future<void> fetchSummary({int? walletUsed}) async {
      isLoading.value = true;
      error.value = null;
      try {
        final response = await repository.fetchPaymentSummary(
          amount: amount.round(),
          walletUsed: walletUsed,
        );
        if (response.status && response.data != null) {
          summary.value = response.data;
          final balance = response.data!.walletBalance.toInt();
          final clamped =
              response.data!.walletUsed.toInt().clamp(0, balance).toInt();
          if (clamped != walletUsedInput.value) {
            walletUsedInput.value = clamped;
          }
          if (walletController.text != walletUsedInput.value.toString()) {
            walletController.text = walletUsedInput.value.toString();
          }
        } else {
          error.value = response.message ?? 'Failed to fetch summary.';
        }
      } catch (_) {
        error.value = 'Failed to fetch summary.';
      } finally {
        isLoading.value = false;
      }
    }

    useEffect(() {
      unawaited(const PaymentDeviceContextService().collect());
      if (initialSummary == null) {
        unawaited(fetchSummary());
      }
      return () {
        debounce?.cancel();
      };
    }, const []);

    void onWalletUsedChanged(String value) {
      final parsed = int.tryParse(value.replaceAll(RegExp(r'\D'), '')) ?? 0;
      final current = summary.value;
      if (current == null) return;
      final clamped = parsed.clamp(0, current.walletBalance.toInt()).toInt();
      if (walletController.text != clamped.toString()) {
        walletController.text = clamped.toString();
      }
      if (clamped == walletUsedInput.value) return;
      walletUsedInput.value = clamped;
      debounce?.cancel();
      debounce = Timer(const Duration(milliseconds: 350), () {
        fetchSummary(walletUsed: clamped);
      });
    }

    final current = summary.value;
    final serviceCharge = current?.serviceCharge ?? 0.0;
    final gstOnServiceCharge = current?.gstOnServiceCharge ?? 0.0;
    final walletBalance = current?.walletBalance ?? 0.0;
    final walletUsed = current?.walletUsed ?? walletUsedInput.value.toDouble();
    final payable = current?.payableAmount ?? 0.0;

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return SafeArea(
      top: false,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 20.h + bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Payment Summary',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.lightBorder),
                borderRadius: BorderRadius.circular(16.r),
                color: Colors.white,
              ),
              child: Column(
                children: [
                  _SummaryRow(
                    label: 'Amount',
                    value: '₹${amount.toStringAsFixed(2)}',
                  ),
                  SizedBox(height: 8.h),
                  _SummaryRow(
                    label: 'Service Charge',
                    value: '₹${serviceCharge.toStringAsFixed(2)}',
                  ),
                  SizedBox(height: 8.h),
                  _SummaryRow(
                    label: 'GST on Service Charge',
                    value: '₹${gstOnServiceCharge.toStringAsFixed(2)}',
                  ),
                  // SizedBox(height: 12.h),
                  // Row(
                  //   children: [
                  //     Container(
                  //       height: 22.r,
                  //       width: 22.r,
                  //       decoration: BoxDecoration(
                  //         color: AppColors.primary.withOpacity(0.1),
                  //         shape: BoxShape.circle,
                  //       ),
                  //       child: Icon(
                  //         Icons.currency_rupee,
                  //         size: 14.r,
                  //         color: AppColors.primary,
                  //       ),
                  //     ),
                  //     SizedBox(width: 8.w),
                  //     Expanded(
                  //       child: Text(
                  //         'Use E-Coins\nBalance ${walletBalance.toStringAsFixed(0)} Coins',
                  //         style: Theme.of(context)
                  //             .textTheme
                  //             .bodySmall
                  //             ?.copyWith(
                  //               color: AppColors.textPrimary.withOpacity(0.6),
                  //             ),
                  //       ),
                  //     ),
                  //     SizedBox(
                  //       width: 92.w,
                  //       child: TextField(
                  //         controller: walletController,
                  //         keyboardType: TextInputType.number,
                  //         textAlign: TextAlign.center,
                  //         enabled: walletBalance > 0,
                  //         decoration: InputDecoration(
                  //           hintText: '0',
                  //           isDense: true,
                  //           contentPadding: EdgeInsets.symmetric(
                  //             horizontal: 8.w,
                  //             vertical: 8.h,
                  //           ),
                  //           border: OutlineInputBorder(
                  //             borderRadius: BorderRadius.circular(10.r),
                  //             borderSide: const BorderSide(
                  //                 color: AppColors.lightBorder),
                  //           ),
                  //           enabledBorder: OutlineInputBorder(
                  //             borderRadius: BorderRadius.circular(10.r),
                  //             borderSide: const BorderSide(
                  //                 color: AppColors.lightBorder),
                  //           ),
                  //           focusedBorder: OutlineInputBorder(
                  //             borderRadius: BorderRadius.circular(10.r),
                  //             borderSide:
                  //                 const BorderSide(color: AppColors.primary),
                  //           ),
                  //           suffixIcon: isLoading.value
                  //               ? Padding(
                  //                   padding: EdgeInsets.all(8.r),
                  //                   child: const Center(
                  //                     child: SpinKitCircle(
                  //                       color: AppColors.primary,
                  //                       size: 48,
                  //                     ),
                  //                   ),
                  //                 )
                  //               : null,
                  //         ),
                  //         onChanged: onWalletUsedChanged,
                  //       ),
                  //     ),
                  //   ],
                  // ),
                  // SizedBox(height: 8.h),
                  // _SummaryRow(
                  //   label: 'You used ${walletUsed.toStringAsFixed(0)} E-Coins',
                  //   value: '-₹${walletUsed.toStringAsFixed(2)}',
                  //   valueColor: Colors.red,
                  // ),
                  if (error.value != null) ...[
                    SizedBox(height: 8.h),
                    Text(
                      error.value!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                  Divider(height: 24.h, color: AppColors.lightBorder),
                  _SummaryRow(
                    label: 'Payable Amount',
                    value: '₹${payable.toStringAsFixed(2)}',
                    isBold: true,
                  ),
                ],
              ),
            ),
            SizedBox(height: 14.h),
            CustomElevatedButton(
              onPressed: (isLoading.value || isPaying.value)
                  ? null
                  : () async {
                      if (isPaying.value) return;
                      isPaying.value = true;
                      await Navigator.of(context).maybePop();
                      await onPayNow(payable);
                    },
              label: isPaying.value
                  ? 'Processing...'
                  : 'Pay ₹${payable.toStringAsFixed(2)}',
              uppercaseLabel: false,
              showArrow: false,
              height: 42.h,
            ),
          ],
        ),
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
    final style = Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
        );
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.black,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w400,
                  height: 1.0,
                  letterSpacing: 0,
                ),
          ),
        ),
        Text(
          value,
          style: style?.copyWith(color: valueColor),
        ),
      ],
    );
  }
}

class _Label extends StatelessWidget {
  const _Label({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
    );
  }
}

class _InputField extends StatelessWidget {
  const _InputField({required this.hint, this.suffix});

  final String hint;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 12.w,
          vertical: 12.h,
        ),
        suffixIcon: suffix,
      ),
    );
  }
}
