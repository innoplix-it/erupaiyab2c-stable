import 'dart:async';
import 'dart:math' as math;

import 'package:e_rupaiya/constants/app_colors.dart';
import 'package:e_rupaiya/constants/file_constants.dart';
import 'package:e_rupaiya/constants/routes_constant.dart';
import 'package:e_rupaiya/features/auth/components/auth_step_parts.dart';
import 'package:e_rupaiya/features/auth/components/login_services_slider.dart';
import 'package:e_rupaiya/widgets/custom_elevated_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

/// Login mobile step: Figma welcome / mobile number layout.
///
/// Figma frame is 440 wide, so EVERY size here (fonts, gaps, field, button,
/// margins) is a Figma px value multiplied by [scaleFor] (= width / 440).
/// This is the same maths the slider already uses, so form and slider stay in
/// proportion on every phone (no `.sp` / `.h` mixing).
///
/// Keyboard closed: 4-row service marquee on top, form below.
/// Keyboard open / field focused (or short viewport): 2 larger faded rows sit
/// BEHIND the form, which overlaps them (Figma keyboard frame).
///
/// Stability: once the form has been lifted by the keyboard it is FROZEN while
/// Continue is loading or the route is being left. The bottom inset is held at
/// the last keyboard height, so the eRupaiya logo, title, field, Continue and
/// Terms text stay exactly where they are while the next step slides in.
class AuthMobileStep extends StatefulWidget {
  const AuthMobileStep({
    super.key,
    required this.controller,
    this.focusNode,
    this.isLoading = false,
    this.layoutActive = true,
    this.onContinue,
    this.referralBanner,
    this.onEmptyPhoneFieldTap,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final bool isLoading;

  /// When false (e.g. login [IndexedStack] shows PIN), skip metrics/focus
  /// work so the hidden step does not rebuild on every keyboard frame.
  final bool layoutActive;
  final VoidCallback? onContinue;
  final Widget? referralBanner;

  /// Empty mobile field tapped (e.g. reopen Android phone hint).
  final VoidCallback? onEmptyPhoneFieldTap;

  /// Figma frame width the form is authored against.
  static const double figmaFrameWidth = 440;

  /// Figma px -> dp factor for a given screen width.
  static double scaleFor(double width) =>
      (width / figmaFrameWidth).clamp(0.72, 1.1).toDouble();

  /// Closed (Figma): soft seam into solid white welcome band.
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
  static const Color _subtitle = Color(0xFF71717A);
  static const Color _continueDisabledFill = Color(0xFFE3E3E6);
  static const Color _continueDisabledLabel = Color(0xFF64646B);

  /// Figma wordmark 158×34.
  static const double logoWidthDesign = 158;
  static const double logoHeightDesign = 34;

  /// Figma px: logo top -> Terms/Privacy bottom (closed layout).
  static const double formReserveDesign = 340;

  /// Figma px: Terms/Privacy bottom -> screen bottom (home indicator incl.).
  static const double closedBottomGapDesign = 51;

  /// Figma px: Terms/Privacy bottom -> keyboard top.
  static const double overlayBottomGapDesign = 29;

  static const double referralExtraDesign = 72;

  static const Duration _anim = Duration(milliseconds: 220);

  @override
  State<AuthMobileStep> createState() => _AuthMobileStepState();
}

class _AuthMobileStepState extends State<AuthMobileStep>
    with WidgetsBindingObserver {
  late FocusNode _focus;
  bool _ownsFocus = false;
  bool _hadKeyboard = false;

  /// Once the keypad lifts the form, keep that layout until the user
  /// deliberately dismisses (tap outside) - Continue/loading must not drop
  /// the content box.
  bool _keepLifted = false;

  /// Last real keyboard height. Held while the layout is frozen so content
  /// does not fall to the bottom when the keyboard closes during navigation.
  double _lastInset = 0;

  /// Body-height gap while the keypad is open. Continue keeps this as bottom
  /// padding so the form does not slide to the screen bottom.
  double _heldGap = 0;

  /// Set on Continue, before loading flips, so the form cannot drop.
  bool _continueHeld = false;
  int _continueStamp = 0;

  /// Phone-hint sheet hides the IME before we reopen it. Collapsing in that
  /// gap drops the form after autofill, so the drop waits one beat.
  Timer? _dropLiftTimer;

  bool _routeWasCurrent = true;

  bool get _phoneValid {
    final text = widget.controller.text;
    if (text.length < 10) return false;
    var digits = 0;
    for (final unit in text.codeUnits) {
      if (unit >= 48 && unit <= 57) digits++;
    }
    return digits == 10;
  }

  bool get _routeCurrent => ModalRoute.of(context)?.isCurrent ?? true;

  double _readKeyboardInset(BuildContext context) {
    final fromMediaQuery = MediaQuery.viewInsetsOf(context).bottom;
    final view = View.maybeOf(context);
    if (view == null) return fromMediaQuery;
    final dpr = view.devicePixelRatio <= 0 ? 1.0 : view.devicePixelRatio;
    return math.max(fromMediaQuery, view.viewInsets.bottom / dpr);
  }

  @override
  void initState() {
    super.initState();
    _attachFocus();
    widget.controller.addListener(_onPhoneChanged);
    WidgetsBinding.instance.addObserver(this);
  }

  void _onPhoneChanged() {
    if (!mounted || !widget.layoutActive || !_phoneValid || _keepLifted) return;
    _dropLiftTimer?.cancel();
    setState(() => _keepLifted = true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final current = _routeCurrent;
    // Came back to this step (e.g. back from OTP) with no keyboard: restore
    // the closed layout.
    if (current && !_routeWasCurrent) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final inset = View.maybeOf(context)?.viewInsets.bottom ?? 0;
        if (!_focus.hasFocus && inset == 0 && _keepLifted) {
          setState(() {
            _keepLifted = false;
            _hadKeyboard = false;
            _lastInset = 0;
          });
        }
      });
    }
    _routeWasCurrent = current;
  }

