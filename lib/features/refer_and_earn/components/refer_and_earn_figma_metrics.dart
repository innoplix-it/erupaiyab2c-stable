import 'package:flutter/material.dart';

/// Refer & Earn screens (Figma 440×956) sized from [MediaQuery] — no ScreenUtil
/// `.w`/`.h` on top of these values (avoids double scaling).
abstract final class ReferAndEarnFigmaMetrics {
  static const double frameWidth = 440;
  static const double frameHeight = 956;

  static double widthScaleOf(BuildContext context) =>
      (MediaQuery.sizeOf(context).width / frameWidth).clamp(0.72, 1.12);

  static double heightScaleOf(BuildContext context) =>
      (MediaQuery.sizeOf(context).height / frameHeight).clamp(0.72, 1.12);

  /// Horizontal layout & most Figma px (width ratio).
  static double w(BuildContext context, double figmaPx) =>
      figmaPx * widthScaleOf(context);

  /// Vertical spacing & heights (height ratio).
  static double h(BuildContext context, double figmaPx) =>
      figmaPx * heightScaleOf(context);

  static double r(BuildContext context, double figmaPx) => w(context, figmaPx);

  static double sp(BuildContext context, double figmaPx) => w(context, figmaPx);

  /// Parent or screen width fraction, clamped when [min]/[max] are set.
  static double widthFraction(
    BuildContext context,
    double fraction, {
    double min = 0,
    double max = double.infinity,
  }) =>
      (MediaQuery.sizeOf(context).width * fraction).clamp(min, max).toDouble();
}

extension ReferAndEarnLayoutContext on BuildContext {
  double referW(double figmaPx) => ReferAndEarnFigmaMetrics.w(this, figmaPx);

  double referH(double figmaPx) => ReferAndEarnFigmaMetrics.h(this, figmaPx);

  double referR(double figmaPx) => ReferAndEarnFigmaMetrics.r(this, figmaPx);

  double referSp(double figmaPx) => ReferAndEarnFigmaMetrics.sp(this, figmaPx);
}
