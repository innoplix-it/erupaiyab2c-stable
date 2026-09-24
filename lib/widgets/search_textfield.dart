// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../constants/app_colors.dart';

const String _orangeSearchSvg = '''
<svg width="18" height="18" viewBox="0 0 18 18" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M8.625 15.75C12.56 15.75 15.75 12.56 15.75 8.625C15.75 4.68997 12.56 1.5 8.625 1.5C4.68997 1.5 1.5 4.68997 1.5 8.625C1.5 12.56 4.68997 15.75 8.625 15.75Z" stroke="#DD5428" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
<path opacity="0.4" d="M16.5 16.5L15 15" stroke="#DD5428" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
</svg>
''';

class TwotoneSearchIcon extends StatelessWidget {
  const TwotoneSearchIcon({
    super.key,
    this.size,
    this.color = const Color(0xFFDD5428),
  });

  final double? size;
  final Color color;

  static const _defaultColor = Color(0xFFDD5428);

  @override
  Widget build(BuildContext context) {
    final resolved = size ?? 18.w;
    return SizedBox(
      width: resolved,
      height: resolved,
      child: SvgPicture.string(
        _orangeSearchSvg,
        width: resolved,
        height: resolved,
        fit: BoxFit.contain,
        colorFilter: color == _defaultColor
            ? null
            : ColorFilter.mode(color, BlendMode.srcIn),
      ),
    );
  }
}

class SearchBarLeadingIcon extends StatelessWidget {
  const SearchBarLeadingIcon({
    super.key,
    this.fieldHeight,
    this.leftPadding,
    this.gap,
  });

  final double? fieldHeight;
  final double? leftPadding;
  final double? gap;

  static BoxConstraints constraints({double? fieldHeight}) {
    return BoxConstraints(
      minWidth: 16.w + 18.w + 8.w,
      minHeight: fieldHeight ?? 18.w,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: leftPadding ?? 16.w,
        right: gap ?? 8.w,
      ),
      child: SizedBox(
        height: fieldHeight,
        width: 18.w,
        child: const Center(
          child: TwotoneSearchIcon(),
        ),
      ),
    );
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
    this.searchIconOnRight = false,
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
  final bool searchIconOnRight;
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
            prefixIcon: searchIconOnRight
                ? prefixIcon
                : (prefixIcon ?? SearchBarLeadingIcon(fieldHeight: height)),
            prefixIconConstraints: searchIconOnRight
                ? prefixIconConstraints
                : (prefixIconConstraints ??
                    SearchBarLeadingIcon.constraints(fieldHeight: height)),
            suffixIcon: searchIconOnRight
                ? Padding(
                    padding: EdgeInsets.only(right: 16.w),
                    child: SizedBox(
                      height: height,
                      width: 18.w,
                      child: const Center(child: TwotoneSearchIcon()),
                    ),
                  )
                : onFilterPressed == null
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
            suffixIconConstraints: searchIconOnRight
                ? BoxConstraints(
                    minWidth: 16.w + 18.w,
                    minHeight: height ?? 18.w,
                  )
                : null,
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
