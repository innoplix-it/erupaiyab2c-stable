// ignore_for_file: deprecated_member_use

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/file_constants.dart';
import '../../../widgets/custom_elevated_button.dart';
import 'login_services_slider.dart';

/// Plus Jakarta Sans is the app-wide theme font, but every raw [TextStyle] in
/// the auth steps pins the family explicitly so they stay correct when
/// rendered outside the app theme (widget tests, previews).
const String authFontFamily = 'Plus Jakarta Sans';

/// What the login/PIN chrome needs from the keyboard slot.
///
/// [overlay] is the lifted layout (keyboard, focus, short body, or loading).
/// [available] is the body height under the status-bar pad, after any held
/// keyboard gap. Both stay constant while the keyboard inset is only moving,
/// so the form widgets are not rebuilt on those frames.
class AuthKeyboardFrame {
  const AuthKeyboardFrame({
    required this.overlay,
    required this.available,
    required this.topPad,
    required this.bottomSafe,
  });

  final bool overlay;
  final double available;
  final double topPad;
  final double bottomSafe;
}

/// Lays out the auth background and form against the real body height.
///
/// Scaffold shrinks the body while the keyboard opens. This slot reads that
/// height here, so the parent does not subscribe to inset or padding changes.
/// The slider and form widget instances are reused until [overlay] or the
/// closed-layout height actually changes. Keyboard frames only move padding.
class AuthKeyboardSlot extends StatefulWidget {
  const AuthKeyboardSlot({
    super.key,
    required this.screenHeight,
    required this.topExtra,
    required this.frozen,
    required this.heldGap,
    required this.lifted,
    required this.onGap,
    required this.onOpened,
    required this.onDismiss,
    required this.buildSlider,
    required this.buildForm,
  });

  final double screenHeight;

  /// Added under the status-bar inset (Figma top pad).
  final double topExtra;
  final bool frozen;
  final double heldGap;

  /// Lift requested by focus, loading, or a keyboard the parent already saw.
  /// A shrinking body also lifts, without waiting for this flag.
  final bool lifted;
  final ValueChanged<double> onGap;
  final VoidCallback onOpened;
  final VoidCallback onDismiss;
  final Widget Function(AuthKeyboardFrame frame) buildSlider;
  final Widget Function(AuthKeyboardFrame frame) buildForm;

  @override
  State<AuthKeyboardSlot> createState() => _AuthKeyboardSlotState();
}

class _AuthKeyboardSlotState extends State<AuthKeyboardSlot> {
  bool _gapOpen = false;
  int? _cacheKey;
  Widget? _slider;
  Widget? _form;

  @override
  void didUpdateWidget(covariant AuthKeyboardSlot oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Parent state changed (focus, loading, dismiss). Rebuild the chrome
    // once; pure keyboard-inset frames never reach this method.
    _cacheKey = null;
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    return LayoutBuilder(
      builder: (context, viewport) {
        final keyboardGap =
            math.max(0.0, widget.screenHeight - viewport.maxHeight);
        var gap = widget.heldGap;
        final gapOpen =
            keyboardGap > 0 && keyboardGap < widget.screenHeight * 0.6;
        if (gapOpen) {
          gap = math.max(gap, keyboardGap);
          if (gap != widget.heldGap) widget.onGap(gap);
        }
        if (gapOpen != _gapOpen) {
          _gapOpen = gapOpen;
          if (gapOpen && !widget.lifted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) widget.onOpened();
            });
          }
        }
        final rawHold = widget.frozen ? math.max(0.0, gap - keyboardGap) : 0.0;
        final maxHold = math.max(0.0, viewport.maxHeight - 320);
        final holdInset = math.min(rawHold, maxHold);
        final topPad = padding.top + widget.topExtra;
        final bodyHeight = math.max(0.0, viewport.maxHeight - holdInset);
        final available = math.max(0.0, bodyHeight - topPad);
        final shortViewport = available < 420;
        final overlay = widget.lifted || shortViewport || gapOpen;
        // Closed layout sizes the slider from the body. Lifted layout does
        // not, so intermediate keyboard heights must not rebuild it.
        final key = Object.hash(overlay, overlay ? 0 : available.round());
        if (_cacheKey != key || _slider == null || _form == null) {
          final frame = AuthKeyboardFrame(
            overlay: overlay,
            available: available,
            topPad: topPad,
            bottomSafe: padding.bottom,
          );
          _cacheKey = key;
          _slider = widget.buildSlider(frame);
          _form = widget.buildForm(frame);
        }
        return SizedBox.expand(
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: AppColors.loginPeachCoralGradient,
            ),
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: widget.onDismiss,
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
                      child: _slider!,
                    ),
                    Positioned.fill(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: holdInset),
                        child: RepaintBoundary(child: _form!),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

