// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/routes_constant.dart';
import '../../../widgets/app_snackbar.dart';
import '../../../widgets/custom_elevated_button.dart';
import '../../../widgets/k_dialog.dart';
import '../../../widgets/my_app_bar.dart';
import '../../../widgets/processing_overlay.dart';
import '../../paymentgateway/razorpay_guard.dart';
import '../../paymentgateway/razorpay_service.dart';
import '../../profile/controllers/profile_controller.dart';
import '../components/education_payment_sheets.dart';
import '../controllers/education_fees_controller.dart';
import '../models/education_fees_responses.dart';

class EducationFeesTutorsView extends HookConsumerWidget {
  const EducationFeesTutorsView({
    super.key,
    required this.amount,
    required this.tutors,
  });

  final double amount;
  final List<EducationBeneficiary> tutors;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.read(educationFeesRepositoryProvider);
    useEffect(() {
      Future.microtask(
        () =>
            ref.read(profileControllerProvider.notifier).fetchProfileIfNeeded(),
      );
      return null;
    }, const []);
    final expandedIndex = useState<int?>(null);
    final processingNavigationStarted = useRef(false);

    void openSummary(EducationBeneficiary tutor) {
      KDialog.instance.openSheet(
        dialog: EducationPaymentSummarySheet(
          amount: amount,
          onPayNow: (payable) async {
            if (!await RazorpayGuard.ensureProfileReadyAndNotPaused(ref)) {
              return;
            }
            final feeType = ref.read(educationFeesControllerProvider).feeType;
            EducationCreateOrderResponse order;
            try {
              order = await repository.createOrder(
                recipientName: tutor.name,
                accountNo: tutor.accountMasked,
                accountNoUnmasked: tutor.accountNoUnmasked,
                ifsc: tutor.ifsc,
                amount: amount,
                feeType: feeType,
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
                order.message.isNotEmpty
                    ? order.message
                    : 'Failed to create order. Please try again.',
                backgroundColor: Colors.red,
                textColor: Colors.white,
              );
              return;
            }

            await RazorpayService.instance.openCheckout(
              amount: payable,
              name: tutor.name.isEmpty ? 'Education Fees' : tutor.name,
              description: 'Tuition fee payment',
              orderId: order.orderId,
              keyOverride: order.key,
              onSuccess: (paymentId) {
                if (processingNavigationStarted.value) return;
                processingNavigationStarted.value = true;
                openEducationPaymentProcessing({
                  'transactionRefId': order.transactionRefId,
                  'paymentType': 'Education Fees',
                  'recipientName': tutor.name,
                  'maskedAccount': tutor.accountMasked,
                  'fallbackAmount': payable.toStringAsFixed(2),
                  'paymentId': paymentId,
                });
              },
              onFailure: (message) {
                if (processingNavigationStarted.value) return;
                processingNavigationStarted.value = true;
                openEducationPaymentProcessing({
                  'transactionRefId': order.transactionRefId,
                  'paymentType': 'Education Fees',
                  'recipientName': tutor.name,
                  'maskedAccount': tutor.accountMasked,
                  'fallbackAmount': payable.toStringAsFixed(2),
                });
              },
            );
          },
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: MyAppBar(
        title: 'Tutors',
        showHelp: true,
        onBack: () => Navigator.of(context).maybePop(),
        onHelp: () {},
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
                itemCount: tutors.length,
                separatorBuilder: (_, __) => SizedBox(height: 12.h),
                itemBuilder: (context, index) {
                  final tutor = tutors[index];
                  final name = tutor.name.isEmpty
                      ? _fallbackTutorName(tutor)
                      : tutor.name;
                  final isExpanded = expandedIndex.value == index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.symmetric(
                      horizontal: 14.w,
                      vertical: 12.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(color: AppColors.lightBorder),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10.r,
                          offset: Offset(0.w, 6.h),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.person_outline,
                                color: Colors.black),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: Text(
                                name,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                            SizedBox(height: 30.h,
                              child: ElevatedButton(
                                onPressed: () {
                                  expandedIndex.value =
                                      isExpanded ? null : index;
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18.r),
                                  ),
                                  elevation: 0,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 14.w,
                                    vertical: 6.h,
                                  ),
                                ),
                                child: Text(
                                  isExpanded ? 'Hide Details' : 'View Details',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (isExpanded) ...[
                          SizedBox(height: 12.h),
                          InkWell(
                            onTap: () => openSummary(tutor),
                            borderRadius: BorderRadius.circular(12.r),
                            child: Column(
                              children: [
                                _DetailRow(
                                  label: 'PAN Details',
                                  value: tutor.panMasked.isEmpty
                                      ? '-'
                                      : tutor.panMasked,
                                ),
                                _DetailRow(
                                  label: 'Account Number',
                                  value: tutor.accountMasked.isEmpty
                                      ? '-'
                                      : tutor.accountMasked,
                                ),
                                _DetailRow(
                                  label: 'IFSC Code',
                                  value: tutor.ifsc.isEmpty ? '-' : tutor.ifsc,
                                ),
                                SizedBox(height: 6.h),
                                SizedBox(height: 12.h),
                                CustomElevatedButton(
                                  onPressed: () => openSummary(tutor),
                                  label: 'Pay ₹${amount.toStringAsFixed(0)}',
                                  uppercaseLabel: false,
                                  showArrow: false,
                                  height: 36.h,
                                  width: 135.w,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 0.h, 16.w, 20.h),
              child: CustomElevatedButton(
                onPressed: () =>
                    context.push(RouteConstants.educationFeesRecipient),
                label: '+ Add New',
                uppercaseLabel: false,
                showArrow: false,
                height: 48.h,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.showDivider = true,
  });

  final String label;
  final String value;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textPrimary.withOpacity(0.65),
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ],
        ),
        if (showDivider) ...[
          SizedBox(height: 8.h),
          const Divider(color: AppColors.lightBorder, height: 1),
          SizedBox(height: 8.h),
        ],
      ],
    );
  }
}

String _fallbackTutorName(EducationBeneficiary tutor) {
  if (tutor.accountMasked.isNotEmpty) {
    return 'Account ${tutor.accountMasked}';
  }
  return 'Beneficiary';
}
