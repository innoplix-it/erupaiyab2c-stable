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

  FocusNode? get _activeFocus =>
      widget.confirmPinFocusNode ??
      widget.newPinFocusNode ??
      widget.otpFocusNode;

  @override
  void didUpdateWidget(covariant AuthResetMpinStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isSubmitting && widget.isSubmitting) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !widget.isSubmitting) return;
        final focused = FocusManager.instance.primaryFocus;
        if (focused is FocusNode) {
          showAuthKeyboard(focused);
        } else {
          final node = _activeFocus;
          if (node != null) showAuthKeyboard(node);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Expanded(child: _buildScrollableContent()),
          // The form scrolls. Verify stays in the column so the scaffold
          // can place it above the keyboard instead of removing it on focus.
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildScrollableContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            authSidePadding(context),
            0,
            authSidePadding(context),
            authH(context, 16),
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
                    offset: Offset(-authW(context, 8), 0),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      iconSize: 24.r,
                      color: authInk,
                      onPressed: widget.onBack,
                    ),
                  ),
                  SizedBox(height: authH(context, 16)),
                  Text(
                    'Reset MPIN',
                    style: authTextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                  ),
                  SizedBox(height: authH(context, 4)),
                  Text(
                    'Set a 4 digit MPIN to secure your eRupaiya wallet.',
                    style: authTextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: authMuted,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: authH(context, 13)),
                  const AuthCodeLabel('Enter OTP'),
                  SizedBox(height: authH(context, 8)),
                  AuthOtpBoxes(
                    controller: widget.otpController,
                    focusNode: widget.otpFocusNode,
                    shakeController: widget.shakeController,
                    length: widget.otpLength,
                    autofocus: true,
                    // Keep focusable while submitting so layout stays lifted.
                    enabled: true,
                    hasError: widget.codeErrorText != null,
                    onChanged: widget.isSubmitting
                        ? null
                        : (value) {
                            widget.onChanged?.call(value);
                            widget.onOtpChanged?.call(value);
                          },
                    onCompleted:
                        widget.isSubmitting ? null : widget.onOtpCompleted,
                  ),
                  AuthOtpTimerRow(
                    timerText: widget.timerText,
                    canResend: widget.canResend && !widget.isSubmitting,
                    onResend: widget.onResend,
                    resendLabel: widget.resendLabel,
                    errorText: widget.codeErrorText,
                  ),
                  SizedBox(height: authH(context, 15)),
                  const Divider(height: 1, thickness: 1, color: _divider),
                  SizedBox(height: authH(context, 15)),
                  const AuthCodeLabel('Create New Pin'),
                  SizedBox(height: authH(context, 6)),
                  AuthPinRowWithToggle(
                    controller: widget.newPinController,
                    focusNode: widget.newPinFocusNode,
                    obscure: _obscureNew,
                    enabled: true,
                    hasError: _hasError,
                    onToggle: widget.isSubmitting
                        ? () {}
                        : () => setState(() => _obscureNew = !_obscureNew),
                    onChanged: widget.isSubmitting ? null : widget.onChanged,
                    onCompleted:
                        widget.isSubmitting ? null : widget.onNewPinCompleted,
                  ),
                  SizedBox(height: authH(context, 12)),
                  const AuthCodeLabel('Confirm New Pin'),
                  SizedBox(height: authH(context, 6)),
                  AuthPinRowWithToggle(
                    controller: widget.confirmPinController,
                    focusNode: widget.confirmPinFocusNode,
                    obscure: _obscureConfirm,
                    enabled: true,
                    hasError: _hasError,
                    onToggle: widget.isSubmitting
                        ? () {}
                        : () => setState(
                              () => _obscureConfirm = !_obscureConfirm,
                            ),
                    onChanged: widget.isSubmitting ? null : widget.onChanged,
                    onCompleted: widget.isSubmitting
                        ? null
                        : widget.onConfirmPinCompleted,
                  ),
                  if (_hasError) ...[
                    SizedBox(height: authH(context, 12)),
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
        authSidePadding(context),
        authH(context, 8),
        authSidePadding(context),
        authH(context, 16),
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
