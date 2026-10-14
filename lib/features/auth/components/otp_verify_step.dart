// ignore_for_file: deprecated_member_use

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../constants/app_colors.dart';
import '../../../widgets/custom_elevated_button.dart';
import 'auth_code_fields.dart';
import 'auth_feedback.dart';
import 'auth_step_parts.dart';

/// Pinned explicitly so the screen keeps Plus Jakarta Sans when rendered
/// outside the app theme (widget tests, previews).
const String _fontFamily = 'Plus Jakarta Sans';

const Color _ink = Color(0xFF09090B);
const Color _muted = Color(0xFF71717A);
const Color _disabledFill = Color(0xFFA1A1AA);

/// Every text on this screen goes through here so each style carries the full
/// set of properties instead of inheriting gaps from the ambient theme.
TextStyle _textStyle({
  required double fontSize,
  required FontWeight fontWeight,
  Color color = _ink,
  double height = 1.2,
  FontStyle fontStyle = FontStyle.normal,
  TextDecoration decoration = TextDecoration.none,
}) {
  return TextStyle(
    fontFamily: _fontFamily,
    fontSize: fontSize.sp,
    fontWeight: fontWeight,
    fontStyle: fontStyle,
    color: color,
    height: height,
    letterSpacing: 0,
    decoration: decoration,
    decorationColor: color,
  );
}

/// Presentation-only Verify OTP step. Every behaviour (verification, resend,
/// autofill, navigation) is owned by the caller and passed in as callbacks.
class OtpVerifyStep extends StatelessWidget {
  const OtpVerifyStep({
    super.key,
    required this.otpLength,
    required this.otpController,
    required this.otpFocusNode,
    required this.phoneNumber,
    required this.label,
    required this.timerText,
    required this.canResend,
    required this.onResend,
    required this.onVerify,
    required this.onBack,
    required this.onChangeNumber,
    this.title = 'Verify OTP',
    this.description,
    this.buttonLabel = 'Verify',
    this.errorText,
    this.isSubmitting = false,
    this.onOtpChanged,
    this.onOtpCompleted,
    this.shakeController,
    this.codeErrorText,
  });

  final int otpLength;
  final TextEditingController otpController;
  final FocusNode otpFocusNode;
  final String phoneNumber;
  final String title;
  final String label;
  final String? description;
  final String timerText;
  final bool canResend;
  final VoidCallback onResend;

  /// Null keeps the Verify button disabled.
  final VoidCallback? onVerify;
  final VoidCallback onBack;
  final VoidCallback onChangeNumber;
  final String buttonLabel;
  final String? errorText;
  final bool isSubmitting;
  final ValueChanged<String>? onOtpChanged;
  final ValueChanged<String>? onOtpCompleted;

  /// Jiggles the OTP boxes after a wrong OTP.
  final AuthShakeController? shakeController;

  /// Wrong-OTP message, shown under the boxes between the timer and Resend.
  final String? codeErrorText;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Colors.white),
        const AuthBackgroundImage(),
        SafeArea(
          child: Column(
            children: [
              Expanded(child: _buildScrollableContent(context)),
              _buildFooter(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScrollableContent(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            authHorizontalPadding,
            0,
            authHorizontalPadding,
            16.h,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: authContentMaxWidth(context),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Transform.translate(
                    // Lines the arrow glyph up with the content edge while
                    // keeping the full 48dp tap target.
                    offset: Offset(-8.w, 0),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      iconSize: 24.r,
                      color: _ink,
                      onPressed: onBack,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    title,
                    style: _textStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  _buildSubtitle(),
                  SizedBox(height: 24.h),
                  Text(
                    label,
                    style: _textStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  AuthOtpBoxes(
                    controller: otpController,
                    focusNode: otpFocusNode,
                    shakeController: shakeController,
                    length: otpLength,
                    autofocus: true,
                    hasError: (errorText?.isNotEmpty ?? false) ||
                        codeErrorText != null,
                    onChanged: onOtpChanged,
                    onCompleted: onOtpCompleted,
                  ),
                  if (errorText != null && errorText!.isNotEmpty) ...[
                    SizedBox(height: 10.h),
                    Text(
                      errorText!,
                      style: _textStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.red,
                        height: 1.4,
                      ),
                    ),
                  ],
                  SizedBox(height: 2.h),
                  AuthOtpTimerRow(
                    timerText: timerText,
                    canResend: canResend,
                    onResend: onResend,
                    errorText: codeErrorText,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSubtitle() {
    return Text.rich(
      TextSpan(
        style: _textStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: _muted,
          height: 1.4,
        ),
        children: [
          if (description != null)
            TextSpan(text: '$description ')
          else ...[
            TextSpan(
              text: 'Sent to ',
              style: _textStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: _muted,
                height: 1.4,
                fontStyle: FontStyle.italic,
              ),
            ),
            TextSpan(
              text: '$phoneNumber ',
              style: _textStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                height: 1.4,
              ),
            ),
          ],
          TextSpan(
            text: 'Change',
            style: _textStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.primary,
              height: 1.4,
              decoration: TextDecoration.underline,
            ),
            recognizer: TapGestureRecognizer()..onTap = onChangeNumber,
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    final enabled = onVerify != null && !isSubmitting;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        authHorizontalPadding,
        8.h,
        authHorizontalPadding,
        16.h,
      ),
      child: AuthButtonTheme(
        child: CustomElevatedButton(
          onPressed: enabled ? onVerify : null,
          label: isSubmitting ? 'Verifying...' : buttonLabel,
          uppercaseLabel: false,
          isLoading: isSubmitting,
          // CustomElevatedButton's 28.r radius clamps to a full pill at this
          // height.
          height: authButtonHeight(context),
          backgroundColor: enabled ? AppColors.primary : _disabledFill,
          labelColor: Colors.white,
          labelStyle: _textStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.white,
            height: 1,
          ),
        ),
      ),
    );
  }
}
