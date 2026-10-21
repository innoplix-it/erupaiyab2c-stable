import 'dart:math' as math;

import 'package:e_rupaiya/constants/app_colors.dart';
import 'package:e_rupaiya/constants/file_constants.dart';
import 'package:e_rupaiya/constants/routes_constant.dart';
import 'package:e_rupaiya/features/auth/components/login_services_slider.dart';
import 'package:e_rupaiya/widgets/custom_elevated_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import 'auth_code_fields.dart';
import 'auth_feedback.dart';
import 'auth_step_parts.dart';

/// Login PIN step — same Figma shell as [AuthMobileStep] (peach band,
/// 4-row / 2-row marquee, lifted form when the keyboard is open).
/// Presentation only; login / Forgot PIN / edit-mobile stay as callbacks.
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
    this.layoutActive = true,
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

  /// When false, skip keyboard metrics/focus updates (hidden in [IndexedStack]).
  final bool layoutActive;
  final Widget? referralBanner;
  final AuthShakeController? shakeController;
  final String? errorText;
  final ValueChanged<String>? onPinChanged;

  static const double figmaFrameWidth = 440;

  static double scaleFor(double width) =>
      (width / figmaFrameWidth).clamp(0.72, 1.1).toDouble();

  static const LinearGradient _closedBandGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x00FFFFFF), Color(0xFFFFFFFF), Color(0xFFFFFFFF)],
    stops: [0.0, 0.08, 1.0],
  );

  static const LinearGradient _overlayBandGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0x80FFFFFF),
      Color(0xFFFFFFFF),
      Color(0xFFFFFFFF),
    ],
    stops: [0.0, 0.65, 1.0],
  );

  static const double logoWidthDesign = 158;
  static const double logoHeightDesign = 34;
  static const double formReserveDesign = 520;
  static const double closedBottomGapDesign = 51;
  static const double overlayBottomGapDesign = 29;
  static const double referralExtraDesign = 72;
  static const Duration _anim = Duration(milliseconds: 220);

  @override
  State<AuthPinStep> createState() => _AuthPinStepState();
}

class _AuthPinStepState extends State<AuthPinStep> with WidgetsBindingObserver {
  bool _obscure = true;
  bool _hadKeyboard = false;

  /// Keeps the lifted keypad layout while Continue is processing.
  bool _keepLifted = false;

  double _lastInset = 0;

  static const Color _ink = Color(0xFF000000);
  static const Color _subtitle = Color(0xFF71717A);
  static const Color _continueDisabledFill = Color(0xFFE3E3E6);
  static const Color _continueDisabledLabel = Color(0xFF64646B);

  double _readKeyboardInset(BuildContext context) {
    final fromMediaQuery = MediaQuery.viewInsetsOf(context).bottom;
    final fromView = View.maybeOf(context)?.viewInsets.bottom ?? 0;
    return math.max(fromMediaQuery, fromView);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.pinFocusNode.addListener(_onFocusChanged);
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
    if (!oldWidget.layoutActive && widget.layoutActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !widget.layoutActive) return;
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
    if (!mounted || !widget.layoutActive) return;
    if (widget.pinFocusNode.hasFocus) {
      if (!_keepLifted) {
        setState(() => _keepLifted = true);
      }
      return;
    }
    if (_keepLifted && (_hadKeyboard || _lastInset > 0)) return;
  }

  @override
  void didChangeMetrics() {
    if (!mounted || !widget.layoutActive) return;
    final inset = _readKeyboardInset(context);
    if (inset > 0) {
      _lastInset = math.max(_lastInset, inset);
      if (!_hadKeyboard || !_keepLifted) {
        setState(() {
          _hadKeyboard = true;
          _keepLifted = true;
        });
      }
      return;
    }
    if (widget.pinFocusNode.hasFocus && (_hadKeyboard || _keepLifted)) {
      return;
    }
    if (!_hadKeyboard) return;
    _hadKeyboard = false;
    if (widget.isLoading) return;
    if (widget.pinFocusNode.hasFocus) {
      widget.pinFocusNode.unfocus();
    }
    if (!widget.pinFocusNode.hasFocus && _keepLifted) {
      setState(() {
        _keepLifted = false;
        _lastInset = 0;
      });
    }
  }

