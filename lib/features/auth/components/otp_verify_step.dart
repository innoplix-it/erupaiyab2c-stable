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
class OtpVerifyStep extends StatefulWidget {
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
  State<OtpVerifyStep> createState() => _OtpVerifyStepState();
}

class _OtpVerifyStepState extends State<OtpVerifyStep>
    with WidgetsBindingObserver {
  /// Hide footer / keep keypad layout while Verify is processing.
  bool _keepLifted = false;
  bool _hadKeyboard = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.otpFocusNode.addListener(_onFocusChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showAuthKeyboard(widget.otpFocusNode);
    });
  }

  @override
  void didUpdateWidget(covariant OtpVerifyStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.otpFocusNode != widget.otpFocusNode) {
      oldWidget.otpFocusNode.removeListener(_onFocusChanged);
      widget.otpFocusNode.addListener(_onFocusChanged);
    }
    if (!oldWidget.isSubmitting && widget.isSubmitting) {
      _keepLifted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !widget.isSubmitting) return;
        showAuthKeyboard(widget.otpFocusNode);
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.otpFocusNode.removeListener(_onFocusChanged);
    super.dispose();
  }

  void _onFocusChanged() {
    if (!mounted) return;
    if (widget.otpFocusNode.hasFocus) _keepLifted = true;
    setState(() {});
  }

  @override
  void didChangeMetrics() {
    if (!mounted) return;
    final inset = View.maybeOf(context)?.viewInsets.bottom ?? 0;
    if (inset > 0) {
      _hadKeyboard = true;
      _keepLifted = true;
    } else if (_hadKeyboard) {
      _hadKeyboard = false;
      if (widget.isSubmitting) {
        setState(() {});
        return;
      }
      if (widget.otpFocusNode.hasFocus) {
        widget.otpFocusNode.unfocus();
      }
      if (!widget.otpFocusNode.hasFocus) _keepLifted = false;
      setState(() {});
    }
  }

  bool get _lifted {
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0 ||
        (View.maybeOf(context)?.viewInsets.bottom ?? 0) > 0;
    return keyboardOpen ||
        widget.otpFocusNode.hasFocus ||
        widget.isSubmitting ||
        _keepLifted;
  }

  @override
  Widget build(BuildContext context) {
    return AuthKeyboardOnOpen(
      focusNode: widget.otpFocusNode,
      autofocus: true,
      enabled: true,
      child: AuthPeachMarqueeShell(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(child: _buildScrollableContent(context)),
              // Figma: hide Verify while keypad is up; still submit on
              // [onOtpCompleted]. Keep hidden while verifying so content
              // does not drop when the inset briefly clears.
              if (!_lifted)
                _buildFooter(context)
              else
                SizedBox(height: 8.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    final enabled = widget.onVerify != null && !widget.isSubmitting;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        authHorizontalPadding,
        8.h,
        authHorizontalPadding,
        16.h,
      ),
      child: AuthButtonTheme(
        child: CustomElevatedButton(
          onPressed: enabled ? widget.onVerify : null,
          label: widget.isSubmitting ? 'Verifying...' : widget.buttonLabel,
          uppercaseLabel: false,
          isLoading: widget.isSubmitting,
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
                      onPressed: widget.onBack,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    widget.title,
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
                    widget.label,
                    style: _textStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  AuthOtpBoxes(
                    controller: widget.otpController,
                    focusNode: widget.otpFocusNode,
                    shakeController: widget.shakeController,
                    length: widget.otpLength,
                    autofocus: true,
                    // Keep focusable while verifying so layout stays lifted.
                    enabled: true,
                    hasError: (widget.errorText?.isNotEmpty ?? false) ||
                        widget.codeErrorText != null,
                    onChanged:
                        widget.isSubmitting ? null : widget.onOtpChanged,
                    onCompleted:
                        widget.isSubmitting ? null : widget.onOtpCompleted,
                  ),
                  if (widget.errorText != null &&
                      widget.errorText!.isNotEmpty) ...[
                    SizedBox(height: 10.h),
                    Text(
                      widget.errorText!,
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
                    timerText: widget.timerText,
                    canResend: widget.canResend && !widget.isSubmitting,
                    onResend: widget.onResend,
                    errorText: widget.codeErrorText,
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
          if (widget.description != null)
            TextSpan(text: '${widget.description} ')
          else ...[
            TextSpan(
              text: 'Sent to ',
              style: _textStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: _muted,
                height: 1.4,
              ),
            ),
            TextSpan(
              text: '${widget.phoneNumber} ',
              style: _textStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
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
            recognizer: TapGestureRecognizer()..onTap = widget.onChangeNumber,
          ),
        ],
      ),
    );
  }
}
