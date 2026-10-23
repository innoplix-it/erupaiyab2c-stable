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
  double _heldGap = 0;
  bool _continueHeld = false;
  int _continueStamp = 0;

  static const Color _ink = Color(0xFF000000);
  static const Color _subtitle = Color(0xFF71717A);
  static const Color _continueDisabledFill = Color(0xFFE3E3E6);
  static const Color _continueDisabledLabel = Color(0xFF64646B);

  double _readKeyboardInset(BuildContext context) {
    final fromMediaQuery = MediaQuery.viewInsetsOf(context).bottom;
    final view = View.maybeOf(context);
    if (view == null) return fromMediaQuery;
    final dpr = view.devicePixelRatio <= 0 ? 1.0 : view.devicePixelRatio;
    // View insets are physical pixels. Mixing them with logical dp made the
    // held gap taller than the screen and crushed the form (37px overflow).
    return math.max(fromMediaQuery, view.viewInsets.bottom / dpr);
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
    if (!_hadKeyboard) return;
    if (widget.isLoading || _continueHeld) return;
    _hadKeyboard = false;
    if (widget.pinFocusNode.hasFocus) {
      widget.pinFocusNode.unfocus();
    }
    setState(() {
      _keepLifted = false;
      _lastInset = 0;
    });
  }

  void _onContinuePressed() {
    _continueStamp = DateTime.now().millisecondsSinceEpoch;
    _continueHeld = true;
    _keepLifted = true;
    _hadKeyboard = true;
    widget.onContinue();
    setState(() {});
  }

  void _dismissKeyboard() {
    if (widget.isLoading) return;
    if (DateTime.now().millisecondsSinceEpoch - _continueStamp < 400) return;
    _continueHeld = false;
    _keepLifted = false;
    _lastInset = 0;
    _heldGap = 0;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final screenWidth = size.width;
    final k = AuthPinStep.scaleFor(screenWidth);
    double f(double figmaPx) => figmaPx * k;
    final referralBanner = widget.referralBanner;
    final frozen = widget.isLoading || _continueHeld;
    if (_lastInset > size.height) _lastInset = 0;
    final lifted = _hadKeyboard ||
        _lastInset > 0 ||
        widget.pinFocusNode.hasFocus ||
        widget.isLoading ||
        _keepLifted;

    return AuthKeyboardOnOpen(
      focusNode: widget.pinFocusNode,
      autofocus: widget.layoutActive,
      enabled: widget.layoutActive,
      child: AuthKeyboardSlot(
        screenHeight: size.height,
        topExtra: f(6),
        frozen: frozen,
        heldGap: _heldGap,
        lifted: lifted,
        onGap: (gap) => _heldGap = gap,
        onOpened: _onKeyboardOpened,
        onDismiss: _dismissKeyboard,
        buildSlider: (frame) {
          final overlay = frame.overlay;
          return ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: _sliderHeight(
                f,
                screenWidth: screenWidth,
                overlay: overlay,
                available: frame.available,
                bottomSafe: frame.bottomSafe,
                referralBanner: referralBanner,
              ),
              minHeight: 0,
            ),
            child: LoginServicesSlider(
              rowCount: overlay ? 2 : 4,
              compact: overlay,
              opacity: overlay ? 0.4 : 1,
            ),
          );
        },
        buildForm: (frame) {
          final overlay = frame.overlay;
          final sliderH = _sliderHeight(
            f,
            screenWidth: screenWidth,
            overlay: overlay,
            available: frame.available,
            bottomSafe: frame.bottomSafe,
            referralBanner: referralBanner,
          );
          final termsBottomGap = overlay
              ? f(AuthPinStep.overlayBottomGapDesign)
              : math.max(
                  f(AuthPinStep.closedBottomGapDesign),
                  frame.bottomSafe + f(8),
                );
          return Column(
            children: [
              AnimatedContainer(
                duration: AuthPinStep._anim,
                curve: Curves.easeOut,
                height: overlay ? 0 : frame.topPad + sliderH,
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
          );
        },
      ),
    );
  }

  double _sliderHeight(
    double Function(double) f, {
    required double screenWidth,
    required bool overlay,
    required double available,
    required double bottomSafe,
    required Widget? referralBanner,
  }) {
    final rowCount = overlay ? 2 : 4;
    if (overlay) {
      return LoginServicesSlider.naturalHeight(
        screenWidth,
        rowCount,
        compact: true,
      );
    }
    final termsBottomGap = math.max(
      f(AuthPinStep.closedBottomGapDesign),
      bottomSafe + f(8),
    );
    final formReserve = f(AuthPinStep.formReserveDesign) +
        termsBottomGap +
        (referralBanner != null ? f(AuthPinStep.referralExtraDesign) : 0);
    final budget =
        (available - formReserve).clamp(0.0, available * 0.56).toDouble();
    final natural = LoginServicesSlider.naturalHeight(screenWidth, rowCount);
    return math.min(natural, budget);
  }

  void _onKeyboardOpened() {
    if (!mounted || !widget.layoutActive) return;
    if (_hadKeyboard && _keepLifted) return;
    setState(() {
      _hadKeyboard = true;
      _keepLifted = true;
    });
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                final minH = constraints.maxHeight.isFinite
                    ? constraints.maxHeight
                    : 0.0;
                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  // When the keypad shortens the band, keep the bottom of the
                  // form (Continue, then the terms) inside the visible area.
                  reverse: overlay,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: minH,
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
                              onTap:
                                  widget.isLoading ? null : widget.onEditMobile,
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
                          onChanged:
                              widget.isLoading ? null : widget.onPinChanged,
                          onCompleted: widget.isLoading
                              ? null
                              : (_) => _onContinuePressed(),
                        ),
                        SizedBox(height: f(2)),
                        AuthPinActionsRow(
                          obscure: _obscure,
                          onToggle: () => setState(() => _obscure = !_obscure),
                          onForgotPin:
                              widget.isLoading ? null : widget.onForgotPin,
                          errorText: widget.errorText,
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
                                  canContinue ? _onContinuePressed : null,
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
                        SizedBox(height: f(overlay ? 15 : 18)),
                        _buildTerms(context, k),
                        SizedBox(height: termsBottomGap),
                      ],
                    ),
                  ),
                );
              },
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
