// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/file_constants.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class HomeBannerCard extends StatelessWidget {
  const HomeBannerCard({
    super.key,
    required this.title,
    this.subtitle,
    this.buttonLabel,
    this.onPressed,
    this.height = 120,
  });

  final String title;
  final String? subtitle;
  final String? buttonLabel;
  final VoidCallback? onPressed;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppColors.gradientEnd,
            AppColors.gradientStart,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
      ),
      // padding: EdgeInsets.all(16.w),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                ),
                if (subtitle != null) ...[
                  SizedBox(height: 6.h),
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textPrimary.withOpacity(0.7),
                        ),
                  ),
                ],
                if (buttonLabel != null) ...[
                  SizedBox(height: 14.h),
                  SizedBox(height: 40.h,
                    child: ElevatedButton(
                      onPressed: onPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                      ),
                      child: Text(
                        buttonLabel!,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 20.0.h),
              child: Image.asset(
                FileConstants.iphone,
                height: height,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
