// ignore_for_file: deprecated_member_use

import 'package:e_rupaiya/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomElevatedButton extends StatelessWidget {
  const CustomElevatedButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.width = double.infinity,
    this.height,
    this.showArrow = false,
    this.uppercaseLabel = true,
    this.isBorder = false,
    this.isLoading = false,
    this.backgroundColor,
    this.borderColor,
    this.labelColor,
    this.labelStyle,
  });

  final VoidCallback? onPressed;
  final String label;
  final double? width;
  final double? height;
  final bool showArrow;
  final bool uppercaseLabel;
  final bool isBorder;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? labelColor;
  final TextStyle? labelStyle;

  @override
  Widget build(BuildContext context) {
    final background = backgroundColor != null
        ? LinearGradient(
            colors: [backgroundColor!, backgroundColor!],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          )
        : const LinearGradient(
            colors: [AppColors.primary, AppColors.primaryDark],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          );

    return SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: isBorder ? null : background,
          color: isBorder ? (backgroundColor ?? Colors.transparent) : null,
          borderRadius: BorderRadius.circular(28.r),
          border: isBorder
              ? Border.all(
                  color: borderColor ?? AppColors.primary,
                )
              : null,
        ),
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(
              horizontal: 12.w,
              vertical: 8.h,
            ),
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: labelColor ?? Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28.r),
            ),
          ),
          child: Row(
            mainAxisAlignment: showArrow
                ? MainAxisAlignment.spaceBetween
                : MainAxisAlignment.center,
            children: [
              if (isLoading && !showArrow) ...[
                SizedBox(
                  height: 16.h,
                  width: 16.h,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      labelColor ?? Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
              ],
              Text(
                uppercaseLabel ? label.toUpperCase() : label,
                style: (labelStyle ??
                        Theme.of(context).textTheme.labelLarge)
                    ?.copyWith(
                  color: labelColor ?? Colors.white,
                  letterSpacing: labelStyle == null ? 1.1 : null,
                  fontWeight: labelStyle?.fontWeight ?? FontWeight.w700,
                ),
              ),
              if (showArrow) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 20,
                  color: labelColor ?? AppColors.white,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
