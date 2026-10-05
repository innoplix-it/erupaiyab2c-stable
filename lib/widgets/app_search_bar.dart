import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import 'search_textfield.dart';

/// The app-wide search bar, based on the Electricity "Search by billers"
/// design (440x956 Figma frame: 54px tall, 12px radius, 0.5px #D7D7D7
/// border, 0 4 16 #0000000F shadow, Plus Jakarta Sans 14px #7C7C7C hint).
///
/// It fills the width it is given; place it inside horizontal padding of
/// [sideInset] to get the Electricity width.
class AppSearchBar extends StatelessWidget {
  const AppSearchBar({
    super.key,
    required this.hintText,
    required this.controller,
    this.onChanged,
    this.focusNode,
    this.autofocus = false,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.showSearchIcon = true,
    this.prefixText,
    this.prefixStyle,
    this.trailing,
    this.textStyle,
  });

  final String hintText;
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final FocusNode? focusNode;
  final bool autofocus;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final bool showSearchIcon;

  /// Fixed text shown before the input, e.g. a "+91 " country code.
  final String? prefixText;
  final TextStyle? prefixStyle;

  /// Widget pinned to the right edge (e.g. a mode toggle). Replaces the
  /// clear button.
  final Widget? trailing;

  /// Style of the typed text; defaults to Bricolage Grotesque 14sp.
  final TextStyle? textStyle;

  /// Converts a value from the 440-wide Figma frame to ScreenUtil radius
  /// units (design width 360), so 440-wide phones get the exact Figma size.
  static double _r(double figmaPx) => (figmaPx * 360 / 440).r;

  static double get height => _r(54);

  /// Horizontal screen margin around the bar (24px on the 440 frame), so
  /// every screen gives it the same width as on Electricity.
  static double get sideInset => (24 * 360 / 440).w;

  @override
  Widget build(BuildContext context) {
    final fieldHeight = height;
    final radius = BorderRadius.circular(_r(12));
    final hintSize = (14 * 360 / 440).sp.clamp(12.0, 14.0).toDouble();
    final textStyle = this.textStyle ??
        GoogleFonts.bricolageGrotesque(
          fontWeight: FontWeight.w500,
          fontSize: 14.sp,
          color: Colors.black,
        );

    return Container(
      width: double.infinity,
      height: fieldHeight,
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: radius,
        border: Border.all(color: const Color(0xFFD7D7D7), width: 0.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0x0F000000),
            offset: Offset(0, _r(4)),
            blurRadius: _r(16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, _) {
            return TextField(
              controller: controller,
              focusNode: focusNode,
              autofocus: autofocus,
              keyboardType: keyboardType,
              textInputAction: textInputAction,
              inputFormatters: inputFormatters,
              onChanged: onChanged,
              textAlignVertical: TextAlignVertical.center,
              style: textStyle,
              cursorColor: Colors.black,
              decoration: InputDecoration(
                isDense: true,
                hintText: hintText,
                hintStyle: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w400,
                  fontSize: hintSize,
                  height: 1,
                  letterSpacing: 0,
                  color: const Color(0xFF7C7C7C),
                ),
                prefixText: prefixText,
                prefixStyle: prefixStyle ??
                    textStyle.copyWith(fontWeight: FontWeight.w700),
                prefixIcon: showSearchIcon
                    ? SearchBarLeadingIcon(fieldHeight: fieldHeight)
                    : SizedBox(width: 16.w),
                prefixIconConstraints: showSearchIcon
                    ? SearchBarLeadingIcon.constraints(fieldHeight: fieldHeight)
                    : BoxConstraints(minWidth: 16.w),
                suffixIcon: trailing != null
                    ? Padding(
                        padding: EdgeInsets.only(right: 6.w),
                        child: trailing,
                      )
                    : value.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, size: 20.sp),
                            onPressed: () {
                              controller.clear();
                              onChanged?.call('');
                            },
                          )
                        : null,
                suffixIconConstraints: trailing != null
                    ? BoxConstraints(minHeight: fieldHeight)
                    : null,
                filled: true,
                fillColor: Colors.transparent,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.only(right: 16.w),
              ),
            );
          },
        ),
      ),
    );
  }
}
