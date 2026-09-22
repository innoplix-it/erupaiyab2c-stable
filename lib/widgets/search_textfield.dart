// ignore_for_file: deprecated_member_use

import 'package:e_rupaiya/constants/file_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../constants/app_colors.dart';

class TwotoneSearchIcon extends StatelessWidget {
  const TwotoneSearchIcon({
    super.key,
    required this.size,
    this.color = const Color(0xFFDD5428),
    this.strokeWidth = 1.5,
  });

  final double size;
  final Color color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _TwotoneSearchPainter(
          color: color,
          strokeWidth: strokeWidth,
        ),
      ),
    );
  }
}

class _TwotoneSearchPainter extends CustomPainter {
  const _TwotoneSearchPainter({
    required this.color,
    required this.strokeWidth,
  });

  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    final fill = Paint()
      ..color = color.withOpacity(0.18)
      ..style = PaintingStyle.fill;

    final center = Offset(size.width * 0.42, size.height * 0.42);
    final radius = size.width * 0.30;
    canvas.drawCircle(center, radius, fill);
    canvas.drawCircle(center, radius, stroke);
    canvas.drawLine(
      Offset(center.dx + radius * 0.68, center.dy + radius * 0.68),
      Offset(size.width * 0.86, size.height * 0.86),
      stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _TwotoneSearchPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
  }
}

class SearchTextfield extends StatelessWidget {
  const SearchTextfield({
    super.key,
    required this.hintText,
    required this.controller,
    this.prefixIcon,
    this.onChange,
    this.onFilterPressed,
    this.hintStyle,
    this.style,
    this.prefixIconConstraints,
    this.contentPadding,
    this.width,
    this.height,
    this.fillColor,
    this.borderColor,
    this.borderWidth,
    this.radius,
    this.boxShadow,
  });

  final String hintText;
  final TextEditingController controller;
  final Widget? prefixIcon;
  final ValueChanged<String>? onChange;
  final VoidCallback? onFilterPressed;
  final TextStyle? hintStyle;
  final TextStyle? style;
  final BoxConstraints? prefixIconConstraints;
  final EdgeInsetsGeometry? contentPadding;
  final double? width;
  final double? height;
  final Color? fillColor;
  final Color? borderColor;
  final double? borderWidth;
  final double? radius;
  final List<BoxShadow>? boxShadow;

  @override
  Widget build(BuildContext context) {
    final resolvedRadius = BorderRadius.all(Radius.circular(radius ?? 12.r));
    final resolvedFill = fillColor ?? Colors.white;
    final resolvedBorderColor = borderColor ?? AppColors.lightBorder;
    final resolvedBorderWidth = borderWidth ?? 1;
    final useOuterChrome =
        boxShadow != null || height != null || width != null;

    final field = ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        return TextField(
          controller: controller,
          onChanged: onChange,
          textAlignVertical: TextAlignVertical.center,
          style: style ??
              TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w500,
                fontSize: 14.sp,
              ),
          cursorColor: Colors.black,
          decoration: InputDecoration(
            isDense: useOuterChrome,
            hintText: hintText,
            hintStyle: hintStyle ??
                TextStyle(
                  color: AppColors.textPrimary.withOpacity(0.4),
                  fontWeight: FontWeight.w400,
                  fontSize: 12.sp,
                ),
            prefixIcon: prefixIcon ??
                Padding(
                  padding: EdgeInsets.all(12.w),
                  child: Image.asset(
                    FileConstants.orangeSearch,
                    width: 18.w,
                    height: 18.h,
                    fit: BoxFit.contain,
                  ),
                ),
            prefixIconConstraints: prefixIconConstraints,
            suffixIcon: onFilterPressed == null
                ? (value.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, size: 20.sp),
                        onPressed: () {
                          controller.clear();
                          onChange?.call('');
                        },
                      )
                    : null)
                : IconButton(
                    onPressed: onFilterPressed,
                    icon: Icon(
                      Icons.filter_list,
                      color: AppColors.textPrimary.withOpacity(0.6),
                    ),
                  ),
            filled: true,
            fillColor: resolvedFill,
            border: useOuterChrome
                ? InputBorder.none
                : OutlineInputBorder(
                    borderRadius: resolvedRadius,
                    borderSide: BorderSide(
                      color: resolvedBorderColor,
                      width: resolvedBorderWidth,
                    ),
                  ),
            enabledBorder: useOuterChrome
                ? InputBorder.none
                : OutlineInputBorder(
                    borderRadius: resolvedRadius,
                    borderSide: BorderSide(
                      color: resolvedBorderColor,
                      width: resolvedBorderWidth,
                    ),
                  ),
            focusedBorder: useOuterChrome
                ? InputBorder.none
                : OutlineInputBorder(
                    borderRadius: resolvedRadius,
                    borderSide: BorderSide(
                      color: borderColor ?? AppColors.primary,
                      width: resolvedBorderWidth,
                    ),
                  ),
            contentPadding: contentPadding ??
                EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 14.h,
                ),
          ),
        );
      },
    );

    if (!useOuterChrome) return field;

    return Container(
      width: width ?? double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: resolvedFill,
        borderRadius: resolvedRadius,
        border: Border.all(
          color: resolvedBorderColor,
          width: resolvedBorderWidth,
        ),
        boxShadow: boxShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: field,
    );
  }
}
