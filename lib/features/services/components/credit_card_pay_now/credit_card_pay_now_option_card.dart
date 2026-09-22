import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../constants/app_colors.dart';

class CreditCardPayNowOptionCard extends StatelessWidget {
  const CreditCardPayNowOptionCard({
    super.key,
    required this.title,
    required this.amount,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String amount;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor =
        isSelected ? const Color(0xFFE85A2C) : AppColors.lightBorder;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        height: 90.h,
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: borderColor, width: 1.2),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              right: 0,
              child: _RadioDot(isSelected: isSelected),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFFE85A2C),
                        fontWeight: FontWeight.w700,
                      ),
                ),
                SizedBox(height: 6.h),
                Text(
                  amount,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
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

class _RadioDot extends StatelessWidget {
  const _RadioDot({required this.isSelected});
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final borderColor =
        isSelected ? const Color(0xFFE85A2C) : AppColors.lightBorder;
    return Container(
      width: 16.r,
      height: 16.r,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 1.6),
      ),
      child: Center(
        child: Container(
          width: 8.r,
          height: 8.r,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isSelected ? const Color(0xFFE85A2C) : Colors.transparent,
          ),
        ),
      ),
    );
  }
}
