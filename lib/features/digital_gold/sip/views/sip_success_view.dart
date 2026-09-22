// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../constants/app_colors.dart';
import '../../../../constants/routes_constant.dart';
import '../../../../widgets/custom_elevated_button.dart';
import '../../models/digital_gold_purchase_receipt.dart';

class DigitalGoldSipSuccessView extends ConsumerWidget {
  const DigitalGoldSipSuccessView({
    super.key,
    this.receipt,
  });

  final DigitalGoldPurchaseReceipt? receipt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = receipt;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 12.h),
            Container(
              width: 56.r,
              height: 56.r,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF0B8A3B),
              ),
              child: Icon(Icons.check, color: Colors.white, size: 28.r),
            ),
            SizedBox(height: 14.h),
            Text(
              'Gold Purchased Successfully',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
            ),
            SizedBox(height: 6.h),
            Text(
              r?.weightOfGold.trim().isNotEmpty == true
                  ? '${r!.weightOfGold} of 24k Gold'
                  : 'Gold purchased',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.black.withOpacity(0.55),
                    fontWeight: FontWeight.w700,
                  ),
            ),
            SizedBox(height: 10.h),
            Text(
              'Now Earn Gold To Your Account',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.black.withOpacity(0.55),
                    fontWeight: FontWeight.w700,
                  ),
            ),
            SizedBox(height: 18.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 18.w),
              child: Container(
                padding: EdgeInsets.all(14.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14.r),
                  border:
                      Border.all(color: AppColors.lightBorder.withOpacity(0.6)),
                ),
                child: Column(
                  children: [
                    _RowItem(
                      label: 'Amount Paid',
                      value: (r?.amountPaid ?? '').trim().isNotEmpty
                          ? r!.amountPaid
                          : '—',
                    ),
                    _RowItem(
                      label: 'Gold Price',
                      value: (r?.pricePerGram ?? '').trim().isNotEmpty
                          ? r!.pricePerGram
                          : '—',
                    ),
                    _RowItem(
                      label: 'Date & Time',
                      value: (r?.dateTime ?? '').trim().isNotEmpty
                          ? r!.dateTime
                          : '—',
                    ),
                    _RowItem(
                      label: 'Transaction ID',
                      value: (r?.transactionId ?? '').trim().isNotEmpty
                          ? r!.transactionId
                          : '—',
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            Padding(
              padding: EdgeInsets.fromLTRB(18.w, 10.h, 18.w, 16.h),
              child: Column(
                children: [
                  CustomElevatedButton(
                    onPressed: () =>
                        context.push(RouteConstants.digitalGoldSipSetup),
                    label: 'Start Gold SIP',
                    uppercaseLabel: false,
                    height: 46.h,
                    backgroundColor: Colors.white,
                    borderColor: const Color(0xFFE85A2C),
                    labelColor: const Color(0xFFE85A2C),
                  ),
                  SizedBox(height: 10.h),
                  CustomElevatedButton(
                    onPressed: () =>
                        context.push(RouteConstants.digitalGoldSipPortfolio),
                    label: 'View Portfolio',
                    uppercaseLabel: false,
                    height: 46.h,
                    backgroundColor: const Color(0xFFE85A2C),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
