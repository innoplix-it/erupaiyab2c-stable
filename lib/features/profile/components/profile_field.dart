import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ProfileField extends StatelessWidget {
  const ProfileField({
    super.key,
    required this.label,
    required this.controller,
    this.enabled = true,
    this.trailingText,
    this.onTrailingTap,
    this.trailingIcon,
    this.textColor,
    this.onTap,
    this.keyboardType,
    this.maxLines = 1,
  });

  final String label;
  final TextEditingController controller;
  final bool enabled;
  final String? trailingText;
  final VoidCallback? onTrailingTap;
  final IconData? trailingIcon;
  final Color? textColor;
  final VoidCallback? onTap;
  final TextInputType? keyboardType;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final field = Stack(
      alignment: Alignment.centerRight,
      children: [
        TextField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            filled: true,
            fillColor:
                enabled ? Colors.white : AppColors.lightBorder.withOpacity(0.3),
            contentPadding:
                EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: textColor ??
                    (enabled
                        ? AppColors.textPrimary
                        : AppColors.textPrimary.withOpacity(0.5)),
                fontWeight: FontWeight.w600,
              ),
        ),
        if (trailingText != null || trailingIcon != null)
          Padding(
            padding: EdgeInsets.only(right: 16.w),
            child: GestureDetector(
              onTap: onTrailingTap,
              child: trailingIcon != null
                  ? Icon(
                      trailingIcon,
                      size: 18.r,
                      color: AppColors.primary,
                    )
                  : Text(
                      trailingText!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
            ),
          ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
        ),
        SizedBox(height: 8.h),
        if (onTap == null)
          field
        else
          GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: AbsorbPointer(
              child: field,
            ),
          ),
      ],
    );
  }
}
