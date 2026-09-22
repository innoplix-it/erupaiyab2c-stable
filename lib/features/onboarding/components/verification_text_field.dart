import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../constants/app_colors.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class VerificationTextField extends StatelessWidget {
  const VerificationTextField({
    super.key,
    required this.controller,
    this.hintText,
    this.keyboardType = TextInputType.text,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.maxLength,
    this.onChanged,
    this.suffix,
    this.prefix,
  });

  final TextEditingController controller;
  final String? hintText;
  final TextInputType keyboardType;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final Widget? suffix;
  final Widget? prefix;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58.h,
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
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        inputFormatters: inputFormatters,
        maxLength: maxLength,
        textAlignVertical: TextAlignVertical.center,
        decoration: InputDecoration(
          hintText: hintText,
          counterText: '',
          border: InputBorder.none,
          contentPadding:
              EdgeInsets.symmetric(horizontal: 18.w, vertical: 16.h),
          prefixIcon: prefix == null
              ? null
              : Padding(
                  padding: EdgeInsets.only(left: 16.w, right: 12.w),
                  child: prefix,
                ),
          prefixIconConstraints:
              const BoxConstraints(maxHeight: 32, minWidth: 56),
          suffixIcon: suffix == null
              ? null
              : Padding(
                  padding: EdgeInsets.only(right: 16.w, left: 12.w),
                  child: suffix,
                ),
          suffixIconConstraints:
              const BoxConstraints(maxHeight: 32, minWidth: 56),
        ),
        onChanged: onChanged,
      ),
    );
  }
}
