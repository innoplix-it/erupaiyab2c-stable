import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pinput/pinput.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/file_constants.dart';
import 'auth_feedback.dart';
import 'auth_step_parts.dart';

const Color authInk = Color(0xFF09090B);
const Color authMuted = Color(0xFF71717A);
const Color _otpBorder = Color(0xFFECECEC);
const Color _otpFilledBorder = Color(0xFFA1A1AA);

/// #D1D1D1 at the per-layer opacities of the Figma drop-shadow stack.
const Color _pinShadowTint = Color(0xFFD1D1D1);

/// Plus Jakarta Sans style carrying every text property explicitly, so auth
/// screens never inherit gaps from the ambient theme.
TextStyle authTextStyle({
  required double fontSize,
  required FontWeight fontWeight,
  Color color = authInk,
  double height = 1.2,
  FontStyle fontStyle = FontStyle.normal,
  TextDecoration decoration = TextDecoration.none,
}) {
  return TextStyle(
    fontFamily: authFontFamily,
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

/// Width each box gets when [length] boxes share [maxWidth], capped at the
/// Figma size so they stop growing on wide screens.
double _boxWidth(double maxWidth, int length, double gap, double cap) {
  final width = (maxWidth - gap * (length - 1)) / length;
  return width.clamp(0.0, cap).toDouble();
}

/// Grey OTP boxes (white card, #ECECEC border, soft shadow). Typed boxes get
/// a dark border; once every digit is in, the whole row turns brand orange.
class AuthOtpBoxes extends StatelessWidget {
  const AuthOtpBoxes({
    super.key,
    required this.controller,
    required this.length,
    this.focusNode,
    this.autofocus = false,
    this.enabled = true,
    this.hasError = false,
    this.onChanged,
    this.onCompleted,
    this.shakeController,
  });

  final TextEditingController controller;
  final int length;
  final FocusNode? focusNode;
  final bool autofocus;
  final bool enabled;
  final bool hasError;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onCompleted;

  /// Jiggles the boxes after a failed OTP check.
  final AuthShakeController? shakeController;

  @override
  Widget build(BuildContext context) {
    final boxes = LayoutBuilder(
      builder: (context, constraints) {
        final gap = 10.w;
        final width = _boxWidth(
          constraints.maxWidth,
          length,
          gap,
          authWidthFraction(context, 58 / 360, min: 44, max: 86),
        );
        final height = authWidthFraction(context, 47 / 360, min: 36, max: 70);

        PinTheme theme(Color borderColor) => PinTheme(
              width: width,
              height: height,
              textStyle: authTextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12.r,
                    offset: Offset(0, 4.h),
                  ),
                ],
              ),
            );

        return ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            final complete = controller.text.length == length;
            final boxes = Pinput(
              controller: controller,
              focusNode: focusNode,
              length: length,
              autofocus: autofocus,
              enabled: enabled,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              mainAxisAlignment: MainAxisAlignment.start,
              separatorBuilder: (_) => SizedBox(width: gap),
              forceErrorState: hasError,
              onChanged: onChanged,
              onCompleted: onCompleted,
              defaultPinTheme: theme(_otpBorder),
              focusedPinTheme: theme(authMuted),
              submittedPinTheme:
                  theme(complete ? AppColors.primary : _otpFilledBorder),
              disabledPinTheme:
                  theme(complete ? AppColors.primary : _otpBorder),
              errorPinTheme: theme(Colors.red),
            );
            return AuthKeyboardOnOpen(
              focusNode: focusNode,
              autofocus: autofocus,
              enabled: enabled,
              child: boxes,
            );
          },
        );
      },
    );
    final shake = shakeController;
    return shake == null ? boxes : AuthShake(controller: shake, child: boxes);
  }
}

