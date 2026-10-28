// ignore_for_file: deprecated_member_use

import 'dart:math' as math;

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
///
/// Layout (Figma): the Continue button is pinned directly above the keyboard
/// at all times. The Scaffold body shrinks with the keyboard, so the button
/// rides on top of it and never jumps when Continue is tapped, validation
/// runs, or the keyboard opens.
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
    this.buttonLabel = 'Continue',
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

  /// Null keeps the Continue button disabled.
  final VoidCallback? onVerify;
  final VoidCallback onBack;

  /// Null hides the underlined "Change" link in the subtitle (flows like
  /// Delete Account have no number to change).
  final VoidCallback? onChangeNumber;
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

class _OtpVerifyStepState extends State<OtpVerifyStep> {
  /// Tap recognizer is created once and disposed with the state (the old code
  /// created a new, never-disposed recognizer on every rebuild).
  late final TapGestureRecognizer _changeTap = TapGestureRecognizer()
    ..onTap = () => widget.onChangeNumber?.call();

  /// Keyboard gap captured before Continue closes the keypad, so the button
  /// stays where it was instead of falling to the screen bottom.
  double _heldGap = 0;
  bool _continueHeld = false;

  void _onContinue() {
    _continueHeld = true;
    widget.onVerify?.call();
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showAuthKeyboard(widget.otpFocusNode);
    });
  }

  @override
  void didUpdateWidget(covariant OtpVerifyStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    // While Verify runs keep the keypad up so nothing moves.
    final started = !oldWidget.isSubmitting && widget.isSubmitting;
    final finished = oldWidget.isSubmitting && !widget.isSubmitting;
    if (started) _continueHeld = true;
    if (started || finished) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        showAuthKeyboard(widget.otpFocusNode);
      });
    }
  }

  @override
  void dispose() {
    _changeTap.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    return AuthKeyboardOnOpen(
      focusNode: widget.otpFocusNode,
      autofocus: true,
      enabled: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final keyboardGap =
              math.max(0.0, screenHeight - constraints.maxHeight);
          if (keyboardGap > 0) {
            _heldGap = math.max(_heldGap, keyboardGap);
          }
          final stick = widget.isSubmitting || _continueHeld;
          final hold = stick ? math.max(0.0, _heldGap - keyboardGap) : 0.0;
          return SafeArea(
            child: Padding(
              padding: EdgeInsets.only(bottom: hold),
              child: Column(
                children: [
                  Expanded(child: _buildScrollableContent(context)),
                  _buildFooter(context),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    final enabled = widget.onVerify != null && !widget.isSubmitting;
    final side = authSidePadding(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        side,
        authH(context, 8),
        side,
        authH(context, 14),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: authContentMaxWidth(context)),
          child: AuthButtonTheme(
            child: CustomElevatedButton(
              onPressed: enabled ? _onContinue : null,
              label: widget.isSubmitting ? 'Verifying...' : widget.buttonLabel,
              uppercaseLabel: false,
              isLoading: widget.isSubmitting,
              height: authButtonHeight(context),
              backgroundColor:
                  enabled ? AppColors.primary : authContinueDisabledFill,
              labelColor: enabled ? Colors.white : authContinueDisabledLabel,
              labelStyle: _textStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: enabled ? Colors.white : authContinueDisabledLabel,
                height: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScrollableContent(BuildContext context) {
    final side = authSidePadding(context);
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
      padding: EdgeInsets.fromLTRB(side, 0, side, authH(context, 16)),
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
                offset: Offset(-authW(context, 8), 0),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  iconSize: authW(context, 24),
                  color: _ink,
                  onPressed: widget.onBack,
                  tooltip: 'Back',
                ),
              ),
              SizedBox(height: authH(context, 16)),
              Text(
                widget.title,
                style: _textStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                ),
              ),
              SizedBox(height: authH(context, 4)),
              _buildSubtitle(),
              SizedBox(height: authH(context, 24)),
              Text(
                widget.label,
                style: _textStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: authH(context, 8)),
              AuthOtpBoxes(
                controller: widget.otpController,
                focusNode: widget.otpFocusNode,
                shakeController: widget.shakeController,
                length: widget.otpLength,
                autofocus: true,
                // Keep focusable while verifying so the keypad stays up.
                enabled: true,
                hasError: (widget.errorText?.isNotEmpty ?? false) ||
                    widget.codeErrorText != null,
                onChanged: widget.isSubmitting ? null : widget.onOtpChanged,
                onCompleted: widget.isSubmitting ? null : widget.onOtpCompleted,
              ),
              if (widget.errorText != null && widget.errorText!.isNotEmpty) ...[
                SizedBox(height: authH(context, 10)),
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
              SizedBox(height: authH(context, 2)),
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
          if (widget.onChangeNumber != null)
            TextSpan(
              text: 'Change',
              style: _textStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.primary,
                height: 1.4,
                decoration: TextDecoration.underline,
              ),
              recognizer: _changeTap,
            ),
        ],
      ),
    );
  }
}
