import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/routes_constant.dart';
import '../models/digital_metal.dart';
import 'digital_gold_trade_success_v2_view.dart';

class DigitalGoldSuccessV2View extends StatelessWidget {
  const DigitalGoldSuccessV2View({
    super.key,
    this.metal = DigitalMetal.gold,
  });

  final DigitalMetal metal;

  @override
  Widget build(BuildContext context) {
    final theme = DigitalMetalTheme.of(metal);
    return DigitalGoldTradeSuccessV2View(
      title: '${theme.label} Purchased Successfully',
      subtitle: '0.069g of 24k ${theme.label}',
      details: Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: AppColors.lightBorder.withOpacity(0.6)),
        ),
        child: const Column(
          children: [
            _RowItem(label: 'Amount Paid', value: '400'),
            _RowItem(label: 'Gold Price', value: '₹15,450/g'),
            _RowItem(label: 'Date & Time', value: '18 May 2026, 9:41'),
            _RowItem(label: 'Transaction ID', value: 'GOLD123456'),
          ],
        ),
      ),
      secondaryCtaLabel: 'Start Gold SIP',
      onSecondaryCta: () => context.push(RouteConstants.digitalGoldSipSetup),
      primaryCtaLabel: 'View Portfolio',
      onPrimaryCta: () => context.go('${RouteConstants.digitalGold}?entry=home'),
    );
  }
}

class _RowItem extends StatelessWidget {
  const _RowItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.black.withOpacity(0.6),
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.black,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}
