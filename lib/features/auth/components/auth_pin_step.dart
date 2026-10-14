import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'auth_code_fields.dart';
import 'auth_feedback.dart';
import 'auth_step_parts.dart';

/// Login PIN step, laid out like [AuthMobileStep] with the PIN boxes added.
/// Presentation only: login, Forgot PIN and back-to-mobile are callbacks.
class AuthPinStep extends StatefulWidget {
  const AuthPinStep({
    super.key,
    required this.mobileController,
    required this.pinController,
    required this.pinFocusNode,
    required this.pinLength,
    required this.onContinue,
    required this.onForgotPin,
    required this.onEditMobile,
    this.isLoading = false,
    this.referralBanner,
    this.shakeController,
    this.errorText,
    this.onPinChanged,
  });

  final TextEditingController mobileController;
  final TextEditingController pinController;
  final FocusNode pinFocusNode;
  final int pinLength;
  final VoidCallback onContinue;
  final VoidCallback onForgotPin;
  final VoidCallback onEditMobile;
  final bool isLoading;
  final Widget? referralBanner;

  /// Jiggles the PIN boxes after a wrong PIN.
  final AuthShakeController? shakeController;

  /// Shown under the boxes, between Show and Forget PIN.
  final String? errorText;
  final ValueChanged<String>? onPinChanged;

  @override
  State<AuthPinStep> createState() => _AuthPinStepState();
}

class _AuthPinStepState extends State<AuthPinStep> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return AuthStepLayout(
      footer: ValueListenableBuilder<TextEditingValue>(
        valueListenable: widget.pinController,
        builder: (context, value, _) {
          return AuthPrimaryButton(
            label: 'Continue',
            enabled: !widget.isLoading && value.text.length == widget.pinLength,
            onPressed: widget.onContinue,
            isLoading: widget.isLoading,
          );
        },
      ),
      children: [
        const AuthBrandRow(),
        SizedBox(height: 22.h),
        const AuthWelcomeHeading(),
        SizedBox(height: 22.h),
        if (widget.referralBanner != null) ...[
          widget.referralBanner!,
          SizedBox(height: 16.h),
        ],
        const AuthFieldLabel('Mobile Number'),
        SizedBox(height: 8.h),
        AuthMobileField(
          controller: widget.mobileController,
          enabled: false,
          onTap: widget.isLoading ? null : widget.onEditMobile,
        ),
        SizedBox(height: 12.h),
        const AuthFieldLabel('Enter Pin'),
        SizedBox(height: 10.h),
        AuthPinBoxes(
          controller: widget.pinController,
          focusNode: widget.pinFocusNode,
          shakeController: widget.shakeController,
          length: widget.pinLength,
          obscure: _obscure,
          autofocus: true,
          enabled: !widget.isLoading,
          hasError: widget.errorText != null,
          onChanged: widget.onPinChanged,
          onCompleted: (_) => widget.onContinue(),
        ),
        SizedBox(height: 2.h),
        AuthPinActionsRow(
          obscure: _obscure,
          onToggle: () => setState(() => _obscure = !_obscure),
          onForgotPin: widget.isLoading ? null : widget.onForgotPin,
          errorText: widget.errorText,
        ),
      ],
    );
  }
}
