// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ParamDropdownField extends StatefulWidget {
  const ParamDropdownField({
    super.key,
    required this.controller,
    required this.items,
    this.hintText,
    this.errorText,
    this.onChanged,
  });

  final TextEditingController controller;
  final List<String> items;
  final String? hintText;
  final String? errorText;
  final ValueChanged<String?>? onChanged;

  @override
  State<ParamDropdownField> createState() => _ParamDropdownFieldState();
}

class _ParamDropdownFieldState extends State<ParamDropdownField> {
  String? _selected;

  @override
  void initState() {
    super.initState();
    // Pre-select if the controller already has a matching value.
    final existing = widget.controller.text.trim();
    if (existing.isNotEmpty && widget.items.contains(existing)) {
      _selected = existing;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: _selected,
      isExpanded: true,
      icon: Icon(
        Icons.keyboard_arrow_down_rounded,
        color: AppColors.textPrimary.withOpacity(0.55),
      ),
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: TextStyle(
          color: AppColors.textPrimary.withOpacity(0.45),
        ),
        errorText: widget.errorText,
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
      items: widget.items
          .map(
            (item) => DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: (value) {
        setState(() => _selected = value);
        widget.controller.text = value ?? '';
        widget.onChanged?.call(value);
      },
    );
  }
}
