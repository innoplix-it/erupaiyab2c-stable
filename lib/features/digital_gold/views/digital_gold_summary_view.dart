// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/file_constants.dart';
import '../../../constants/routes_constant.dart';
import '../../../widgets/app_snackbar.dart';
import '../../../widgets/custom_elevated_button.dart';
import '../../profile/controllers/profile_controller.dart';
import '../components/gold_payment_summary_sheet.dart';
import '../models/digital_gold_preview.dart';
import '../models/digital_metal.dart';
import '../repo/digital_gold_repo.dart';

class DigitalGoldSummaryView extends HookConsumerWidget {
  const DigitalGoldSummaryView({
    super.key,
    required this.amount,
    required this.preview,
    required this.isBuyingInRupees,
    this.metal = DigitalMetal.gold,
  });

  final double amount;
  final DigitalGoldPreview preview;
  final bool isBuyingInRupees;
  final DigitalMetal metal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileControllerProvider);
    final theme = DigitalMetalTheme.of(metal);

    final weightOfGold = () {
      if (isBuyingInRupees) return '1';
      final fixed = amount.toStringAsFixed(4);
      return fixed
          .replaceAll(RegExp(r'0+$'), '')
          .replaceAll(RegExp(r'\\.$'), '');
    }();
    final totalPrice = preview.totalAmount.toStringAsFixed(2);

    final summaryAsync = ref.watch(
      digitalGoldSummaryProvider(
        DigitalGoldSummaryRequest(
          weightOfGold: weightOfGold,
          totalPrice: totalPrice,
        ),
      ),
    );
    final summary = summaryAsync.asData?.value;

    final walletBalance = () {
      final fromProfile = (profileState.profile?.walletBalance ?? 0.0).toInt();
      final raw = (summary?.balanceEcoins ?? '').trim();
      final fromApi = (double.tryParse(raw) ?? double.nan).isNaN
          ? null
          : (double.tryParse(raw) ?? 0).floor();
      if (fromApi == null || fromApi <= 0) return fromProfile;
      return fromApi < fromProfile ? fromApi : fromProfile;
    }();

    final walletController = useTextEditingController(text: '0');
    final walletUsedInput = useState<int>(0);

    final serverTotal = summary?.finalAmount.amount ?? 0.0;
    final maxAllowedWallet = (serverTotal * 0.05).floorToDouble();

    void onWalletUsedChanged(String value) {
      final parsed = int.tryParse(value.replaceAll(RegExp(r'\D'), '')) ?? 0;
      final maxAllowed = maxAllowedWallet.floor();
      final clamped = parsed.clamp(0, walletBalance).clamp(0, maxAllowed);
      if (walletController.text != clamped.toString()) {
        walletController.text = clamped.toString();
        walletController.selection = TextSelection.fromPosition(
          TextPosition(offset: walletController.text.length),
        );
      }
      walletUsedInput.value = clamped;
    }

    final walletUsed = walletUsedInput.value.toDouble();
    final payable =
        (serverTotal - walletUsed).clamp(0, double.infinity).toDouble();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(8.w, 8.h, 12.w, 8.h),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  ),
                  Expanded(
                    child: Text(
                      'Summary',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                          ),
                    ),
                  ),
                  Image.asset(
                    FileConstants.bharatConnectColor,
                    height: 20.h,
                    fit: BoxFit.contain,
                  ),
                  SizedBox(width: 6.w),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.help_outline_rounded),
                  ),
                ],
              ),
            ),
          ),
          Divider(height: 1.h, color: AppColors.lightBorder.withOpacity(0.6)),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(18.w, 14.h, 18.w, 120.h),
              children: [
                Text(
                  'Purchase Details',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                ),
                SizedBox(height: 14.h),
                summaryAsync.when(
                  // Always show amounts from the summary API only.
                  loading: () => Column(
                    children: [
                      _KeyValueRow(
                        label: 'Weight Of ${theme.label}',
                        value: '—',
                      ),
                      SizedBox(height: 10.h),
                      const _KeyValueRow(
                        label: 'Total Price',
                        value: '—',
                      ),
                      SizedBox(height: 10.h),
                      const _KeyValueRow(
                        label: 'GST',
                        value: '—',
                      ),
                    ],
                  ),
                  error: (_, __) => Column(
                    children: [
                      _KeyValueRow(
                        label: 'Weight Of ${theme.label}',
                        value: '—',
                      ),
                      SizedBox(height: 10.h),
                      const _KeyValueRow(
                        label: 'Total Price',
                        value: '—',
                      ),
                      SizedBox(height: 10.h),
                      const _KeyValueRow(
                        label: 'GST',
                        value: '—',
                      ),
                    ],
                  ),
                  data: (summary) => Column(
                    children: [
                      _KeyValueRow(
                        label: 'Weight Of ${theme.label}',
                        value: summary.weightOfGold.isNotEmpty
                            ? summary.weightOfGold
                            : '—',
                      ),
                      SizedBox(height: 10.h),
                      _KeyValueRow(
                        label: 'Total Price',
                        value: summary.totalPrice.displayAmount.isNotEmpty
                            ? summary.totalPrice.displayAmount
                            : '—',
                      ),
                      SizedBox(height: 10.h),
                      _KeyValueRow(
                        label:
                            'GST ${summary.gst.percentage.isNotEmpty ? summary.gst.percentage : '3%'}',
                        value: summary.gst.displayAmount.isNotEmpty
                            ? summary.gst.displayAmount
                            : '—',
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 18.h),
                Row(
                  children: [
                    Image.asset(FileConstants.coin_3d,
                        width: 25.w, height: 25.h),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        'Balance $walletBalance Coins',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                      ),
                    ),
                    SizedBox(width: 58.w,
                      child: TextField(
                        controller: walletController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          hintText: '0',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 10.w,
                            vertical: 10.h,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.r),
                            borderSide:
                                const BorderSide(color: AppColors.lightBorder),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.r),
                            borderSide:
                                const BorderSide(color: AppColors.lightBorder),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.r),
                            borderSide:
                                const BorderSide(color: AppColors.primary),
                          ),
                        ),
                        onChanged: onWalletUsedChanged,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'You Used ${walletUsed.toStringAsFixed(0)} E-Coins',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                      ),
                    ),
                    Text(
                      '-₹${walletUsed.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                          ),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE9FCEB),
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(color: const Color(0xFFBEEFC6)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle,
                          size: 18.r, color: Colors.black),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w700,
                                    ),
                            children: [
                              const TextSpan(text: 'You saved '),
                              TextSpan(
                                text: '₹${walletUsed.toStringAsFixed(0)}',
                                style: const TextStyle(color: Colors.red),
                              ),
                              const TextSpan(text: ' for this transaction'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 26.h, color: AppColors.lightBorder),
                Row(
                  children: [
                    Text(
                      'Total',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                          ),
                    ),
                    const Spacer(),
                    Text(
                      ': ₹${payable.toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                          ),
                    ),
                  ],
                ),
                SizedBox(height: 22.h),
                Container(
                  padding: EdgeInsets.all(14.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(
                        color: AppColors.lightBorder.withOpacity(0.6)),
                  ),
                  child: const Column(
                    children: [
                      _FeatureRow(
                        title: '100% Secure',
                        subtitle: 'Will Be Securely Stored In Your Portfolio',
                      ),
                      _FeatureRow(
                        title: 'Easy Buy & Sell',
                        subtitle: 'Sell Anytime At Live Price',
                      ),
                      _FeatureRow(
                        title: '24k 99.99% Pure Gold',
                        subtitle: '',
                        showSubtitle: false,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 6.h),
                if (maxAllowedWallet > 0)
                  Text(
                    'Max ${maxAllowedWallet.toStringAsFixed(0)} coins can be used (5%).',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textPrimary.withOpacity(0.6),
                          fontWeight: FontWeight.w600,
                        ),
                  ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: EdgeInsets.fromLTRB(18.w, 10.h, 18.w, 16.h),
        child: SafeArea(
          top: false,
          child: CustomElevatedButton(
            onPressed: () {
              if (summary == null || summary.finalAmount.amount <= 0) {
                AppSnackbar.show(
                  'Unable to proceed. Please try again.',
                  type: AppSnackbarType.error,
                );
                return;
              }
              showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(18.r),
                  ),
                ),
                builder: (_) => GoldPaymentSummarySheet(
                  amount: amount,
                  preview: preview,
                  metal: metal,
                  onBuyNow: (receipt) {
                    if (!context.mounted) return;
                    context.push(
                      RouteConstants.digitalGoldSipSuccess,
                      extra: <String, dynamic>{
                        'receipt': receipt,
                      },
                    );
                  },
                ),
              );
            },
            label: 'Proceed to Pay',
            uppercaseLabel: false,
            height: 40.h,
            backgroundColor: const Color(0xFFE85A2C),
          ),
        ),
      ),
    );
  }
}

class _KeyValueRow extends StatelessWidget {
  const _KeyValueRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
          ),
        ),
        Text(
          ': $value',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
        ),
      ],
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.title,
    required this.subtitle,
    this.showSubtitle = true,
  });

  final String title;
  final String subtitle;
  final bool showSubtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(
            FileConstants.resetPinIcon,
            width: 30.r,
            height: 30.r,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0B8A3B),
                      ),
                ),
                if (showSubtitle && subtitle.trim().isNotEmpty) ...[
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.black.withOpacity(0.55),
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
