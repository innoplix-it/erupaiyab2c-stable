// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/file_constants.dart';
import '../../../constants/routes_constant.dart';
import '../../../widgets/custom_elevated_button.dart';
import '../components/gold_details_header.dart';
import '../components/gold_locker_value_card.dart';
import '../components/gold_recent_purchase_card.dart';
import '../models/digital_metal.dart';
import '../repo/digital_gold_repo.dart';

class DigitalGoldLockerView extends HookConsumerWidget {
  const DigitalGoldLockerView({
    super.key,
    this.metal = DigitalMetal.gold,
  });

  final DigitalMetal metal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = DigitalMetalTheme.of(metal);
    final lockerAccentColor = metal == DigitalMetal.silver
        ? const Color(0xFF797979)
        : const Color(0xFFD7AA41);
    final lockerValueGradient = metal == DigitalMetal.silver
        ? const RadialGradient(
            center: Alignment.center,
            radius: 1.1,
            colors: [
              Color(0xFFFFFFFF),
              Color(0xFFB5B5B5),
            ],
          )
        : const RadialGradient(
            center: Alignment.center,
            radius: 1.1,
            colors: [
              Color(0xFFFFF3E6),
              Color(0xFFD7AA41),
            ],
          );
    final recentPurchasesAsync = ref.watch(recentPurchasesProvider);
    final balanceAsync = ref.watch(goldBalanceProvider);
    return Scaffold(
      backgroundColor: theme.pageBackground,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            GoldDetailsHeader(
              title: theme.lockerTitle,
              onBack: () => context.go(RouteConstants.home),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 0.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    balanceAsync.when(
                      data: (balance) => GoldLockerValueCard(
                        value: '₹${balance.toStringAsFixed(0)}',
                        changeText: '',
                        // changeText: '↑ ₹50(10%)',
                        investedText:
                            '₹${balance.toStringAsFixed(0)} Invested In Digital ${theme.label}',
                        subtitle: 'Track. Grow. Sell Anytime.',
                        backgroundGradient: lockerValueGradient,
                      ),
                      loading: () => GoldLockerValueCard(
                        value: '₹--',
                        changeText: '',
                        investedText: 'Loading...',
                        subtitle: 'Track. Grow. Sell Anytime.',
                        backgroundGradient: lockerValueGradient,
                      ),
                      error: (error, stack) => GoldLockerValueCard(
                        value: '₹0',
                        changeText: '',
                        investedText: 'Unable to load balance',
                        subtitle: 'Track. Grow. Sell Anytime.',
                        backgroundGradient: lockerValueGradient,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'Recent Purchases',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    SizedBox(height: 10.h),
                    recentPurchasesAsync.when(
                      data: (response) => response.data.isEmpty
                          ? Text(
                              'No recent purchases',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color:
                                        AppColors.textPrimary.withOpacity(0.6),
                                  ),
                            )
                          : Column(
                              children: response.data
                                  .map((purchase) => Padding(
                                        padding: EdgeInsets.only(bottom: 10.h),
                                        child: GoldRecentPurchaseCard(
                                          purchase: purchase,
                                          onSellNow: () => context.go(
                                            '${RouteConstants.digitalGold}?mode=sell&metal=${theme.queryValue}',
                                          ),
                                          onBuyMore: () => context.go(
                                            '${RouteConstants.digitalGold}?metal=${theme.queryValue}',
                                          ),
                                          currentValueColor: lockerAccentColor,
                                          sellButtonColor:
                                              theme.toggleActiveColor,
                                          buyMoreButtonColor: lockerAccentColor,
                                        ),
                                      ))
                                  .toList(),
                            ),
                      loading: () => const GoldRecentPurchaseCardShimmer(),
                      error: (error, stack) => Text(
                        'Failed to load recent purchases',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: const Color.fromARGB(255, 76, 10, 5),
                            ),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Row(
                      children: [
                        Text(
                          'Must Visit',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        const Spacer(),
                        Text(
                          'Advertisement',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: AppColors.textPrimary.withOpacity(0.6),
                              ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10.h),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14.r),
                      child: Image.asset(
                        FileConstants.pngReva,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    SizedBox(height: 30.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
          child: CustomElevatedButton(
            onPressed: () => context.go(RouteConstants.digitalGold),
            label: 'Go to Dashboard',
            uppercaseLabel: false,
            height: 42.h,
          ),
        ),
      ),
    );
  }
}
