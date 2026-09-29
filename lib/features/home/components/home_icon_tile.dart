// ignore_for_file: deprecated_member_use

import 'dart:math' as math;

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
  });

  final Widget child;

  static double get size {
    final width = ScreenUtil().screenWidth;
    final preferred = 52.w;
    final byWidth = width * (52 / 360);
    final resolved = preferred < byWidth ? preferred : byWidth;
    if (resolved < 40) return 40;
    if (resolved > 56) return 56;
    return resolved;
  }

  static BoxDecoration decoration() {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(80.r),
      border: Border.all(
        color: const Color(0xFFFFFFFF),
        width: 2.w,
      ),
      gradient: const RadialGradient(
        center: Alignment(0, 0),
        radius: 0.7868,
        colors: [
          Color(0xFFFFFFFF),
          Color(0xFFEEF3FD),
        ],
        stops: [0.0, 1.0],
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

  @override
  Widget build(BuildContext context) {
    final circleSize = size;
    return Container(
      width: circleSize,
      height: circleSize,
      padding: EdgeInsets.all((circleSize * 0.14).clamp(6.0, 10.0)),
      decoration: decoration(),
      child: Center(child: child),
    );
  }
}

TextStyle homeServiceCardLabelStyle() {
  return GoogleFonts.plusJakartaSans(
    fontSize: 12.sp,
    fontWeight: FontWeight.w600,
    fontStyle: FontStyle.normal,
    height: 1.2,
    letterSpacing: 0,
    color: const Color(0xFF000000),
  );
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
    this.labelSpacing,
    this.labelHeight,
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
  final double? labelSpacing;
  final double? labelHeight;
  final bool showHalfRing;
  final bool isLoading;
  final bool creditCardCircle;

  @override
  State<HomeIconTile> createState() => _HomeIconTileState();
}

class _HomeIconTileState extends State<HomeIconTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ringController;
  static const _ringDuration = Duration(milliseconds: 1200);

  @override
  void initState() {
    super.initState();
    _ringController = AnimationController(
      vsync: this,
      duration: _ringDuration,
    );
    if (widget.showHalfRing) {
      _ringController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant HomeIconTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.showHalfRing != widget.showHalfRing) {
      if (widget.showHalfRing) {
        _ringController.repeat();
      } else {
        _ringController.stop();
      }
    }
  }

  @override
  void dispose() {
    _ringController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final labelWords = homeServiceCardLabelText(widget.label)
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
    final isTwoWordLabel = labelWords.length == 2;

    final circleSize = HomeServiceCircle.size;
    final ringSize = circleSize + 4.w;
    final iconSize = (circleSize * 0.48).clamp(18.0, 26.0);
    final textScaler = MediaQuery.textScalerOf(context);
    final labelStyle = homeServiceCardLabelStyle();
    final lineExtent = textScaler.scale(
      (labelStyle.fontSize ?? 12) * (labelStyle.height ?? 1.2),
    );
    final resolvedLabelHeight = widget.labelHeight ?? (lineExtent * 2);

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
                if (widget.showHalfRing)
                  RepaintBoundary(
                    child: AnimatedBuilder(
                      animation: _ringController,
                      child: SizedBox(
                        height: ringSize,
                        width: ringSize,
                        child: CustomPaint(
                          painter: _HalfRingPainter(progress: 1),
                        ),
                      ),
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: _ringController.value * 2 * math.pi,
                          child: child,
                        );
                      },
                    ),
                  ),
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
                if (!widget.isLoading && widget.offer != null)
                  Positioned(
                    top: -10,
                    right: 13.5,
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
            SizedBox(height: widget.labelSpacing ?? 4.w),
            SizedBox(
              width: double.infinity,
              height: resolvedLabelHeight,
              child: Text(
                isTwoWordLabel
                    ? '${labelWords.first}\n${labelWords.last}'
                    : labelWords.join(' '),
                maxLines: 2,
                softWrap: true,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: labelStyle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HalfRingPainter extends CustomPainter {
  _HalfRingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = 1.8.r;
    final paint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );

    const startAngle = 0.75 * math.pi;
    final sweepAngle = math.pi * progress;
    canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
  }

  @override
  bool shouldRepaint(covariant _HalfRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