/// Orange-bordered PIN boxes from the Figma card SVG (white, 12 radius,
/// #DD5428 stroke, four-layer drop shadow), masked with `*`.
class AuthPinBoxes extends StatelessWidget {
  const AuthPinBoxes({
    super.key,
    required this.controller,
    this.focusNode,
    this.length = 4,
    this.obscure = true,
    this.autofocus = false,
    this.enabled = true,
    this.hasError = false,
    this.boxHeight,
    this.maxBoxWidth,
    this.gap,
    this.onChanged,
    this.onCompleted,
    this.shakeController,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final int length;
  final bool obscure;
  final bool autofocus;
  final bool enabled;
  final bool hasError;

  /// Defaults to the 48px Figma box height.
  final double? boxHeight;

  /// Widest a box may grow; defaults to the 93px Figma card.
  final double? maxBoxWidth;

  /// Space between boxes; defaults to 10px.
  final double? gap;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onCompleted;

  /// Jiggles the boxes after a failed PIN check.
  final AuthShakeController? shakeController;

  @override
  Widget build(BuildContext context) {
    final boxes = LayoutBuilder(
      builder: (context, constraints) {
        final gap = this.gap ?? 10.w;
        final width = _boxWidth(
          constraints.maxWidth,
          length,
          gap,
          maxBoxWidth ??
              authWidthFraction(context, 93 / 360, min: 64, max: 140),
        );
        final height =
            boxHeight ?? authWidthFraction(context, 48 / 360, min: 36, max: 72);

        PinTheme theme({Color? borderColor, double borderWidth = 1}) =>
            PinTheme(
              width: width,
              height: height,
              textStyle: authTextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: borderColor ?? AppColors.primary,
                  width: borderWidth,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _pinShadowTint.withValues(alpha: 0.10),
                    blurRadius: 25.r,
                    offset: Offset(0, 11.h),
                  ),
                  BoxShadow(
                    color: _pinShadowTint.withValues(alpha: 0.09),
                    blurRadius: 45.r,
                    offset: Offset(0, 45.h),
                  ),
                  BoxShadow(
                    color: _pinShadowTint.withValues(alpha: 0.05),
                    blurRadius: 61.r,
                    offset: Offset(0, 101.h),
                  ),
                  BoxShadow(
                    color: _pinShadowTint.withValues(alpha: 0.01),
                    blurRadius: 72.r,
                    offset: Offset(0, 180.h),
                  ),
                ],
              ),
            );

        final boxes = Pinput(
          controller: controller,
          focusNode: focusNode,
          length: length,
          autofocus: autofocus,
          enabled: enabled,
          obscureText: obscure,
          obscuringCharacter: '*',
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          mainAxisAlignment: MainAxisAlignment.start,
          separatorBuilder: (_) => SizedBox(width: gap),
          forceErrorState: hasError,
          onChanged: onChanged,
          onCompleted: onCompleted,
          defaultPinTheme: theme(),
          focusedPinTheme: theme(borderWidth: 1.5),
          disabledPinTheme: theme(),
          errorPinTheme: theme(borderColor: Colors.red),
        );
        return AuthKeyboardOnOpen(
          focusNode: focusNode,
          autofocus: autofocus,
          enabled: enabled,
          child: boxes,
        );
      },
    );
    final shake = shakeController;
    return shake == null ? boxes : AuthShake(controller: shake, child: boxes);
  }
}

/// Largest system text scale the compact action rows (timer/Resend,
/// Show/Forget PIN) follow; beyond this they would crowd the PIN boxes.
const double _actionRowMaxTextScale = 1.3;

/// Keeps an action row's icons in proportion with its (clamped) text when the
/// user raises the system font size.
double _actionIconScale(BuildContext context) {
  final scale = MediaQuery.textScalerOf(context).scale(12) / 12;
  return scale.clamp(1.0, _actionRowMaxTextScale).toDouble();
}

/// Eye icon + Show/Hide label: 12px text, 4px gap (Figma action row).
class AuthVisibilityToggle extends StatelessWidget {
  const AuthVisibilityToggle({
    super.key,
    required this.obscure,
    required this.onTap,
  });

  final bool obscure;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: _actionRowMaxTextScale,
      child: Builder(
        builder: (context) => InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8.r),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 2.w),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 17.r * _actionIconScale(context),
                  color: authInk,
                ),
                SizedBox(width: 4.w),
                Flexible(
                  child: Text(
                    obscure ? 'Show' : 'Hide',
                    overflow: TextOverflow.ellipsis,
                    style: authTextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      height: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Red message centred between the two ends of a row under the code boxes
/// (wrong PIN / wrong OTP).
class AuthCodeRowError extends StatelessWidget {
  const AuthCodeRowError(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 6.w),
      child: Text(
        text,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: authTextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.red,
          height: 1.2,
        ),
      ),
    );
  }
}

/// Show/Hide on the left, underlined Forget PIN on the right, and
/// [errorText] (if any) in the middle.
class AuthPinActionsRow extends StatelessWidget {
  const AuthPinActionsRow({
    super.key,
    required this.obscure,
    required this.onToggle,
    required this.onForgotPin,
    this.errorText,
  });

