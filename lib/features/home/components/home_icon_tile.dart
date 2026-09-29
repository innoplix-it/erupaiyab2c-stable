// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/file_constants.dart';
import '../../../widgets/app_network_image.dart';

class HomeServiceCircle extends StatelessWidget {
  const HomeServiceCircle({
    super.key,
    required this.child,
    this.fillColors,
  });

  final Widget child;

  /// Radial gradient (centre → edge) for metal-themed circles; defaults to
  /// the standard #FFFFFF → #EEF3FD fill.
  final List<Color>? fillColors;

  static const goldFill = [Color(0xFFFFFFFF), Color(0xFFFFF7D5)];
  static const silverFill = [Color(0xFFFFFFFF), Color(0xFFF4F4F4)];

  static const defaultFill = [Color(0xFFFFFFFF), Color(0xFFEEF3FD)];

  /// Figma sizes are drawn on a 440px frame while ScreenUtil's design size is
  /// 360, so Figma px are converted before applying `.w`; this keeps a 68px
  /// Figma circle exactly 68px on the Figma device and proportional elsewhere.
  static double _figma(double px) => (px * 360 / 440).w;

  static double get size => _figma(68);

  static double get contentPadding => _figma(10);

  static double get borderWidth => _figma(2);

  static BoxDecoration themedDecoration(List<Color> colors) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(80.r),
      border: Border.all(
        color: const Color(0xFFFFFFFF),
        width: borderWidth,
        strokeAlign: BorderSide.strokeAlignOutside,
      ),
      gradient: RadialGradient(
        center: Alignment.center,
        radius: 0.7868,
        colors: colors,
        stops: const [0.0, 1.0],
      ),
      boxShadow: [
        BoxShadow(
          color: const Color(0xD9EEF3FD),
          offset: Offset(0.w, 1.h),
          blurRadius: 1.r,
        ),
        BoxShadow(
          color: const Color(0x80EEF3FD),
          offset: Offset(0.w, 2.h),
          blurRadius: 1.r,
        ),
        BoxShadow(
          color: const Color(0x26EEF3FD),
          offset: Offset(0.w, 3.h),
          blurRadius: 1.r,
        ),
        BoxShadow(
          color: const Color(0x05EEF3FD),
          offset: Offset(0.w, 5.h),
          blurRadius: 1.r,
        ),
      ],
    );
  }

  static BoxDecoration decoration() => themedDecoration(defaultFill);

  @override
  Widget build(BuildContext context) {
    final circleSize = size;
    return Container(
      width: circleSize,
      height: circleSize,
      padding: EdgeInsets.all(contentPadding),
      decoration: themedDecoration(fillColors ?? defaultFill),
      child: Center(child: child),
    );
  }
}

/// Figma 34px icon inside the 68px circle: always half the circle so it stays
/// centred and proportional on every screen.
double homeServiceIconSize() => HomeServiceCircle.size * 34 / 68;

/// Shared metrics for every circle + label service item on Home, so all
/// sections keep the same icon → text rhythm.
abstract final class HomeServiceItemMetrics {
  static const double labelLineHeight = 1.25;
  static const int labelMaxLines = 2;
  static const _labelHeightBehavior = TextHeightBehavior(
    leadingDistribution: TextLeadingDistribution.even,
  );
}

TextStyle homeServiceCardLabelStyle() {
  return GoogleFonts.plusJakartaSans(
    fontSize: 11.sp,
    fontWeight: FontWeight.w600,
    fontStyle: FontStyle.normal,
    height: HomeServiceItemMetrics.labelLineHeight,
    letterSpacing: 0,
    color: const Color(0xFF000000),
  );
}

/// Space between the bottom of a service circle and its label; slightly
/// tighter on narrow phones.
double homeServiceCardLabelGap(BuildContext context) {
  final isNarrow = MediaQuery.sizeOf(context).width < 360;
  return (isNarrow ? 3.h : 4.h).clamp(2.0, 6.0);
}

/// Fixed two-line label box so 1- and 2-line labels start at the same
/// position and every item in a row has the same height.
double homeServiceCardLabelBoxHeight(BuildContext context) {
  final style = homeServiceCardLabelStyle();
  final lineExtent = MediaQuery.textScalerOf(context).scale(
    (style.fontSize ?? 11) * (style.height ?? 1),
  );
  return lineExtent * HomeServiceItemMetrics.labelMaxLines + 1;
}

/// Centered label under a service circle (gap included).
class HomeServiceLabel extends StatelessWidget {
  const HomeServiceLabel(this.text, {super.key, this.maxLines = 2});

