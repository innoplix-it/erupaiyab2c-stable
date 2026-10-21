import 'package:e_rupaiya/constants/app_colors.dart';
import 'package:e_rupaiya/constants/file_constants.dart';
import 'package:e_rupaiya/constants/routes_constant.dart';
import 'package:e_rupaiya/widgets/custom_elevated_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import 'auth_code_fields.dart';
import 'auth_feedback.dart';
import 'auth_step_parts.dart';

/// Login PIN step — same Figma shell as [AuthMobileStep] (peach band +
/// marquee + wordmark + terms). Presentation only; login / Forgot PIN /
/// edit-mobile stay as callbacks.
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
  final AuthShakeController? shakeController;
  final String? errorText;
  final ValueChanged<String>? onPinChanged;

  static const double figmaFrameWidth = 440;

  static double scaleFor(double width) =>
      (width / figmaFrameWidth).clamp(0.72, 1.1).toDouble();

  @override
  State<AuthPinStep> createState() => _AuthPinStepState();
}

class _AuthPinStepState extends State<AuthPinStep> with WidgetsBindingObserver {
  bool _obscure = true;
  bool _hadKeyboard = false;

  /// Keeps the lifted keypad layout while Continue is processing.
  bool _keepLifted = false;

  static const Color _ink = Color(0xFF000000);
  static const Color _subtitle = Color(0xFF71717A);
  static const Color _continueDisabledFill = Color(0xFFE3E3E6);
  static const Color _continueDisabledLabel = Color(0xFF64646B);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.pinFocusNode.addListener(_onFocusChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showAuthKeyboard(widget.pinFocusNode);
    });
  }

  @override
  void didUpdateWidget(covariant AuthPinStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isLoading && widget.isLoading) {
      _keepLifted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !widget.isLoading) return;
        showAuthKeyboard(widget.pinFocusNode);
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.pinFocusNode.removeListener(_onFocusChanged);
    super.dispose();
  }

  void _onFocusChanged() {
    if (!mounted) return;
    if (widget.pinFocusNode.hasFocus) _keepLifted = true;
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
      // Processing Continue: never unfocus / drop the lifted form.
      if (widget.isLoading) {
        setState(() {});
        return;
      }
      if (widget.pinFocusNode.hasFocus) {
        widget.pinFocusNode.unfocus();
      }
      if (!widget.pinFocusNode.hasFocus) _keepLifted = false;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final bottomSafe = MediaQuery.paddingOf(context).bottom;
    final k = AuthPinStep.scaleFor(screenWidth);
    double f(double figmaPx) => figmaPx * k;

    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0 ||
        (View.maybeOf(context)?.viewInsets.bottom ?? 0) > 0;
    final focused = widget.pinFocusNode.hasFocus;
    final lifted =
        keyboardOpen || focused || widget.isLoading || _keepLifted;
    final termsBottomGap = lifted
        ? f(29)
        : (f(51) > bottomSafe + f(8) ? f(51) : bottomSafe + f(8));

    return AuthKeyboardOnOpen(
      focusNode: widget.pinFocusNode,
      autofocus: true,
      // Stay enabled while loading so keypad/layout do not drop.
      enabled: true,
      // Same peach + animated marquee shell as OTP (Figma).
      child: AuthPeachMarqueeShell(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: f(20)),
          child: Align(
            alignment: Alignment.bottomLeft,
            child: SizedBox(
              width: double.infinity,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: authContentMaxWidth(context),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            physics: const ClampingScrollPhysics(),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: constraints.maxHeight,
                                minWidth: constraints.maxWidth,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: SvgPicture.asset(
                                      FileConstants.erupaiyaLogoWordmarkSvg,
                                      width: f(158),
                                      height: f(34),
                                      fit: BoxFit.contain,
                                      alignment: Alignment.centerLeft,
                                    ),
                                  ),
                                  SizedBox(height: f(16)),
                                  Text(
                                    'Welcome to eRupaiya',
                                    textAlign: TextAlign.start,
                                    style: TextStyle(
                                      fontSize: f(20),
                                      fontWeight: FontWeight.w700,
                                      color: _ink,
                                      height: 1.2,
                                    ),
                                  ),
                                  SizedBox(height: f(8)),
                                  Text(
                                    'Enter your mobile number to continue.',
                                    textAlign: TextAlign.start,
                                    style: TextStyle(
                                      fontSize: f(14),
                                      fontWeight: FontWeight.w400,
                                      color: _subtitle,
                                      height: 1.35,
                                    ),
                                  ),
                                  if (widget.referralBanner != null) ...[
                                    SizedBox(height: f(12)),
                                    widget.referralBanner!,
                                  ],
                                  SizedBox(height: f(28)),
                                  Text(
                                    'Mobile Number',
                                    style: TextStyle(
                                      fontSize: f(14),
                                      fontWeight: FontWeight.w700,
                                      color: _ink,
                                    ),
                                  ),
                                  SizedBox(height: f(8)),
                                  _PinStepMobileField(
                                    controller: widget.mobileController,
                                    k: k,
                                    onTap: widget.isLoading
                                        ? null
                                        : widget.onEditMobile,
                                  ),
                                  SizedBox(height: f(12)),
                                  Text(
                                    'Enter Pin',
                                    style: TextStyle(
                                      fontSize: f(14),
                                      fontWeight: FontWeight.w700,
                                      color: _ink,
                                    ),
                                  ),
                                  SizedBox(height: f(10)),
                                  AuthPinBoxes(
                                    controller: widget.pinController,
                                    focusNode: widget.pinFocusNode,
                                    shakeController: widget.shakeController,
                                    length: widget.pinLength,
                                    obscure: _obscure,
                                    autofocus: true,
                                    // Keep focusable while loading so layout
                                    // does not drop (Continue still no-ops
                                    // via isLoading gate).
                                    enabled: true,
                                    hasError: widget.errorText != null,
                                    onChanged: widget.isLoading
                                        ? null
                                        : widget.onPinChanged,
                                    onCompleted: widget.isLoading
                                        ? null
                                        : (_) => widget.onContinue(),
                                  ),
                                  SizedBox(height: f(2)),
                                  AuthPinActionsRow(
                                    obscure: _obscure,
                                    onToggle: () =>
                                        setState(() => _obscure = !_obscure),
                                    onForgotPin: widget.isLoading
                                        ? null
                                        : widget.onForgotPin,
                                    errorText: widget.errorText,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: f(12)),
                    ListenableBuilder(
                      listenable: widget.pinController,
                      builder: (context, _) {
                        final canContinue = !widget.isLoading &&
                            widget.pinController.text.length ==
                                widget.pinLength;
                        return CustomElevatedButton(
                          label: 'Continue',
                          uppercaseLabel: false,
                          onPressed:
                              canContinue ? widget.onContinue : null,
                          isLoading: widget.isLoading,
                          backgroundColor: canContinue
                              ? AppColors.primary
                              : _continueDisabledFill,
                          labelColor: canContinue
                              ? Colors.white
                              : _continueDisabledLabel,
                          height: f(50),
                        );
                      },
                    ),
                    SizedBox(height: f(15)),
                    Text(
                      'By continuing, you agree to our',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: f(12),
                        fontWeight: FontWeight.w400,
                        color: _ink,
                      ),
                    ),
                    SizedBox(height: f(2)),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () =>
                              context.push(RouteConstants.termsPrivacy),
                          child: Text(
                            'Terms of Use',
                            style: TextStyle(
                              fontSize: f(12),
                              fontWeight: FontWeight.w400,
                              color: AppColors.primary,
                              decoration: TextDecoration.underline,
                              decorationColor: AppColors.primary,
                            ),
                          ),
                        ),
                        Text(
                          ' & ',
                          style: TextStyle(
                            fontSize: f(12),
                            fontWeight: FontWeight.w400,
                            color: _ink,
                          ),
                        ),
                        GestureDetector(
                          onTap: () =>
                              context.push(RouteConstants.privacyPolicy),
                          child: Text(
                            'Privacy Policy',
                            style: TextStyle(
                              fontSize: f(12),
                              fontWeight: FontWeight.w400,
                              color: AppColors.primary,
                              decoration: TextDecoration.underline,
                              decorationColor: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: termsBottomGap),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PinStepMobileField extends StatelessWidget {
  const _PinStepMobileField({
    required this.controller,
    required this.k,
    this.onTap,
  });

  final TextEditingController controller;
  final double k;
  final VoidCallback? onTap;

  static const Color _ink = Color(0xFF000000);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56 * k,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16 * k),
          border: Border.all(color: const Color(0xFFE4E4E7)),
        ),
        padding: EdgeInsets.symmetric(horizontal: 20 * k),
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            Text(
              '+91',
              style: TextStyle(
                fontSize: 14 * k,
                fontWeight: FontWeight.w500,
                color: _ink,
              ),
            ),
            SizedBox(width: 10 * k),
            Container(
              width: 1,
              height: 24 * k,
              color: const Color(0xFFE4E4E7),
            ),
            SizedBox(width: 10 * k),
            Expanded(
              child: Text(
                controller.text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14 * k,
                  fontWeight: FontWeight.w500,
                  color: _ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
