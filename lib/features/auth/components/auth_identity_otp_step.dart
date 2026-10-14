import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'auth_code_fields.dart';
import 'auth_feedback.dart';
import 'auth_step_parts.dart';

const Color _divider = Color(0xFFE4E4E7);

/// Mobile + email OTP verification, laid out like the Reset MPIN Figma
/// screen. Presentation only: sending, resending and verifying OTPs belong to
/// the caller.
class AuthIdentityOtpStep extends StatelessWidget {
  const AuthIdentityOtpStep({
    super.key,
    required this.title,
    required this.description,
    required this.otpLength,
    required this.mobileOtpController,
    required this.emailOtpController,
    required this.mobileTimerText,
    required this.emailTimerText,
    required this.canResendMobile,
    required this.canResendEmail,
    required this.onResendMobile,
    required this.onResendEmail,
    required this.onVerify,
    required this.onBack,
    required this.buttonLabel,
    this.mobileOtpFocusNode,
    this.emailOtpFocusNode,
    this.errorText,
    this.isSubmitting = false,
    this.onMobileOtpChanged,
    this.onEmailOtpChanged,
    this.shakeController,
    this.codeErrorText,
  });

  final String title;
  final String description;
  final int otpLength;
  final TextEditingController mobileOtpController;
  final TextEditingController emailOtpController;
  final FocusNode? mobileOtpFocusNode;
  final FocusNode? emailOtpFocusNode;
  final String mobileTimerText;
  final String emailTimerText;
  final bool canResendMobile;
  final bool canResendEmail;
  final VoidCallback onResendMobile;
  final VoidCallback onResendEmail;
  final VoidCallback onVerify;
  final VoidCallback onBack;
  final String buttonLabel;
  final String? errorText;
  final bool isSubmitting;
  final ValueChanged<String>? onMobileOtpChanged;
  final ValueChanged<String>? onEmailOtpChanged;

  /// Jiggles both OTP rows after a wrong OTP.
  final AuthShakeController? shakeController;

  /// Wrong-OTP message, shown under each OTP row between the timer and
  /// Resend.
  final String? codeErrorText;

  bool get _hasError =>
      (errorText?.isNotEmpty ?? false) || codeErrorText != null;

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
              _buildFooter(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScrollableContent(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        authHorizontalPadding,
        0,
        authHorizontalPadding,
        16.h,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: authContentMaxWidth(context)),
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
                  color: authInk,
                  onPressed: onBack,
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                title,
                style: authTextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                description,
                style: authTextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: authMuted,
                  height: 1.4,
                ),
              ),
              SizedBox(height: 13.h),
              const AuthCodeLabel('Mobile OTP'),
              SizedBox(height: 8.h),
              AuthOtpBoxes(
                controller: mobileOtpController,
                focusNode: mobileOtpFocusNode,
                shakeController: shakeController,
                length: otpLength,
                autofocus: true,
                enabled: !isSubmitting,
                hasError: _hasError,
                onChanged: onMobileOtpChanged,
                onCompleted: (_) => emailOtpFocusNode?.requestFocus(),
              ),
              AuthOtpTimerRow(
                timerText: mobileTimerText,
                canResend: canResendMobile,
                onResend: onResendMobile,
                errorText: codeErrorText,
              ),
              SizedBox(height: 15.h),
              const Divider(height: 1, thickness: 1, color: _divider),
              SizedBox(height: 15.h),
              const AuthCodeLabel('Email OTP'),
              SizedBox(height: 8.h),
              AuthOtpBoxes(
                controller: emailOtpController,
                focusNode: emailOtpFocusNode,
                shakeController: shakeController,
                length: otpLength,
                enabled: !isSubmitting,
                hasError: _hasError,
                onChanged: onEmailOtpChanged,
              ),
              AuthOtpTimerRow(
                timerText: emailTimerText,
                canResend: canResendEmail,
                onResend: onResendEmail,
                errorText: codeErrorText,
              ),
              if (errorText?.isNotEmpty ?? false) ...[
                SizedBox(height: 12.h),
                Text(
                  errorText!,
                  style: authTextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.red,
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        authHorizontalPadding,
        8.h,
        authHorizontalPadding,
        16.h,
      ),
      child: AuthPrimaryButton(
        label: buttonLabel,
        enabled: !isSubmitting,
        onPressed: onVerify,
        isLoading: isSubmitting,
      ),
    );
  }
}
