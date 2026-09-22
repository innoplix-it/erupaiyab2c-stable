// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../utils/date_format_helper.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class DatePickerField extends StatelessWidget {
  const DatePickerField({
    super.key,
    required this.controller,
    required this.dateFormat,
    this.errorText,
    this.onDatePicked,
  });

  final TextEditingController controller;

  /// The date format string extracted from the param name, e.g. "DD-MM-YYYY".
  final String dateFormat;
  final String? errorText;

  /// Called after the user picks a date (value is already set on controller).
  final VoidCallback? onDatePicked;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _pickDate(context),
      child: AbsorbPointer(
        child: TextField(
          controller: controller,
          readOnly: true,
          decoration: InputDecoration(
            hintText: dateFormat,
            hintStyle: TextStyle(
              color: AppColors.textPrimary.withOpacity(0.45),
            ),
            errorText: errorText,
            suffixIcon: Icon(
              Icons.calendar_today_outlined,
              size: 20.r,
              color: AppColors.textPrimary.withOpacity(0.55),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: AppColors.lightBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: AppColors.lightBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: Colors.red),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 16.h,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(1900),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      controller.text = DateFormatHelper.format(picked, dateFormat);
      onDatePicked?.call();
    }
  }
}
