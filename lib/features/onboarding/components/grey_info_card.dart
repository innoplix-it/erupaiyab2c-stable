import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class GreyInfoCard extends StatelessWidget {
  const GreyInfoCard({
    super.key,
    required this.entries,
  });

  final Map<String, String> entries;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.lightBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 14.r,
            offset: Offset(0.w, 8.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: entries.entries.map((entry) {
          return Padding(
            padding: EdgeInsets.only(bottom: 8.h),
            child: RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                    ),
                children: [
                  TextSpan(
                    text: '${entry.key}: ',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(
                    text: entry.value,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