  final String text;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: homeServiceCardLabelGap(context)),
        SizedBox(
          width: double.infinity,
          height: homeServiceCardLabelBoxHeight(context),
          child: Text(
            text,
            maxLines: maxLines,
            softWrap: maxLines > 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            textHeightBehavior: HomeServiceItemMetrics._labelHeightBehavior,
            style: homeServiceCardLabelStyle(),
          ),
        ),
      ],
    );
  }
}

/// Reusable circle icon + label used by every Home service section.
class HomeServiceItem extends StatelessWidget {
  const HomeServiceItem({
    super.key,
    required this.icon,
    required this.label,
    this.fillColors,
    this.maxLines = 2,
  });

  final Widget icon;
  final String label;
  final List<Color>? fillColors;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        HomeServiceCircle(fillColors: fillColors, child: icon),
        HomeServiceLabel(label, maxLines: maxLines),
      ],
    );
  }
}

TextStyle homeSectionHeaderStyle() {
  return GoogleFonts.plusJakartaSans(
    fontSize: 12.sp,
    fontWeight: FontWeight.w700,
    fontStyle: FontStyle.normal,
    height: 1.2,
    letterSpacing: -0.02 * 12.sp,
    color: const Color(0xFF000000),
  );
}

String homeServiceCardLabelText(String input) {
  return input.split('\n').map((line) {
    return line
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .map((word) {
      if (word.isEmpty) return word;
      return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
    }).join(' ');
  }).join('\n');
}

class HomeIconTile extends StatefulWidget {
  const HomeIconTile({
    super.key,
    required this.label,
    this.onTap,
    this.iconSize = 28,
    this.iconUrl,
    this.lottieAsset,
    this.offer,
    this.showHalfRing = false,
    this.isLoading = false,
    this.creditCardCircle = false,
  });

  final String label;
  final VoidCallback? onTap;
  final double iconSize;
  final String? iconUrl;
  final String? lottieAsset;
  final int? offer;
  final bool showHalfRing;
  final bool isLoading;
  final bool creditCardCircle;

  @override
  State<HomeIconTile> createState() => _HomeIconTileState();
}

class _HomeIconTileState extends State<HomeIconTile> {
  /// Ellipse-orbit-with-sparkles.json: 96x96 canvas whose orbit is a 68px
  /// circle centred at (47.741, 47.741).
  static const double _orbitCanvas = 96;
  static const double _orbitCircle = 68;
  static const double _orbitCenter = 47.741;

  @override
  Widget build(BuildContext context) {
    final labelWords = homeServiceCardLabelText(widget.label)
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
    final isTwoWordLabel = labelWords.length == 2;

    final circleSize = HomeServiceCircle.size;
    final ringSize = circleSize + 2 * HomeServiceCircle.borderWidth;
    final orbitScale = circleSize / _orbitCircle;
    final iconSize = homeServiceIconSize();
    return RepaintBoundary(
      child: InkWell(
        borderRadius: BorderRadius.circular(12.r),
        onTap: widget.isLoading ? null : widget.onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                if (widget.showHalfRing) SizedBox.square(dimension: ringSize),
                HomeServiceCircle(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: widget.isLoading
                        ? SizedBox(
                            key: const ValueKey('loading'),
                            height: 24.r,
                            width: 24.r,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primary,
                              ),
                            ),
                          )
                        : widget.lottieAsset != null
                            ? Lottie.asset(
                                widget.lottieAsset!,
                                key: const ValueKey('lottie-icon'),
                                width: iconSize,
                                height: iconSize,
                                fit: BoxFit.contain,
                              )
                            : AppNetworkImage(
                                key: const ValueKey('icon'),
                                url: widget.iconUrl,
                                width: iconSize,
                                height: iconSize,
                                fit: BoxFit.contain,
                                showShimmer: false,
                                errorWidget: Image.asset(
                                  FileConstants.appLogo,
                                  height: iconSize,
                                  width: iconSize,
                                  fit: BoxFit.contain,
                                ),
                              ),
                  ),
                ),
                if (widget.showHalfRing)
                  Positioned(
                    left: ringSize / 2 - _orbitCenter * orbitScale,
                    top: ringSize / 2 - _orbitCenter * orbitScale,
                    width: _orbitCanvas * orbitScale,
                    height: _orbitCanvas * orbitScale,
                    child: IgnorePointer(
                      child: RepaintBoundary(
                        child: Lottie.asset(
                          FileConstants.bookGasOrbitLottie,
                          fit: BoxFit.contain,
                          repeat: true,
                        ),
                      ),
                    ),
                  ),
                if (!widget.isLoading && widget.offer != null)
                  Positioned(
                    top: -circleSize * 10 / 68,
                    right: circleSize * 13.5 / 68,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 5.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Text(
                        '₹${widget.offer}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            HomeServiceLabel(
              isTwoWordLabel
                  ? '${labelWords.first}\n${labelWords.last}'
                  : labelWords.join(' '),
            ),
          ],
        ),
      ),
    );
  }
}