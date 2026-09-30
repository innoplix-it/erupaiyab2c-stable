import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Converts Fetch Your Provider values from the 440x956 Figma frame into
/// ScreenUtil units (design size 360x690), so a 440x956 phone renders them at
/// exactly the Figma pixel sizes and other phones scale from there.
abstract final class FetchProviderMetrics {
  static double w(double figmaPx) => (figmaPx * 360 / 440).w;
  static double h(double figmaPx) => (figmaPx * 690 / 956).h;
  static double r(double figmaPx) => (figmaPx * 360 / 440).r;

  /// Figma font size, never above the Figma value nor below [min].
  static double font(double figmaPx, {required double min}) =>
      (figmaPx * 360 / 440).sp.clamp(min, figmaPx).toDouble();
}