  void _dismissKeyboard() {
    if (widget.isLoading) return;
    _keepLifted = false;
    _lastInset = 0;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final screenWidth = size.width;
    final topInset = MediaQuery.paddingOf(context).top;
    final bottomSafe = MediaQuery.paddingOf(context).bottom;
    final k = AuthPinStep.scaleFor(screenWidth);
    double f(double figmaPx) => figmaPx * k;
    final referralBanner = widget.referralBanner;
    final inset = _readKeyboardInset(context);
    if (inset > 0) {
      _lastInset = math.max(_lastInset, inset);
    }
    final holdInset =
        widget.isLoading ? math.max(0.0, _lastInset - inset) : 0.0;

    return AuthKeyboardOnOpen(
      focusNode: widget.pinFocusNode,
      autofocus: widget.layoutActive,
      enabled: widget.layoutActive,
      child: SizedBox.expand(
        child: LayoutBuilder(
          builder: (context, viewport) {
            final keyboardOpen = inset > 0 || _lastInset > 0;
            final focused = widget.pinFocusNode.hasFocus;
            final bodyHeight = math.max(0.0, viewport.maxHeight - holdInset);
            final topPad = topInset + f(6);
            final available = math.max(0.0, bodyHeight - topPad);
            final shortViewport = available < 420;
            final overlay = keyboardOpen ||
                focused ||
                shortViewport ||
                widget.isLoading ||
                _keepLifted ||
                _hadKeyboard;
            final rowCount = overlay ? 2 : 4;
            final termsBottomGap = overlay
                ? f(AuthPinStep.overlayBottomGapDesign)
                : math.max(
                    f(AuthPinStep.closedBottomGapDesign),
                    bottomSafe + f(8),
                  );

            final double sliderH;
            if (overlay) {
              sliderH = LoginServicesSlider.naturalHeight(
                screenWidth,
                rowCount,
                compact: true,
              );
            } else {
              final formReserve = f(AuthPinStep.formReserveDesign) +
                  termsBottomGap +
                  (referralBanner != null
                      ? f(AuthPinStep.referralExtraDesign)
                      : 0);
              final budget = (available - formReserve)
                  .clamp(0.0, available * 0.56)
                  .toDouble();
              final natural = LoginServicesSlider.naturalHeight(
                screenWidth,
                rowCount,
              );
              sliderH = math.min(natural, budget);
            }

            return DecoratedBox(
              decoration: const BoxDecoration(
                gradient: AppColors.loginPeachCoralGradient,
              ),
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _dismissKeyboard,
                child: SafeArea(
                  top: false,
                  bottom: false,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Positioned(
                        top: topPad,
                        left: 0,
                        right: 0,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: sliderH,
                            minHeight: 0,
                          ),
                          child: Opacity(
                            opacity: 0.4,
                            child: LoginServicesSlider(
                              rowCount: rowCount,
                              compact: overlay,
                            ),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: Padding(
                          padding: EdgeInsets.only(bottom: holdInset),
                          child: Column(
                            children: [
                              AnimatedContainer(
                                duration: AuthPinStep._anim,
                                curve: Curves.easeOut,
                                height: overlay ? 0 : topPad + sliderH,
                              ),
                              Expanded(
                                child: _buildFormBand(
                                  context,
                                  k: k,
                                  overlay: overlay,
                                  termsBottomGap: termsBottomGap,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFormBand(
    BuildContext context, {
    required double k,
    required bool overlay,
    required double termsBottomGap,
  }) {
    double f(double figmaPx) => figmaPx * k;
    final referralBanner = widget.referralBanner;

    return AnimatedContainer(
      duration: AuthPinStep._anim,
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        gradient: overlay
            ? AuthPinStep._overlayBandGradient
            : AuthPinStep._closedBandGradient,
      ),
      child: AnimatedPadding(
        duration: AuthPinStep._anim,
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(horizontal: f(overlay ? 20 : 32)),
        child: Align(
          alignment: Alignment.bottomLeft,
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
                                  width: f(AuthPinStep.logoWidthDesign),
                                  height: f(AuthPinStep.logoHeightDesign),
                                  fit: BoxFit.contain,
                                  alignment: Alignment.centerLeft,
                                ),
                              ),
                              SizedBox(height: f(overlay ? 16 : 18)),
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
                                'Enter your PIN to continue.',
                                textAlign: TextAlign.start,
                                style: TextStyle(
                                  fontSize: f(14),
                                  fontWeight: FontWeight.w400,
                                  color: _subtitle,
                                  height: 1.35,
                                ),
                              ),
                              if (referralBanner != null) ...[
                                SizedBox(height: f(12)),
                                SizedBox(
                                  width: double.infinity,
                                  child: referralBanner,
                                ),
                              ],
                              SizedBox(
                                height: referralBanner != null
                                    ? f(16)
                                    : f(overlay ? 14 : 28),
                              ),
                              Text(
                                'Mobile Number',
                                style: TextStyle(
                                  fontSize: f(14),
                                  fontWeight: FontWeight.w700,
                                  color: _ink,
                                ),
                              ),
                              SizedBox(height: f(8)),
                              ListenableBuilder(
                                listenable: widget.mobileController,
                                builder: (context, _) {
                                  return _PinStepMobileField(
                                    controller: widget.mobileController,
                                    k: k,
                                    onTap: widget.isLoading
                                        ? null
                                        : widget.onEditMobile,
                                  );
                                },
                              ),
                              SizedBox(height: f(overlay ? 8 : 12)),
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
                                enabled: true,
                                hasError: widget.errorText != null &&
                                    widget.errorText!.isNotEmpty,
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
                        widget.pinController.text.length == widget.pinLength;
                    return CustomElevatedButton(
                      label: 'Continue',
                      uppercaseLabel: false,
                      onPressed: canContinue ? widget.onContinue : null,
                      isLoading: widget.isLoading,
                      backgroundColor: canContinue
                          ? AppColors.primary
                          : _continueDisabledFill,
                      labelColor:
                          canContinue ? Colors.white : _continueDisabledLabel,
                      height: f(50),
                    );
                  },
                ),
                SizedBox(height: f(overlay ? 15 : 18)),
                _buildTerms(context, k),
                SizedBox(height: termsBottomGap),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTerms(BuildContext context, double k) {
    double f(double figmaPx) => figmaPx * k;
    final linkStyle = TextStyle(
      fontSize: f(12),
      fontWeight: FontWeight.w400,
      color: AppColors.primary,
      decoration: TextDecoration.underline,
      decorationColor: AppColors.primary,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
              onTap: () => context.push(RouteConstants.termsPrivacy),
              child: Text('Terms of Use', style: linkStyle),
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
              onTap: () => context.push(RouteConstants.privacyPolicy),
              child: Text('Privacy Policy', style: linkStyle),
            ),
          ],
        ),
      ],
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
