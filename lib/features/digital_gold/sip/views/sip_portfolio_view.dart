// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../constants/app_colors.dart';
import '../../../../constants/routes_constant.dart';
import '../../../../widgets/custom_elevated_button.dart';

class DigitalGoldSipPortfolioView extends ConsumerWidget {
  const DigitalGoldSipPortfolioView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const headerTop = Color(0xFFF3EFE3);
    const headerBottom = Color(0xFFFFF7E8);
    return Scaffold(
      backgroundColor: Colors.white,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(
              16.w,
              MediaQuery.of(context).viewPadding.top + 8.h,
              16.w,
              18.h,
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [headerTop, headerBottom],
              ),
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(22.r),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    ),
                    Expanded(
                      child: Text(
                        'Portfolio',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black,
                                ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 7.h,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEDD8),
                        borderRadius: BorderRadius.circular(999.r),
                        border: Border.all(color: AppColors.lightBorder),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6.r,
                            height: 6.r,
                            decoration: const BoxDecoration(
                              color: Color(0xFFE85A2C),
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            '16,144.25/gm',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w900,
                                      color: Colors.black,
                                    ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 10.w),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.help_outline_rounded),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current Value',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.black.withOpacity(0.55),
                                      fontWeight: FontWeight.w700,
                                    ),
                          ),
                          SizedBox(height: 6.h),
                          Text(
                            '₹545.00',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF0B8A3B),
                                ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            '24k | 99% | Pure Gold',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w800,
                                    ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Digital Gold',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.black.withOpacity(0.55),
                                      fontWeight: FontWeight.w700,
                                    ),
                          ),
                          SizedBox(height: 6.h),
                          Text(
                            '0.89g',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 14.h),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Invested',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.black.withOpacity(0.55),
                                      fontWeight: FontWeight.w700,
                                    ),
                          ),
                          SizedBox(height: 6.h),
                          Text(
                            '+545.60',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Overall Returns',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.black.withOpacity(0.55),
                                      fontWeight: FontWeight.w700,
                                    ),
                          ),
                          SizedBox(height: 6.h),
                          Text(
                            '11.18%',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                Row(
                  children: [
                    Expanded(
                      child: CustomElevatedButton(
                        onPressed: () {},
                        label: 'Save More',
                        uppercaseLabel: false,
                        height: 40.h,
                        backgroundColor: const Color(0xFFE85A2C),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: CustomElevatedButton(
                        onPressed: () {},
                        label: 'Withdraw',
                        uppercaseLabel: false,
                        height: 40.h,
                        backgroundColor: Colors.transparent,
                        borderColor: const Color(0xFFE85A2C),
                        labelColor: const Color(0xFFE85A2C),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(22.r)),
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 20.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Tabs(),
                  SizedBox(height: 12.h),
                  Text(
                    'Your Holdings',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                        ),
                  ),
                  SizedBox(height: 10.h),
                  const _HoldingCard(
                    title: 'Gold',
                    amount: '0.89g',
                    value: '₹12,450.00',
                  ),
                  SizedBox(height: 10.h),
                  Container(
                    height: 38.h,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    'SIP Summery',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                        ),
                  ),
                  SizedBox(height: 10.h),
                  _SipSummaryRow(
                    label: 'Digital Gold',
                    amount: '₹50',
                    status: 'Active',
                    onTap: () =>
                        context.push(RouteConstants.digitalGoldSipSetup),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tabs extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const _Tab(label: 'Overview', selected: true),
        SizedBox(width: 14.w),
        const _Tab(label: 'Transactions'),
      ],
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.label, this.selected = false});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: selected ? const Color(0xFFE85A2C) : Colors.black54,
              ),
        ),
        SizedBox(height: 6.h),
        Container(
          height: 2.h,
          width: selected ? 56.w : 0,
          color: const Color(0xFFE85A2C),
        ),
      ],
    );
  }
}

class _HoldingCard extends StatelessWidget {
  const _HoldingCard({
    required this.title,
    required this.amount,
    required this.value,
  });

  final String title;
  final String amount;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.lightBorder.withOpacity(0.6)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
              ),
              SizedBox(height: 2.h),
              Text(
                value,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.black.withOpacity(0.55),
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SipSummaryRow extends StatelessWidget {
  const _SipSummaryRow({
    required this.label,
    required this.amount,
    required this.status,
    required this.onTap,
  });

  final String label;
  final String amount;
  final String status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14.r),
      child: Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: AppColors.lightBorder.withOpacity(0.6)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
              ),
            ),
            Text(
              amount,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
            ),
            SizedBox(width: 10.w),
            Text(
              status,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF0B8A3B),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
