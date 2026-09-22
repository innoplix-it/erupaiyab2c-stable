import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/file_constants.dart';
import '../../../widgets/custom_elevated_button.dart';
import '../models/recent_purchase.dart';

class GoldRecentPurchaseCard extends StatelessWidget {
  const GoldRecentPurchaseCard({
    super.key,
    required this.purchase,
    required this.onSellNow,
    required this.onBuyMore,
    required this.currentValueColor,
    required this.sellButtonColor,
    required this.buyMoreButtonColor,
  });

  final RecentPurchase purchase;
  final VoidCallback onSellNow;
  final VoidCallback onBuyMore;
  final Color currentValueColor;
  final Color sellButtonColor;
  final Color buyMoreButtonColor;

  @override
  Widget build(BuildContext context) {
    // Parse date
    final dateTime = DateTime.parse(purchase.date);
    final formattedDate =
        '${dateTime.day.toString().padLeft(2, '0')}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.year}';

    return Container(
      padding: EdgeInsets.fromLTRB(12.w, 12.h, 0.w, 14.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset(
                FileConstants.mmtcPamp,
                height: 30.h,
                width: 45.w,
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MMTC-PAMP',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '${purchase.amount} G | $formattedDate',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            // ignore: deprecated_member_use
                            color: AppColors.textPrimary.withOpacity(0.7),
                          ),
                    ),
                  ],
                ),
              ),
              ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12.r),
                  bottomLeft: Radius.circular(12.r),
                ),
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: currentValueColor,
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Current Value',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white70,
                              fontSize: 10.sp,
                            ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        '${purchase.amount} G',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Row(
            children: [
              Expanded(
                child: CustomElevatedButton(
                  onPressed: onSellNow,
                  label: 'Sell Now',
                  uppercaseLabel: false,
                  height: 34.h,
                  backgroundColor: sellButtonColor,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: CustomElevatedButton(
                  onPressed: onBuyMore,
                  label: 'Buy More',
                  uppercaseLabel: false,
                  height: 34.h,
                  backgroundColor: buyMoreButtonColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class GoldRecentPurchaseCardShimmer extends StatelessWidget {
  const GoldRecentPurchaseCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        padding: EdgeInsets.fromLTRB(12.w, 12.h, 0.w, 14.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppColors.lightBorder),
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 30.h,
                  width: 45.w,
                  color: Colors.white,
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 16.h,
                        width: 100.w,
                        color: Colors.white,
                      ),
                      SizedBox(height: 4.h),
                      Container(
                        height: 14.h,
                        width: 150.w,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12.r),
                      bottomLeft: Radius.circular(12.r),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        height: 10.h,
                        width: 60.w,
                        color: Colors.white,
                      ),
                      SizedBox(height: 2.h),
                      Container(
                        height: 14.h,
                        width: 40.w,
                        color: Colors.white,
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
                  child: Container(
                    height: 36.h,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Container(
                    height: 36.h,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
