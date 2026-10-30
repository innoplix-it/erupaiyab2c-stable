// ignore_for_file: deprecated_member_use

import 'package:e_rupaiya/widgets/custom_elevated_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/file_constants.dart';
import '../../../widgets/app_snackbar.dart';
import '../../../widgets/k_dialog.dart';
import '../../../widgets/my_app_bar.dart';
import '../../profile/controllers/profile_controller.dart';
import '../components/education_payment_sheets.dart';
import '../controllers/education_fees_controller.dart';
import '../education_fees_typography.dart';
import '../helpers/education_pay_now.dart';
import '../models/education_fees_responses.dart';

class EducationFeesPaymentView extends HookConsumerWidget {
  const EducationFeesPaymentView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(educationFeesControllerProvider);
    final repository = ref.read(educationFeesRepositoryProvider);
    useEffect(() {
      Future.microtask(
        () =>
            ref.read(profileControllerProvider.notifier).fetchProfileIfNeeded(),
      );
      return null;
    }, const []);
    final amount = _parseAmount(state.amountInput);
    final selectedCard = useState<EducationCard?>(null);
    final paymentSummary = useState<EducationPaymentSummaryData?>(null);
    final summaryError = useState<String?>(null);
    final isFetchingSummary = useState(false);
    final cardsAsync = useMemoized(
      () => repository.fetchCardList(),
      [repository],
    );
    final cardsFuture = useFuture(cardsAsync);
    final showPayNow = cardsFuture.connectionState == ConnectionState.done &&
        (cardsFuture.data?.cards.isEmpty ?? true);
    final payableAmount = paymentSummary.value?.payableAmount ?? amount;

    useEffect(() {
      Future.microtask(() async {
        isFetchingSummary.value = true;
        summaryError.value = null;
        try {
          final response = await repository.fetchPaymentSummary(
            amount: amount.round(),
          );
          if (response.status && response.data != null) {
            paymentSummary.value = response.data;
          } else {
            summaryError.value =
                response.message ?? 'Failed to fetch payment summary.';
          }
        } catch (e) {
          summaryError.value =
              'Failed to fetch payment summary. Please try again.';
        } finally {
          isFetchingSummary.value = false;
        }
      });
      return null;
    }, [amount]);

