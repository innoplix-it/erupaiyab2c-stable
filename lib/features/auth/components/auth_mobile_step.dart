import 'dart:math' as math;

import 'package:e_rupaiya/constants/app_colors.dart';
import 'package:e_rupaiya/constants/file_constants.dart';
import 'package:e_rupaiya/constants/routes_constant.dart';
import 'package:e_rupaiya/features/auth/components/auth_step_parts.dart';
import 'package:e_rupaiya/features/auth/components/login_services_slider.dart';
import 'package:e_rupaiya/widgets/custom_elevated_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

/// Login mobile step: Figma "Pay Bills & Earn" layout.
///
/// Figma frame is 440 wide, so EVERY size here (fonts, gaps, field, button,
/// margins) is a Figma px value multiplied by [scaleFor] (= width / 440).
/// This is the same maths the slider already uses, so form and slider stay in
/// proportion on every phone (no `.sp` / `.h` mixing).
///
/// Keyboard closed: 4-row service marquee on top, form below.
/// Keyboard open / field focused (or short viewport): 2 larger faded rows sit
/// BEHIND the form, which overlaps them (Figma keyboard frame).
class AuthMobileStep extends StatefulWidget {
  const AuthMobileStep({
    super.key,
    required this.controller,
    this.focusNode,
    this.isLoading = false,
    this.onContinue,
    this.referralBanner,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final bool isLoading;
  final VoidCallback? onContinue;
  final Widget? referralBanner;

  /// Figma frame width the form is authored against.
  static const double figmaFrameWidth = 440;

  /// Figma px -> dp factor for a given screen width.
  static double scaleFor(double width) =>
      (width / figmaFrameWidth).clamp(0.72, 1.1).toDouble();

  /// Closed (Figma): soft seam into solid white Pay Bills & Earn band.
  static const LinearGradient _closedBandGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x00FFFFFF), Color(0xFFFFFFFF), Color(0xFFFFFFFF)],
    stops: [0.0, 0.08, 1.0],
  );

  /// Keyboard open (Figma):
  /// `linear-gradient(180deg, rgba(255,255,255,0.5) 0%, #FFFFFF 65%)`
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

  static const Color _ink = Color(0xFF000000);
  static const Color _continueDisabledFill = Color(0xFFE3E3E6);
  static const Color _continueDisabledLabel = Color(0xFF64646B);

  /// Figma px: logo top -> Terms/Privacy bottom (closed layout).
  static const double formReserveDesign = 371;

  /// Figma px: Terms/Privacy bottom -> screen bottom (home indicator incl.).
  static const double closedBottomGapDesign = 51;

  /// Figma px: Terms/Privacy bottom -> keyboard top.
  static const double overlayBottomGapDesign = 29;

  static const double referralExtraDesign = 72;

  @override
  State<AuthMobileStep> createState() => _AuthMobileStepState();
}

