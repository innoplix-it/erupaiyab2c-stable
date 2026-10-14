import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../constants/file_constants.dart';
import 'auth_step_parts.dart';

const Color _titleColor = Color(0xFF000000);
const Color _messageColor = Color(0xFF52525B);

/// "MPIN Generated Successfully" confirmation from the Figma spec.
/// Presentation only: the caller owns the timed redirect and back navigation.
class AuthMpinSuccessStep extends StatelessWidget {
  const AuthMpinSuccessStep({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final badgeSize = authWidthFraction(context, 80 / 360, min: 64, max: 120);
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Colors.white),
        const AuthBackgroundImage(),
        SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(left: 8.w),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  iconSize: 24.r,
                  color: _titleColor,
                  onPressed: onBack,
                ),
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.asset(
                          FileConstants.mpinSuccessBadge,
                          width: badgeSize,
                          height: badgeSize,
                        ),
                        SizedBox(height: 14.h),
                        Text(
                          'MPIN Generated Successfully',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: authFontFamily,
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w500,
                            fontStyle: FontStyle.normal,
                            color: _titleColor,
                            height: 1.3,
                            letterSpacing: 0,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'Set a 4 digit MPIN to secure your eRupaiya wallet.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: authFontFamily,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w400,
                            fontStyle: FontStyle.normal,
                            color: _messageColor,
                            height: 1.4,
                            letterSpacing: 0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
