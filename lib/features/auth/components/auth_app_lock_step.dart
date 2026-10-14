import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../constants/file_constants.dart';
import 'auth_code_fields.dart';
import 'auth_feedback.dart';
import 'auth_step_parts.dart';

/// #A8A8A8 at the per-layer opacities of the fingerprint button's Figma
/// drop-shadow stack.
const Color _fingerprintShadowTint = Color(0xFFA8A8A8);

/// Lock screen layout from the Figma spec. Presentation only: unlocking,
/// biometrics and Forget PIN are callbacks.
class AuthAppLockStep extends StatefulWidget {
  const AuthAppLockStep({
    super.key,
    required this.pinController,
    required this.pinFocusNode,
    required this.onPinCompleted,
    required this.onForgotPin,
    this.enabled = true,
    this.showFingerprint = false,
    this.onFingerprint,
    this.shakeController,
    this.errorText,
    this.onPinChanged,
  });

  final TextEditingController pinController;
  final FocusNode pinFocusNode;
  final ValueChanged<String> onPinCompleted;
  final VoidCallback onForgotPin;
  final bool enabled;
  final bool showFingerprint;
  final VoidCallback? onFingerprint;

  /// Jiggles the PIN boxes after a wrong PIN.
  final AuthShakeController? shakeController;

  /// Shown under the boxes, between Show and Forget PIN.
  final String? errorText;
  final ValueChanged<String>? onPinChanged;

  @override
  State<AuthAppLockStep> createState() => _AuthAppLockStepState();
}

class _AuthAppLockStepState extends State<AuthAppLockStep> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Colors.white),
        const AuthBackgroundImage(),
        SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  authHorizontalPadding,
                  20.h,
                  authHorizontalPadding,
                  24.h,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: authContentMaxWidth(context),
                    ),
                    child: _buildContent(),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: AuthBrandRow()),
            Icon(Icons.help_outline, size: 20.r, color: authInk),
          ],
        ),
        SizedBox(height: 29.h),
        Text(
          'Please enter your security pin',
          style: authTextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            height: 1.3,
          ),
        ),
        SizedBox(height: 20.h),
        const AuthCodeLabel('Enter Pin'),
        SizedBox(height: 8.h),
        AuthPinBoxes(
          controller: widget.pinController,
          focusNode: widget.pinFocusNode,
          shakeController: widget.shakeController,
          obscure: _obscure,
          autofocus: true,
          enabled: widget.enabled,
          hasError: widget.errorText != null,
          onChanged: widget.onPinChanged,
          onCompleted: widget.onPinCompleted,
        ),
        AuthPinActionsRow(
          obscure: _obscure,
          onToggle: () => setState(() => _obscure = !_obscure),
          onForgotPin: widget.onForgotPin,
          errorText: widget.errorText,
        ),
        if (widget.showFingerprint) ...[
          SizedBox(height: MediaQuery.sizeOf(context).height * 0.05),
          Center(child: _buildFingerprint()),
        ],
      ],
    );
  }

  Widget _buildFingerprint() {
    final fingerprintSize =
        authWidthFraction(context, 74 / 360, min: 60, max: 110);
    return Semantics(
      button: true,
      label: 'Use Fingerprint Instead',
      child: InkWell(
        onTap: widget.onFingerprint,
        borderRadius: BorderRadius.circular(16.r),
        child: Padding(
          padding: EdgeInsets.all(8.r),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _fingerprintShadowTint.withValues(alpha: 0.10),
                      blurRadius: 5.r,
                      offset: Offset(0, 2.h),
                    ),
                    BoxShadow(
                      color: _fingerprintShadowTint.withValues(alpha: 0.09),
                      blurRadius: 10.r,
                      offset: Offset(0, 10.h),
                    ),
                    BoxShadow(
                      color: _fingerprintShadowTint.withValues(alpha: 0.05),
                      blurRadius: 13.r,
                      offset: Offset(0, 22.h),
                    ),
                    BoxShadow(
                      color: _fingerprintShadowTint.withValues(alpha: 0.01),
                      blurRadius: 16.r,
                      offset: Offset(0, 40.h),
                    ),
                  ],
                ),
                child: SvgPicture.asset(
                  FileConstants.fingerprintButton,
                  width: fingerprintSize,
                  height: fingerprintSize,
                ),
              ),
              SizedBox(height: 13.h),
              Text(
                'Use Fingerprint Instead',
                textAlign: TextAlign.center,
                style: authTextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
