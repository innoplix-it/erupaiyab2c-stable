// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../constants/app_colors.dart';

class GreyTextFormField extends StatelessWidget {
  const GreyTextFormField({
    super.key,
    required this.controller,
    this.labelText,
    this.isNumber = false,
    this.enabled = true,
    this.validator,
    this.hintText,
    this.height,
    this.contentPadding,
    this.prefixIcon,
    this.centerText = true,
    this.maxLength,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final String? labelText;
  final bool isNumber;
  final bool enabled;
  final String? Function(String?)? validator;
  final String? hintText;
  final double? height;
  final EdgeInsets? contentPadding;
  final Widget? prefixIcon;
  final bool centerText;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    final fieldHeight = height ?? 48.h;
    final fontSize = (fieldHeight * 0.42).clamp(12.0, 20.0);
    final verticalPadding =
        ((fieldHeight - fontSize) / 2).clamp(0.0, fieldHeight);
    final resolvedPadding = contentPadding ??
        EdgeInsets.symmetric(
          vertical: verticalPadding,
          horizontal: 12.w,
        );
    final shouldCenter = centerText && prefixIcon == null;
    return Container(
      height: fieldHeight,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppColors.phoneFieldStart,
            AppColors.phoneFieldEnd,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(22.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18.r,
            offset: Offset(0.w, 8.h),
          ),
        ],
      ),
      child: TextFormField(
        enabled: enabled,
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        maxLength: maxLength ?? (isNumber ? 10 : null),
        inputFormatters: inputFormatters ??
            (isNumber
                ? [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(maxLength ?? 10),
                  ]
                : null),
        textAlign: shouldCenter ? TextAlign.center : TextAlign.left,
        textAlignVertical: TextAlignVertical.center,
        cursorHeight: fontSize + 2,
        cursorWidth: 1.6,
        cursorRadius: Radius.circular(2.r),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hintText ?? (isNumber ? '1234567890' : labelText),
          hintStyle: TextStyle(
            fontSize: fontSize,
            color: AppColors.textPrimary.withOpacity(0.5),
            letterSpacing: 2,
          ),
          isCollapsed: true,
          contentPadding: resolvedPadding,
          prefixIcon: prefixIcon,
          prefixIconConstraints: BoxConstraints(
            minWidth: prefixIcon == null ? 0 : 36.w,
            minHeight: fieldHeight,
          ),
          counterText: '',
        ),
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              letterSpacing: 2,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              fontSize: fontSize,
              height: 1.0,
            ),
        validator: validator,
      ),
    );
  }
}