class _AuthMobileStepState extends State<AuthMobileStep>
    with WidgetsBindingObserver {
  late FocusNode _focus;
  bool _ownsFocus = false;
  bool _hadKeyboard = false;
  bool _focusLostBeforeKeyboard = false;

  bool get _phoneValid {
    final digits = widget.controller.text.replaceAll(RegExp(r'\D'), '');
    return digits.length == 10;
  }

  @override
  void initState() {
    super.initState();
    _attachFocus();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didUpdateWidget(covariant AuthMobileStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      _detachFocus();
      _attachFocus();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _detachFocus();
    super.dispose();
  }

  void _attachFocus() {
    final external = widget.focusNode;
    _ownsFocus = external == null;
    _focus = external ?? FocusNode(debugLabel: 'AuthMobileStepPhone');
    _focus.addListener(_onFocusChanged);
  }

  void _detachFocus() {
    _focus.removeListener(_onFocusChanged);
    if (_ownsFocus) _focus.dispose();
  }

  void _onFocusChanged() {
    if (!mounted) return;
    final hasFocus = _focus.hasFocus;
    final inset = View.maybeOf(context)?.viewInsets.bottom ?? 0;
    // Track if focus was lost while keyboard was still open (user dismissal)
    if (!hasFocus && inset > 0) {
      _focusLostBeforeKeyboard = true;
    } else if (hasFocus && inset == 0) {
      _focusLostBeforeKeyboard = false;
    }
    setState(() {});
  }

  /// Keyboard hidden (Android back / iOS dismiss) -> unfocus so the closed
  /// layout comes back instead of staying in overlay mode. Does not unfocus
  /// when focus is retained (e.g., phone hint sheet hid the keyboard).
  @override
  void didChangeMetrics() {
    if (!mounted) return;
    final inset = View.maybeOf(context)?.viewInsets.bottom ?? 0;
    if (inset > 0) {
      _hadKeyboard = true;
    } else if (_hadKeyboard) {
      _hadKeyboard = false;
      // Only unfocus if focus was already lost before keyboard hid (user action)
      // If focus is still retained, an external sheet hid the keyboard
      if (_focusLostBeforeKeyboard) {
        _focus.unfocus();
        _focusLostBeforeKeyboard = false;
      }
    }
  }

  void _dismissKeyboard() => FocusManager.instance.primaryFocus?.unfocus();

  @override
  Widget build(BuildContext context) {
    final fieldEnabled = !widget.isLoading;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final topInset = MediaQuery.paddingOf(context).top;
    final bottomSafe = MediaQuery.paddingOf(context).bottom;
    final referralBanner = widget.referralBanner;
    final k = AuthMobileStep.scaleFor(screenWidth);
    double f(double figmaPx) => figmaPx * k;

    return AuthKeyboardOnOpen(
      focusNode: widget.focusNode,
      autofocus: false,
      enabled: fieldEnabled,
      child: SizedBox.expand(
        child: LayoutBuilder(
          builder: (context, viewport) {
            final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0 ||
                (View.maybeOf(context)?.viewInsets.bottom ?? 0) > 0;
            final focused = _focus.hasFocus;

            final topPad = topInset + f(6);
            final available = (viewport.maxHeight - topPad)
                .clamp(0.0, double.infinity)
                .toDouble();
            final shortViewport = available < 420;

            // Keyboard / focus / short viewport lifts the form.
            final overlay = keyboardOpen || focused || shortViewport;
            final rowCount = overlay ? 2 : 4;

            final termsBottomGap = overlay
                ? f(AuthMobileStep.overlayBottomGapDesign)
                : math.max(
                    f(AuthMobileStep.closedBottomGapDesign),
                    bottomSafe + f(8),
                  );

            final double sliderH;
            if (overlay) {
              final natural = LoginServicesSlider.naturalHeight(
                screenWidth,
                rowCount,
                compact: true,
              );
              sliderH = math.min(natural, available * 0.7);
            } else {
              final formReserve = f(AuthMobileStep.formReserveDesign) +
                  termsBottomGap +
                  (referralBanner != null
                      ? f(AuthMobileStep.referralExtraDesign)
                      : 0);
              // Prefer natural height, but never steal the Terms inset.
              final budget = (available - formReserve)
                  .clamp(0.0, available * 0.56)
                  .toDouble();
              final natural = LoginServicesSlider.naturalHeight(
                screenWidth,
                rowCount,
              );
              sliderH = math.min(natural, budget);
            }

            // Figma CSS: linear-gradient(179.93deg, #DD5428 -13.84%, #FFFFFF 96.21%)
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
                      // Layer 1: slider stays mounted so marquee never restarts.
                      Positioned(
                        top: topPad,
                        left: 0,
                        right: 0,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: sliderH,
                            minHeight: 0,
                          ),
                          child: LoginServicesSlider(
                            rowCount: rowCount,
                            compact: overlay,
                          ),
                        ),
                      ),
                      // Layer 2: form. Overlay = rise up + translucent band.
                      Positioned.fill(
                        child: Column(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeOut,
                              height: overlay ? 0 : topPad + sliderH,
                            ),
                            Expanded(
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 220),
                                curve: Curves.easeOut,
                                decoration: BoxDecoration(
                                  gradient: overlay
                                      ? AuthMobileStep._overlayBandGradient
                                      : AuthMobileStep._closedBandGradient,
                                ),
                                child: AnimatedPadding(
                                  duration: const Duration(milliseconds: 220),
                                  curve: Curves.easeOut,
                                  // Figma side margins: 32 closed / 20 keyboard.
                                  // Terms gap is a dedicated footer SizedBox so
                                  // scroll overflow cannot eat the inset.
                                  padding: EdgeInsets.symmetric(
                                    horizontal: f(overlay ? 20 : 32),
                                  ),
                                  child: Align(
                                    alignment: Alignment.bottomCenter,
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxWidth: authContentMaxWidth(context),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          Expanded(
                                            child: LayoutBuilder(
                                              builder: (context, constraints) {
                                                return SingleChildScrollView(
                                                  physics:
                                                      const ClampingScrollPhysics(),
                                                  child: ConstrainedBox(
                                                    constraints: BoxConstraints(
                                                      minHeight:
                                                          constraints.maxHeight,
                                                    ),
                                                    child: Column(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment.end,
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .stretch,
                                                      children: [
                                                        Center(
                                                          child: Image.asset(
                                                            FileConstants
                                                                .erupaiyaLogo,
                                                            width: f(
                                                              overlay ? 60 : 64,
                                                            ),
                                                            height: f(
                                                              overlay ? 60 : 64,
                                                            ),
                                                            fit: BoxFit.contain,
                                                          ),
                                                        ),
                                                        SizedBox(height: f(12)),
                                                        Text(
                                                          'Pay Bills & Earn',
                                                          textAlign:
                                                              TextAlign.center,
                                                          style: TextStyle(
                                                            fontSize: f(20),
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            color:
                                                                AuthMobileStep
                                                                    ._ink,
                                                            height: 1.2,
                                                          ),
                                                        ),
                                                        SizedBox(height: f(10)),
                                                        Text(
                                                          'Enter your mobile number to continue.',
                                                          textAlign:
                                                              TextAlign.center,
                                                          style: TextStyle(
                                                            fontSize: f(16),
                                                            fontWeight:
                                                                FontWeight.w400,
                                                            color:
                                                                AuthMobileStep
                                                                    ._ink,
                                                            height: 1.3,
                                                          ),
                                                        ),
                                                        if (referralBanner !=
                                                            null) ...[
                                                          SizedBox(
                                                              height: f(12)),
                                                          referralBanner,
                                                        ],
                                                        SizedBox(
                                                          height:
                                                              referralBanner !=
                                                                      null
                                                                  ? f(16)
                                                                  : f(
                                                                      overlay
                                                                          ? 36
                                                                          : 40,
                                                                    ),
                                                        ),
                                                        Text(
                                                          'Mobile Number',
                                                          style: TextStyle(
                                                            fontSize: f(14),
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            color:
                                                                AuthMobileStep
                                                                    ._ink,
                                                          ),
                                                        ),
                                                        SizedBox(height: f(8)),
                                                        _FigmaMobileField(
                                                          controller:
                                                              widget.controller,
                                                          focusNode: _focus,
                                                          enabled: fieldEnabled,
                                                          k: k,
                                                        ),
                                                        SizedBox(
                                                          height: f(
                                                            overlay ? 12 : 18,
                                                          ),
                                                        ),
                                                        ListenableBuilder(
                                                          listenable:
                                                              widget.controller,
                                                          builder:
                                                              (context, _) {
                                                            final canContinue =
                                                                _phoneValid &&
                                                                    !widget
                                                                        .isLoading;
                                                            return CustomElevatedButton(
                                                              label: 'Continue',
                                                              uppercaseLabel:
                                                                  false,
                                                              onPressed: canContinue
                                                                  ? widget
                                                                      .onContinue
                                                                  : null,
                                                              isLoading: widget
                                                                  .isLoading,
                                                              backgroundColor: canContinue
                                                                  ? AppColors
                                                                      .primary
                                                                  : AuthMobileStep
                                                                      ._continueDisabledFill,
                                                              labelColor: canContinue
                                                                  ? Colors.white
                                                                  : AuthMobileStep
                                                                      ._continueDisabledLabel,
                                                              height: f(50),
                                                            );
                                                          },
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                          SizedBox(
                                            height: f(overlay ? 15 : 18),
                                          ),
                                          Text(
                                            'By continuing, you agree to our',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: f(12),
                                              fontWeight: FontWeight.w400,
                                              color: AuthMobileStep._ink,
                                            ),
                                          ),
                                          SizedBox(height: f(2)),
                                          Wrap(
                                            alignment: WrapAlignment.center,
                                            crossAxisAlignment:
                                                WrapCrossAlignment.center,
                                            children: [
                                              GestureDetector(
                                                onTap: () => context.push(
                                                  RouteConstants.termsPrivacy,
                                                ),
                                                child: Text(
                                                  'Terms of Use',
                                                  style: TextStyle(
                                                    fontSize: f(12),
                                                    fontWeight: FontWeight.w400,
                                                    color: AppColors.primary,
                                                    decoration: TextDecoration
                                                        .underline,
                                                    decorationColor:
                                                        AppColors.primary,
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                ' & ',
                                                style: TextStyle(
                                                  fontSize: f(12),
                                                  fontWeight: FontWeight.w400,
                                                  color: AuthMobileStep._ink,
                                                ),
                                              ),
                                              GestureDetector(
                                                onTap: () => context.push(
                                                  RouteConstants.privacyPolicy,
                                                ),
                                                child: Text(
                                                  'Privacy Policy',
                                                  style: TextStyle(
                                                    fontSize: f(12),
                                                    fontWeight: FontWeight.w400,
                                                    color: AppColors.primary,
                                                    decoration: TextDecoration
                                                        .underline,
                                                    decorationColor:
                                                        AppColors.primary,
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
                          ],
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
}

/// Figma-styled +91 / divider / placeholder field (local to this step).
/// [k] = Figma px -> dp factor (screen width / 440).
class _FigmaMobileField extends StatelessWidget {
  const _FigmaMobileField({
    required this.controller,
    required this.k,
    this.focusNode,
    this.enabled = true,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final bool enabled;
  final double k;

  static const Color _ink = Color(0xFF000000);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56 * k,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16 * k),
        border: Border.all(color: const Color(0xFFE4E4E7)),
      ),
      padding: EdgeInsets.symmetric(horizontal: 20 * k),
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
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              enabled: enabled,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              style: TextStyle(
                fontSize: 14 * k,
                fontWeight: FontWeight.w500,
                color: _ink,
              ),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'Enter 10 Digit Mobile Number',
                hintStyle: TextStyle(
                  fontSize: 14 * k,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFFA1A1AA),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