void showAuthKeyboard(FocusNode node) {
  node.requestFocus();
  SystemChannels.textInput.invokeMethod<void>('TextInput.show');
}

/// Keeps the keyboard up for a code field ([child] owns [focusNode]).
///
/// With [autofocus] the keyboard opens when the screen appears. Disabling
/// the field (while an OTP is sent, resent or verified) drops its focus and
/// closes the keyboard, so on re-enable the field takes focus back if it had
/// it, or if it is the autofocus field and nothing else is focused.
class AuthKeyboardOnOpen extends StatefulWidget {
  const AuthKeyboardOnOpen({
    super.key,
    required this.child,
    this.focusNode,
    this.autofocus = true,
    this.enabled = true,
  });

  final Widget child;
  final FocusNode? focusNode;
  final bool autofocus;
  final bool enabled;

  @override
  State<AuthKeyboardOnOpen> createState() => _AuthKeyboardOnOpenState();
}

class _AuthKeyboardOnOpenState extends State<AuthKeyboardOnOpen> {
  /// Fields that were focused when disabled; they win over the autofocus
  /// field when everything is re-enabled together.
  static final Set<_AuthKeyboardOnOpenState> _focusedWhenDisabled = {};

  @override
  void initState() {
    super.initState();
    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openKeyboard());
    }
  }

  @override
  void didUpdateWidget(AuthKeyboardOnOpen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled && !widget.enabled) {
      if (widget.focusNode?.hasFocus ?? false) _focusedWhenDisabled.add(this);
    } else if (!oldWidget.enabled && widget.enabled) {
      final hadFocus = _focusedWhenDisabled.contains(this);
      if (hadFocus || widget.autofocus) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _focusedWhenDisabled.remove(this);
          if (hadFocus || _focusedWhenDisabled.isEmpty) _openKeyboard();
        });
      }
    }
  }

  @override
  void dispose() {
    _focusedWhenDisabled.remove(this);
    super.dispose();
  }

  void _openKeyboard() {
    if (!mounted || !widget.enabled) return;
    if (!(ModalRoute.of(context)?.isCurrent ?? true)) return;
    final primary = FocusManager.instance.primaryFocus;
    final focused = primary?.context;
    final ownsFocus = focused != null &&
        focused.findAncestorStateOfType<_AuthKeyboardOnOpenState>() == this;
    if (ownsFocus) {
      SystemChannels.textInput.invokeMethod<void>('TextInput.show');
      return;
    }
    final node = widget.focusNode;
    final nothingFocused = primary == null || primary is FocusScopeNode;
    if (node != null && nothingFocused) showAuthKeyboard(node);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Zinc-400 disabled fill from the Figma spec. Deliberately local to the auth
/// steps: it must not leak into the global palette.
const Color authDisabledFill = Color(0xFFA1A1AA);

/// Light-grey disabled Continue (matches the Figma login / Verify OTP frames).
const Color authContinueDisabledFill = Color(0xFFE3E3E6);
const Color authContinueDisabledLabel = Color(0xFF64646B);

const Color _hintColor = Color(0xFFA1A1AA);
const Color _fieldDivider = Color(0xFFE4E4E7);

/// Figma auth frames are authored on 360 x 690.
const double _designWidth = 360;
const double _designHeight = 690;

/// Width based MediaQuery sizing: [designPx] / 360 of the screen width,
/// bounded so tiny phones and tablets stay usable. Already in logical pixels:
/// never pass the result through ScreenUtil again.
double authW(BuildContext context, double designPx) {
  final value = MediaQuery.sizeOf(context).width * designPx / _designWidth;
  return value.clamp(designPx * 0.78, designPx * 1.3).toDouble();
}

/// Height based MediaQuery sizing: [designPx] / 690 of the window height.
/// [MediaQuery.sizeOf] is NOT reduced by the keyboard, so vertical gaps stay
/// constant while the keyboard opens/closes (no jumping content).
double authH(BuildContext context, double designPx) {
  final value = MediaQuery.sizeOf(context).height * designPx / _designHeight;
  return value.clamp(designPx * 0.7, designPx * 1.3).toDouble();
}

/// Side gutter (14 / 360) as a MediaQuery value.
double authSidePadding(BuildContext context) => authW(context, 14);

/// Kept for call sites not migrated yet (identity OTP, Create MPIN, ...).
/// New code should use [authSidePadding].
double get authHorizontalPadding => 14.w;

/// MediaQuery sizing for auth layout boxes: [fraction] of the screen width
/// (Figma px / 360), bounded so controls stay usable on 280dp phones and do
/// not balloon on tablets. The result is already in logical pixels and must
/// not be passed through ScreenUtil again.
double authWidthFraction(
  BuildContext context,
  double fraction, {
  required double min,
  required double max,
}) {
  return (MediaQuery.sizeOf(context).width * fraction)
      .clamp(min, max)
      .toDouble();
}

/// Fixed-height auth CTA; [fraction] defaults to the 48px Figma button.
double authButtonHeight(BuildContext context, {double fraction = 48 / 360}) =>
    authWidthFraction(context, fraction, min: 40, max: 56);

/// Full width on phones; on tablets the form column takes 60% of the screen
/// so fields and CTAs stay readable.
double authContentMaxWidth(BuildContext context) {
  final screenWidth = MediaQuery.sizeOf(context).width;
  return screenWidth > 600 ? screenWidth * 0.6 : double.infinity;
}

const double authBackgroundOpacity = 0.4;

/// Auth artwork, faded so it stays behind the form content.
class AuthBackgroundImage extends StatelessWidget {
  const AuthBackgroundImage({super.key});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      FileConstants.authBackground,
      fit: BoxFit.cover,
      alignment: Alignment.topCenter,
      opacity: const AlwaysStoppedAnimation(authBackgroundOpacity),
    );
  }
}