  final bool obscure;
  final VoidCallback onToggle;

  /// Null disables Forget PIN (e.g. while a request is running).
  final VoidCallback? onForgotPin;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final error = errorText;
    final forgotPin = MediaQuery.withClampedTextScaling(
      maxScaleFactor: _actionRowMaxTextScale,
      child: InkWell(
        onTap: onForgotPin,
        borderRadius: BorderRadius.circular(8.r),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 2.w),
          child: Text(
            'Forget PIN',
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            style: authTextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 1.2,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ),
    );
    final toggle = AuthVisibilityToggle(obscure: obscure, onTap: onToggle);
    if (error != null && error.isNotEmpty) {
      return Row(
        children: [
          toggle,
          Expanded(
            child: MediaQuery.withClampedTextScaling(
              maxScaleFactor: _actionRowMaxTextScale,
              child: AuthCodeRowError(error),
            ),
          ),
          forgotPin,
        ],
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(child: toggle),
        SizedBox(width: 12.w),
        Flexible(flex: 3, child: forgotPin),
      ],
    );
  }
}

/// Field label used above OTP and PIN rows.
class AuthCodeLabel extends StatelessWidget {
  const AuthCodeLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: authTextStyle(fontSize: 12, fontWeight: FontWeight.w500),
    );
  }
}

/// PIN boxes with the Show/Hide toggle on the right, as in the Figma rows.
class AuthPinRowWithToggle extends StatelessWidget {
  const AuthPinRowWithToggle({
    super.key,
    required this.controller,
    required this.obscure,
    required this.onToggle,
    this.focusNode,
    this.autofocus = false,
    this.enabled = true,
    this.hasError = false,
    this.onChanged,
    this.onCompleted,
  });

  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggle;
  final FocusNode? focusNode;
  final bool autofocus;
  final bool enabled;
  final bool hasError;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onCompleted;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AuthPinBoxes(
            controller: controller,
            focusNode: focusNode,
            obscure: obscure,
            autofocus: autofocus,
            enabled: enabled,
            hasError: hasError,
            maxBoxWidth: authWidthFraction(context, 55 / 360, min: 44, max: 82),
            gap: 11.w,
            onChanged: onChanged,
            onCompleted: onCompleted,
          ),
        ),
        SizedBox(width: 12.w),
        // Same minimum width for Show and Hide keeps stacked rows aligned.
        ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: authWidthFraction(context, 58 / 360, min: 48, max: 80),
          ),
          child: AuthVisibilityToggle(obscure: obscure, onTap: onToggle),
        ),
      ],
    );
  }
}

/// Countdown with the timer icon on the left, Resend on the right and
/// [errorText] (if any) in the middle: 12px text, clock 11.5x13 with a 6px
/// gap, resend icon 18x18.
class AuthOtpTimerRow extends StatelessWidget {
  const AuthOtpTimerRow({
    super.key,
    required this.timerText,
    required this.canResend,
    required this.onResend,
    this.resendLabel = 'Resend',
    this.errorText,
  });

  final String timerText;
  final bool canResend;
  final VoidCallback onResend;
  final String resendLabel;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final resendColor =
        canResend ? authMuted : authMuted.withValues(alpha: 0.4);
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: _actionRowMaxTextScale,
      child: Builder(
        builder: (context) {
          final iconScale = _actionIconScale(context);
          return Row(
            children: [
              SvgPicture.asset(
                FileConstants.otpTimerIcon,
                width: 11.5.r * iconScale,
                height: 13.r * iconScale,
              ),
              SizedBox(width: 6.w),
              Text(
                timerText,
                style: authTextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  height: 1,
                ),
              ),
              if (errorText != null && errorText!.isNotEmpty)
                Expanded(child: AuthCodeRowError(errorText!))
              else ...[
                SizedBox(width: 12.w),
                const Spacer(),
              ],
              Semantics(
                button: true,
                enabled: canResend,
                child: InkWell(
                  onTap: canResend ? onResend : null,
                  borderRadius: BorderRadius.circular(8.r),
                  child: Padding(
                    padding:
                        EdgeInsets.symmetric(vertical: 6.h, horizontal: 2.w),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.asset(
                          FileConstants.otpResendIcon,
                          width: 18.r * iconScale,
                          height: 18.r * iconScale,
                          colorFilter:
                              ColorFilter.mode(resendColor, BlendMode.srcIn),
                        ),
                        SizedBox(width: 2.w),
                        Text(
                          resendLabel,
                          style: authTextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: resendColor,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