  @override
  void didUpdateWidget(covariant AuthMobileStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      _detachFocus();
      _attachFocus();
    }
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onPhoneChanged);
      widget.controller.addListener(_onPhoneChanged);
    }
    // Continue -> loading: lock lifted layout + keep keypad up.
    if (!oldWidget.isLoading && widget.isLoading) {
      _keepLifted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !widget.isLoading) return;
        showAuthKeyboard(_focus);
      });
    }
  }

  @override
  void dispose() {
    _dropLiftTimer?.cancel();
    widget.controller.removeListener(_onPhoneChanged);
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
    if (!mounted || !widget.layoutActive) return;
    if (_focus.hasFocus) {
      if (!_keepLifted) {
        setState(() => _keepLifted = true);
      }
      return;
    }
    if (_keepLifted && (_hadKeyboard || _lastInset > 0)) return;
  }

  /// Keyboard hidden (Android back / iOS dismiss / keyboard X) -> unfocus so
  /// the closed Figma layout returns. Only rebuilds when something actually
  /// changed, so keyboard animation frames cost nothing here.
  @override
  void didChangeMetrics() {
    if (!mounted || !widget.layoutActive) return;
    final inset = _readKeyboardInset(context);
    if (inset > 0) {
      _dropLiftTimer?.cancel();
      _lastInset = math.max(_lastInset, inset);
      if (!_hadKeyboard || !_keepLifted) {
        setState(() {
          _hadKeyboard = true;
          _keepLifted = true;
        });
      }
      return;
    }
    // resizeToAvoidBottomInset can zero out MediaQuery insets while the
    // keyboard is still visible — keep overlay while the field is focused.
    if (_focus.hasFocus && (_hadKeyboard || _keepLifted)) {
      return;
    }
    if (!_hadKeyboard) return;
    // Processing Continue or leaving this step: never unfocus / drop the form.
    if (widget.isLoading || _continueHeld || !_routeCurrent) return;
    // The number sheet closes the keyboard, then we reopen it. Dropping here
    // puts the filled number back at the bottom.
    _dropLiftTimer?.cancel();
    _dropLiftTimer = Timer(const Duration(milliseconds: 400), () {
      if (!mounted || !widget.layoutActive) return;
      if (_readKeyboardInset(context) > 0 || _focus.hasFocus) return;
      if (widget.isLoading || _continueHeld || !_routeCurrent) return;
      _hadKeyboard = false;
      if (_focus.hasFocus) _focus.unfocus();
      if (_keepLifted) {
        setState(() {
          _keepLifted = false;
          _lastInset = 0;
        });
      }
    });
  }

  void _onContinuePressed() {
    _dropLiftTimer?.cancel();
    _continueStamp = DateTime.now().millisecondsSinceEpoch;
    _continueHeld = true;
    _keepLifted = true;
    _hadKeyboard = true;
    widget.onContinue?.call();
    setState(() {});
  }

  void _dismissKeyboard() {
    if (widget.isLoading) return;
    // The Continue tap can also hit this detector. Ignore that same tap.
    if (DateTime.now().millisecondsSinceEpoch - _continueStamp < 400) return;
    _dropLiftTimer?.cancel();
    _continueHeld = false;
    _hadKeyboard = false;
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
    final topInset = MediaQuery.paddingOf(context).top;
    final bottomSafe = MediaQuery.paddingOf(context).bottom;
    final inset = _readKeyboardInset(context);
    final referralBanner = widget.referralBanner;
    final k = AuthMobileStep.scaleFor(screenWidth);
    double f(double figmaPx) => figmaPx * k;

    // Frozen = Continue is processing or this step is being left. The bottom
    // space the keyboard used to take is kept as padding.
    final frozen = widget.isLoading || _continueHeld || !_routeCurrent;
    if (_lastInset > size.height) _lastInset = inset;
    if (!frozen && inset > 0) {
      _lastInset = math.max(_lastInset, inset);
    }
    final screenHeight = size.height;

    return AuthKeyboardOnOpen(
      focusNode: widget.focusNode,
      autofocus: false,
      enabled: widget.layoutActive,
      child: SizedBox.expand(
        child: LayoutBuilder(
          builder: (context, viewport) {
            final keyboardGap =
                math.max(0.0, screenHeight - viewport.maxHeight);
            if (keyboardGap > 0 && keyboardGap < screenHeight * 0.6) {
              _heldGap = math.max(_heldGap, keyboardGap);
            }
            final rawHold =
                frozen ? math.max(0.0, _heldGap - keyboardGap) : 0.0;
            final maxHold = math.max(0.0, viewport.maxHeight - 320);
            final holdInset = math.min(rawHold, maxHold);
            final keyboardOpen = inset > 0 || _lastInset > 0;
            final focused = _focus.hasFocus;

            final bodyHeight = math.max(0.0, viewport.maxHeight - holdInset);
            final topPad = topInset + f(6);
            final available = math.max(0.0, bodyHeight - topPad);
            final shortViewport = available < 420;

            // Keyboard / focus / short viewport / loading lifts the form.
            final overlay = keyboardOpen ||
                focused ||
                shortViewport ||
                widget.isLoading ||
                _keepLifted ||
                _hadKeyboard;
            final rowCount = overlay ? 2 : 4;

            final termsBottomGap = overlay
                ? f(AuthMobileStep.overlayBottomGapDesign)
                : math.max(
                    f(AuthMobileStep.closedBottomGapDesign),
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
                            opacity: 0.4,
                          ),
                        ),
                      ),
                      // Layer 2: form. Overlay = rise up + translucent band.
                      Positioned.fill(
                        child: RepaintBoundary(
                        child: Padding(
                          padding: EdgeInsets.only(bottom: holdInset),
                          child: Column(
                            children: [
                              AnimatedContainer(
                                duration: AuthMobileStep._anim,
                                curve: Curves.easeOut,
                                height: overlay ? 0 : topPad + sliderH,
                              ),
                              Expanded(
                                child: _buildFormBand(
                                  context,
                                  k: k,
                                  overlay: overlay,
                                  termsBottomGap: termsBottomGap,
                                  referralBanner: referralBanner,
                                ),
                              ),
                            ],
                          ),
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
    required Widget? referralBanner,
  }) {
    double f(double figmaPx) => figmaPx * k;

    return AnimatedContainer(
      duration: AuthMobileStep._anim,
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        gradient: overlay
            ? AuthMobileStep._overlayBandGradient
            : AuthMobileStep._closedBandGradient,
      ),
      child: AnimatedPadding(
        duration: AuthMobileStep._anim,
        curve: Curves.easeOut,
        // Figma side margins: 32 closed / 20 keyboard (MediaQuery width ->
        // scaleFor). Full-width + bottomLeft so brand never centers.
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
                              _LoginBrandWordmark(
                                width: f(AuthMobileStep.logoWidthDesign),
                                height: f(AuthMobileStep.logoHeightDesign),
                              ),
                              SizedBox(height: f(overlay ? 16 : 18)),
                              Text(
                                'Welcome to eRupaiya',
                                textAlign: TextAlign.start,
                                style: TextStyle(
                                  fontSize: f(20),
                                  fontWeight: FontWeight.w700,
                                  color: AuthMobileStep._ink,
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
                                  color: AuthMobileStep._subtitle,
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
                                    : f(overlay ? 28 : 32),
                              ),
                              Text(
                                'Mobile Number',
                                style: TextStyle(
                                  fontSize: f(14),
                                  fontWeight: FontWeight.w700,
                                  color: AuthMobileStep._ink,
                                ),
                              ),
                              SizedBox(height: f(8)),
                              _FigmaMobileField(
                                controller: widget.controller,
                                focusNode: _focus,
                                // Loading: read-only so focus/keyboard stay;
                                // edits are blocked.
                                enabled: true,
                                readOnly: widget.isLoading,
                                onEmptyFieldTap: widget.onEmptyPhoneFieldTap,
                                k: k,
                              ),
                              SizedBox(height: f(overlay ? 12 : 18)),
                              // Only the button listens to the text field, so
                              // typing never rebuilds the rest of the form.
                              ListenableBuilder(
                                listenable: widget.controller,
                                builder: (context, _) {
                                  final canContinue =
                                      _phoneValid && !widget.isLoading;
                                  return CustomElevatedButton(
                                    label: 'Continue',
                                    uppercaseLabel: false,
                                    onPressed: canContinue
                                        ? _onContinuePressed
                                        : null,
                                    isLoading: widget.isLoading,
                                    backgroundColor: canContinue
                                        ? AppColors.primary
                                        : AuthMobileStep._continueDisabledFill,
                                    labelColor: canContinue
                                        ? Colors.white
                                        : AuthMobileStep._continueDisabledLabel,
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
                SizedBox(height: f(overlay ? 15 : 18)),
                _buildTerms(k),
                SizedBox(height: termsBottomGap),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTerms(double k) {
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
            color: AuthMobileStep._ink,
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
                color: AuthMobileStep._ink,
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

/// Figma eRupaiya wordmark - flush left (keyboard open / closed).
class _LoginBrandWordmark extends StatelessWidget {
  const _LoginBrandWordmark({
    required this.width,
    required this.height,
  });

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    // Cap by MediaQuery width so short phones never overflow side gutters.
    final maxContent = MediaQuery.sizeOf(context).width * 0.7;
    final w = width > maxContent ? maxContent : width;
    final h = height * (w / width);
    return Align(
      alignment: Alignment.centerLeft,
      child: SvgPicture.asset(
        FileConstants.erupaiyaLogoWordmarkSvg,
        key: const ValueKey('login-erupaiya-wordmark'),
        width: w,
        height: h,
        fit: BoxFit.contain,
        alignment: Alignment.centerLeft,
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
    this.readOnly = false,
    this.onEmptyFieldTap,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final bool enabled;
  final bool readOnly;
  final VoidCallback? onEmptyFieldTap;
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
              readOnly: readOnly,
              onTap: () {
                if (readOnly || controller.text.trim().isNotEmpty) return;
                onEmptyFieldTap?.call();
              },
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