/// Background sized to the FULL window (not the keyboard-reduced body), so the
/// artwork is not re-laid-out / re-scaled on every keyboard animation frame.
/// Use as a direct child of a [Stack]; the Stack clips the part that sits
/// behind the keyboard.
Widget authFixedBackground(BuildContext context) {
  return Positioned(
    top: 0,
    left: 0,
    right: 0,
    height: MediaQuery.sizeOf(context).height,
    child: const RepaintBoundary(child: AuthBackgroundImage()),
  );
}

/// Plain white shell for Verify OTP, Create MPIN, and Reset MPIN (no marquee).
class AuthPlainWhiteShell extends StatelessWidget {
  const AuthPlainWhiteShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(color: Colors.white, child: child);
  }
}

/// Peach band + animated [LoginServicesSlider] behind OTP / MPIN form content
/// (legacy; login PIN uses the same shell as [AuthMobileStep]).
///
/// The slider height is derived from the full window height, never from the
/// keyboard-reduced body, so opening the keyboard does not resize / rebuild
/// the tiles on every frame.
class AuthPeachMarqueeShell extends StatelessWidget {
  const AuthPeachMarqueeShell({super.key, required this.child});

  final Widget child;

  /// Soft wash so the marquee stays visible behind titles (Figma OTP/PIN).
  static const LinearGradient _overlayBandGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0x59FFFFFF),
      Color(0xD9FFFFFF),
      Color(0xFFFFFFFF),
    ],
    stops: [0.0, 0.38, 1.0],
  );

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final topInset = MediaQuery.paddingOf(context).top;
    final k = (size.width / LoginServicesSlider.figmaFrameWidth)
        .clamp(0.72, 1.1)
        .toDouble();
    final topPad = topInset + 6 * k;
    final available = math.max(0.0, size.height - topPad);
    final natural = LoginServicesSlider.naturalHeight(
      size.width,
      2,
      compact: true,
    );
    final sliderH = math.min(natural, available * 0.72);

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: AppColors.loginPeachCoralGradient,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: topPad,
            left: 0,
            right: 0,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: sliderH, minHeight: 0),
              child: const LoginServicesSlider(rowCount: 2, compact: true),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(gradient: _overlayBandGradient),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

class AuthStepLayout extends StatelessWidget {
  const AuthStepLayout({
    super.key,
    required this.children,
    required this.footer,
  });

  final List<Widget> children;
  final Widget footer;

  @override
  Widget build(BuildContext context) {
    final side = authSidePadding(context);
    // Window based (not keyboard based) so the content does not shift when
    // the keyboard opens.
    final topGap =
        (MediaQuery.sizeOf(context).height * 0.07).clamp(12.0, 56.0).toDouble();
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Colors.white),
        authFixedBackground(context),
        SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(side, topGap, side, 0),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: authContentMaxWidth(context),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...children,
                          // Keeps the last control clear of the pinned
                          // footer button.
                          SizedBox(height: authH(context, 24)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  side,
                  authH(context, 8),
                  side,
                  authH(context, 16),
                ),
                child: footer,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Brand mark + wordmark, using the client's eRupaiya monogram.
class AuthBrandRow extends StatelessWidget {
  const AuthBrandRow({super.key});

