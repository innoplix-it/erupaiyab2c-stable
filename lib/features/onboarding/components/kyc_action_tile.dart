import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class KycActionTile extends StatelessWidget {
  const KycActionTile({
    super.key,
    required this.title,
    required this.iconAsset,
    required this.onTap,
  });

  final String title;
  final String iconAsset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18.r),
      child: Container(
        height: 82.h,
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(color: AppColors.lightBorder, width: 1.4),
          boxShadow: [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 18.r,
              offset: Offset(0.w, 8.h),
            ),
          ],
        ),
        child: Row(
          children: [
            Image.asset(
              iconAsset,
              height: 24.r,
              width: 24.r,
              color: AppColors.textPrimary,
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                size: 16.r, color: Colors.black54),
          ],
        ),
      ),
    );
  }
}
