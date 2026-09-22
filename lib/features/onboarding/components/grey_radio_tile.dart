// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class GreyRadioTile extends StatelessWidget {
  const GreyRadioTile({
    super.key,
    required this.title,
    required this.isSelected,
    required this.onTap,
    this.trailingIcon,
  });

  final String title;
  final bool isSelected;
  final VoidCallback onTap;
  final Widget? trailingIcon;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18.r),
      child: Container(
        height: 82.h,
        padding: EdgeInsets.symmetric(horizontal: 0.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(
            color: isSelected
                ? AppColors.primary.withOpacity(0.55)
                : AppColors.lightBorder,
            width: 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 18.r,
              offset: Offset(0.w, 8.h),
            ),
          ],
        ),
        child: Stack(
          children: [
            if (trailingIcon != null)
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 104.w,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryDark],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(18.r),
                      bottomRight: Radius.circular(18.r),
                      topLeft: Radius.circular(64.r),
                      bottomLeft: Radius.circular(64.r),
                    ),
                  ),
                  child: Center(child: trailingIcon),
                ),
              ),
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 26.r,
                      height: 26.r,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color:
                              isSelected ? AppColors.primary : Colors.black54,
                          width: 2,
                        ),
                      ),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: EdgeInsets.all(6.w),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    SizedBox(width: 14.w),
                    Expanded(
                      child: Text(
                        title,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                      ),
                    ),
                    SizedBox(width: 110.w),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