  @override
  Widget build(BuildContext context) {
    final logo = authW(context, 24);
    return Row(
      children: [
        Image.asset(
          FileConstants.erupaiyaLogo,
          width: logo,
          height: logo,
        ),
        SizedBox(width: authW(context, 6)),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            // TM is its own widget beside the wordmark, so it can never
            // overlap the final 'a'.
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'eRupaiya',
                  style: TextStyle(
                    fontFamily: authFontFamily,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                    height: 1.2,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(width: 1),
                Text(
                  'TM',
                  style: TextStyle(
                    fontFamily: authFontFamily,
                    fontSize: 6.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                    height: 1,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class AuthWelcomeHeading extends StatelessWidget {
  const AuthWelcomeHeading({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome to eRupaiya',
          style: TextStyle(
            fontFamily: authFontFamily,
            fontSize: 18.sp,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
            height: 1.3,
            letterSpacing: 0,
          ),
        ),
        SizedBox(height: authH(context, 4)),
        Text(
          'Enter your mobile number to continue.',
          style: TextStyle(
            fontFamily: authFontFamily,
            fontSize: 12.sp,
            fontWeight: FontWeight.w400,
            fontStyle: FontStyle.italic,
            color: AppColors.textPrimary.withOpacity(0.6),
            height: 1.4,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class AuthFieldLabel extends StatelessWidget {
  const AuthFieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: authFontFamily,
        fontSize: 12.sp,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
        height: 1.2,
        letterSpacing: 0,
      ),
    );
  }
}

/// +91 mobile number field. With [enabled] false it shows the number
/// read-only, and [onTap] lets the caller offer a way back to editing it.
class AuthMobileField extends StatelessWidget {
  const AuthMobileField({
    super.key,
    required this.controller,
    this.enabled = true,
    this.autofocus = false,
    this.focusNode,
    this.onTap,
  });

  static const int mobileLength = 10;

  final TextEditingController controller;
  final bool enabled;
  final bool autofocus;
  final FocusNode? focusNode;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final field = Container(
      height: authWidthFraction(context, 46 / 360, min: 40, max: 64),
      padding: EdgeInsets.symmetric(horizontal: authW(context, 16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18.r,
            offset: Offset(0, 8.r),
          ),
        ],
      ),
      child: Row(
        children: [
          Image.asset(
            FileConstants.indiaFlag,
            width: authW(context, 22),
            height: authW(context, 15),
          ),
          SizedBox(width: authW(context, 8)),
          Text(
            '+91',
            style: TextStyle(
              fontFamily: authFontFamily,
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              height: 1.2,
              letterSpacing: 0,
            ),
          ),
          SizedBox(width: authW(context, 10)),
          Container(width: 1, height: authW(context, 18), color: _fieldDivider),
          SizedBox(width: authW(context, 10)),
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled,
              autofocus: autofocus,
              focusNode: focusNode,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              // Digits only, hard-capped at 10 after the +91 prefix.
              maxLength: mobileLength,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(mobileLength),
              ],
              style: TextStyle(
                fontFamily: authFontFamily,
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
                height: 1.2,
                letterSpacing: 0,
              ),
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: 'enter 10 digit mobile number',
                hintStyle: TextStyle(
                  fontFamily: authFontFamily,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w400,
                  color: _hintColor,
                  height: 1.2,
                  letterSpacing: 0,
                ),
                counterText: '',
              ),
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return field;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: field,
    );
  }
}

/// Makes the [CustomElevatedButton]s under it paint edge to edge with no
/// rim. By default Material draws the button 7px shorter than its 48px tap
/// area and tints it grey when disabled or loading, leaving a light band
/// around the pill that reads as a border.
class AuthButtonTheme extends StatelessWidget {
  const AuthButtonTheme({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = ElevatedButton.styleFrom(
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      minimumSize: const Size(64, kMinInteractiveDimension),
      disabledBackgroundColor: Colors.transparent,
      disabledForegroundColor: Colors.white,
      side: BorderSide.none,
    ).merge(theme.elevatedButtonTheme.style);
    return Theme(
      data: theme.copyWith(
        elevatedButtonTheme: ElevatedButtonThemeData(style: style),
      ),
      child: child,
    );
  }
}

/// Full-pill primary CTA shared by the auth steps.
class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.enabled,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final bool enabled;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return AuthButtonTheme(
      child: CustomElevatedButton(
        onPressed: enabled ? onPressed : null,
        label: label,
        uppercaseLabel: false,
        isLoading: isLoading,
        // No fixed height, so the label never clips at large text scales; the
        // 28.r radius still rounds the 48dp Material height into a full pill.
        backgroundColor: enabled ? AppColors.primary : authContinueDisabledFill,
        labelColor: enabled ? Colors.white : authContinueDisabledLabel,
        labelStyle: TextStyle(
          fontFamily: authFontFamily,
          fontSize: 12.sp,
          fontWeight: FontWeight.w500,
          color: enabled ? Colors.white : authContinueDisabledLabel,
          height: 1,
          letterSpacing: 0,
        ),
      ),
    );
  }
}