    void openSummary() {
      if (summaryError.value != null) {
        AppSnackbar.show(
          summaryError.value!,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
        return;
      }
      if (paymentSummary.value == null) {
        AppSnackbar.show(
          'Payment summary is not available. Please wait or try again.',
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
        return;
      }
      KDialog.instance.openSheet(
        dialog: EducationPaymentSummarySheet(
          amount: amount,
          initialSummary: paymentSummary.value,
          onPayNow: (payable) => runEducationPayNow(
            context: context,
            ref: ref,
            repository: repository,
            state: state,
            amount: amount,
            payable: payable,
          ),
        ),
      );
    }

    return EducationFeesTheme(
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: MyAppBar(
          title: 'Select Payment Method',
          showHelp: true,
          showDivider: false,
          fitTitle: true,
          titleStyle: MyAppBar.sharedTitleStyle(context),
          bharatConnectWidth: 52,
          bharatConnectHeight: 25,
          helpIconSize: 20,
          onBack: () => Navigator.of(context).maybePop(),
        ),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 20.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Paying To',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      SizedBox(height: 10.h),
                      _PayingToCard(
                        name: state.recipientName,
                        maskedAccount: _maskAccount(state.accountNumber),
                        amount: payableAmount,
                      ),
                      SizedBox(height: 26.h),
                      Text(
                        'My Cards / Recent Cards',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      SizedBox(height: 12.h),
                      _CardListSection(
                        amount: payableAmount,
                        cardsFuture: cardsFuture,
                        selectedCard: selectedCard,
                        onViewAndPay: openSummary,
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 0.h, 16.w, 20.h),
                child: showPayNow
                    ? CustomElevatedButton(
                        onPressed: openSummary,
                        label: 'Pay Now',
                        uppercaseLabel: false,
                        showArrow: false,
                        height: 42.h,
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PayingToCard extends StatelessWidget {
  const _PayingToCard({
    required this.name,
    required this.maskedAccount,
    required this.amount,
  });

  final String name;
  final String maskedAccount;
  final double amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.lightBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16.r,
            offset: Offset(0.w, 8.h),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isEmpty ? 'Recipient' : name,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                SizedBox(height: 6.h),
                Row(
                  children: [
                    Container(
                      height: 18.r,
                      width: 18.r,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Icon(
                        Icons.account_balance,
                        size: 12.r,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      maskedAccount,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textPrimary.withOpacity(0.7),
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            '₹${amount.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _CardListSection extends StatelessWidget {
  const _CardListSection({
    required this.amount,
    required this.cardsFuture,
    required this.selectedCard,
    required this.onViewAndPay,
  });

  final double amount;
  final AsyncSnapshot<EducationCardListResponse> cardsFuture;
  final ValueNotifier<EducationCard?> selectedCard;
  final VoidCallback onViewAndPay;

  @override
  Widget build(BuildContext context) {
    if (cardsFuture.connectionState == ConnectionState.waiting) {
      return const Center(
        child: SpinKitCircle(
          color: AppColors.primary,
          size: 48,
        ),
      );
    }
    if (cardsFuture.hasError) {
      return Text(
        'Failed to load cards.',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.red,
              fontWeight: FontWeight.w600,
            ),
      );
    }
    final response = cardsFuture.data;
    final cards = response?.cards ?? const <EducationCard>[];
    if (cards.isEmpty) {
      return SizedBox(
        height: 260.h,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                FileConstants.creditCardGif,
                width: 140.r,
                height: 140.r,
                fit: BoxFit.contain,
              ),
              SizedBox(height: 16.h),
              Text(
                'Add Your Credit Card For\nPayment',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Use Your VISA/Mastercard/Rupay CC\nFor This Payment',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textPrimary.withOpacity(0.6),
                    ),
              ),
            ],
          ),
        ),
      );
    }
    if (selectedCard.value == null) {
      selectedCard.value = cards.first;
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.lightBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12.r,
            offset: Offset(0.w, 6.h),
          ),
        ],
      ),
      child: Column(
        children: [
          ...cards.map((item) {
            final isSelected = selectedCard.value?.cardId == item.cardId;
            return InkWell(
              onTap: () => selectedCard.value = item,
              child: Padding(
                padding: EdgeInsets.only(bottom: 10.h),
                child: Row(
                  children: [
                    Container(
                      height: 40.r,
                      width: 40.r,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(color: AppColors.lightBorder),
                        color: Colors.white,
                      ),
                      child: Center(
                        child: Image.asset(
                          FileConstants.bharatConnectColor,
                          height: 22.r,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.cardNetwork.isEmpty
                                ? 'Card'
                                : item.cardNetwork,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            item.last4.isNotEmpty
                                ? '****${item.last4}'
                                : item.cardNumber,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: AppColors.textPrimary.withOpacity(0.6),
                                ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      height: 18.r,
                      width: 18.r,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.lightBorder,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Container(
                          height: 8.r,
                          width: 8.r,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          SizedBox(height: 12.h),
          const Divider(height: 1, color: AppColors.lightBorder),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: Text(
                  '₹${amount.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              SizedBox(
                height: 36.h,
                child: ElevatedButton(
                  onPressed: onViewAndPay,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18.r),
                    ),
                    elevation: 0,
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
                  ),
                  child: Text(
                    'View And Pay',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _maskAccount(String value) {
  final digits = value.replaceAll(RegExp(r'\D'), '');
  if (digits.length <= 4) return '****';
  final suffix = digits.substring(digits.length - 4);
  return '****$suffix';
}

double _parseAmount(String value) {
  final amount = double.tryParse(value.replaceAll(RegExp(r'\D'), '')) ?? 0;
  return amount.toDouble();
}
