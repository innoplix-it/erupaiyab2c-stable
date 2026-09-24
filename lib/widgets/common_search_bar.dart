// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';
import 'search_textfield.dart';

/// Shared search bar used by Fetch Your Provider and other screens.
/// Pass [width] / [height] per screen; visual defaults match Fetch Your Provider.
class CommonSearchBar extends StatelessWidget {
  const CommonSearchBar({
    super.key,
    required this.hintText,
    required this.controller,
    this.onChanged,
    this.width,
    this.height,
    this.fillColor,
    this.borderColor,
    this.borderWidth,
    this.radius,
    this.boxShadow,
    this.hintStyle,
    this.style,
    this.searchIconOnRight = false,
    this.contentPadding,
  });

  final String hintText;
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final double? width;
  final double? height;
  final Color? fillColor;
  final Color? borderColor;
  final double? borderWidth;
  final double? radius;
  final List<BoxShadow>? boxShadow;
  final TextStyle? hintStyle;
  final TextStyle? style;
  final bool searchIconOnRight;
  final EdgeInsetsGeometry? contentPadding;

  @override
  Widget build(BuildContext context) {
    final fieldHeight = height ?? 60.h;
    return SearchTextfield(
      hintText: hintText,
      controller: controller,
      onChange: onChanged,
      width: width,
      height: fieldHeight,
      radius: radius ?? 12.r,
      fillColor: fillColor ?? const Color(0xFFFFFFFF),
      borderColor: borderColor ?? const Color(0xFFE2E2E2),
      borderWidth: borderWidth ?? 1,
      boxShadow: boxShadow,
      searchIconOnRight: searchIconOnRight,
      contentPadding: contentPadding ??
          (searchIconOnRight
              ? EdgeInsets.only(left: 16.w)
              : EdgeInsets.only(right: 16.w)),
      hintStyle: hintStyle ??
          GoogleFonts.bricolageGrotesque(
            fontWeight: FontWeight.w500,
            fontSize: 14.sp,
            color: AppColors.textPrimary.withOpacity(0.45),
          ),
      style: style ??
          GoogleFonts.bricolageGrotesque(
            fontWeight: FontWeight.w500,
            fontSize: 14.sp,
            color: Colors.black,
          ),
      prefixIconConstraints: searchIconOnRight
          ? const BoxConstraints(minWidth: 0, minHeight: 0)
          : SearchBarLeadingIcon.constraints(fieldHeight: fieldHeight),
      prefixIcon: searchIconOnRight
          ? const SizedBox.shrink()
          : SearchBarLeadingIcon(fieldHeight: fieldHeight),
    );
  }
}
