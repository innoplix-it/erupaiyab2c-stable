import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'auth_code_fields.dart';
import 'auth_feedback.dart';
import 'auth_step_parts.dart';

const Color _divider = Color(0xFFE4E4E7);

/// Reset MPIN layout from the Figma spec: OTP, then the new PIN twice.
/// Presentation only: OTP requests, validation and the reset call belong to
/// the caller.
class AuthResetMpinStep extends StatefulWidget {
  const AuthResetMpinStep({
    super.key,
    required this.otpLength,
    required this.otpController,
    required this.newPinController,
    required this.confirmPinController,
    required this.timerText,
    required this.canResend,
    required this.onResend,
    required this.onVerify,
    required this.onBack,
    this.otpFocusNode,
    this.newPinFocusNode,
    this.confirmPinFocusNode,
    this.resendLabel = 'Resend',
    this.buttonLabel = 'Verify',
    this.errorText,
    this.isSubmitting = false,
    this.onChanged,
    this.onOtpCompleted,
    this.onNewPinCompleted,
    this.onConfirmPinCompleted,
    this.shakeController,
    this.codeErrorText,
    this.onOtpChanged,
  });

  final int otpLength;
  final TextEditingController otpController;
  final TextEditingController newPinController;
  final TextEditingController confirmPinController;
  final FocusNode? otpFocusNode;
  final FocusNode? newPinFocusNode;
  final FocusNode? confirmPinFocusNode;
  final String timerText;
  final bool canResend;
  final VoidCallback onResend;
  final String resendLabel;
  final VoidCallback onVerify;
  final VoidCallback onBack;
  final String buttonLabel;
  final String? errorText;
  final bool isSubmitting;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onOtpCompleted;
  final ValueChanged<String>? onNewPinCompleted;
  final ValueChanged<String>? onConfirmPinCompleted;

  /// Jiggles the OTP boxes after a wrong OTP.
  final AuthShakeController? shakeController;

  /// Wrong-OTP message, shown under the OTP boxes between the timer and
  /// Resend.
  final String? codeErrorText;

  /// OTP boxes only; [onChanged] fires for every field.
  final ValueChanged<String>? onOtpChanged;

  @override
  State<AuthResetMpinStep> createState() => _AuthResetMpinStepState();
}

class _AuthResetMpinStepState extends State<AuthResetMpinStep> {
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  bool get _hasError =>
      widget.errorText != null && widget.errorText!.isNotEmpty;

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
              Expanded(child: _buildScrollableContent()),
              _buildFooter(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScrollableContent() {
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
                      color: authInk,
                      onPressed: widget.onBack,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'Reset MPIN',
                    style: authTextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Set a 4 digit MPIN to secure your eRupaiya wallet.',
                    style: authTextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: authMuted,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 13.h),
                  const AuthCodeLabel('Enter OTP'),
                  SizedBox(height: 8.h),
                  AuthOtpBoxes(
                    controller: widget.otpController,
                    focusNode: widget.otpFocusNode,
                    shakeController: widget.shakeController,
                    length: widget.otpLength,
                    autofocus: true,
                    enabled: !widget.isSubmitting,
                    hasError: widget.codeErrorText != null,
                    onChanged: (value) {
                      widget.onChanged?.call(value);
                      widget.onOtpChanged?.call(value);
                    },
                    onCompleted: widget.onOtpCompleted,
                  ),
                  AuthOtpTimerRow(
                    timerText: widget.timerText,
                    canResend: widget.canResend,
                    onResend: widget.onResend,
                    resendLabel: widget.resendLabel,
                    errorText: widget.codeErrorText,
                  ),
                  SizedBox(height: 15.h),
                  const Divider(height: 1, thickness: 1, color: _divider),
                  SizedBox(height: 15.h),
                  const AuthCodeLabel('Create New Pin'),
                  SizedBox(height: 6.h),
                  AuthPinRowWithToggle(
                    controller: widget.newPinController,
                    focusNode: widget.newPinFocusNode,
                    obscure: _obscureNew,
                    enabled: !widget.isSubmitting,
                    hasError: _hasError,
                    onToggle: () => setState(() => _obscureNew = !_obscureNew),
                    onChanged: widget.onChanged,
                    onCompleted: widget.onNewPinCompleted,
                  ),
                  SizedBox(height: 12.h),
                  const AuthCodeLabel('Confirm New Pin'),
                  SizedBox(height: 6.h),
                  AuthPinRowWithToggle(
                    controller: widget.confirmPinController,
                    focusNode: widget.confirmPinFocusNode,
                    obscure: _obscureConfirm,
                    enabled: !widget.isSubmitting,
                    hasError: _hasError,
                    onToggle: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                    onChanged: widget.onChanged,
                    onCompleted: widget.onConfirmPinCompleted,
                  ),
                  if (_hasError) ...[
                    SizedBox(height: 12.h),
                    Text(
                      widget.errorText!,
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
      },
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
      child: ListenableBuilder(
        listenable: Listenable.merge([
          widget.otpController,
          widget.newPinController,
          widget.confirmPinController,
        ]),
        builder: (context, _) {
          final complete =
              widget.otpController.text.length == widget.otpLength &&
                  widget.newPinController.text.length == 4 &&
                  widget.confirmPinController.text.length == 4;
          return AuthPrimaryButton(
            label: widget.buttonLabel,
            enabled: complete && !widget.isSubmitting,
            onPressed: widget.onVerify,
            isLoading: widget.isSubmitting,
          );
        },
      ),
    );
  }
}
