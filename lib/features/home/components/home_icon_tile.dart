// ignore_for_file: deprecated_member_use

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_text_styles.dart';
import '../../../constants/file_constants.dart';
import '../../../widgets/app_network_image.dart';

class HomeIconTile extends StatefulWidget {
  const HomeIconTile({
    super.key,
    required this.label,
    this.onTap,
    this.iconSize = 28,
    this.iconUrl,
    this.offer,
    this.labelSpacing,
    this.showHalfRing = false,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onTap;
  final double iconSize;
  final String? iconUrl;
  final int? offer;
  final double? labelSpacing;
  final bool showHalfRing;
  final bool isLoading;

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
    final labelTextStyle = AppTextStyles.bodySmallSemibold(context);
    final labelWords = widget.label.trim().split(RegExp(r'\s+'));
    final isTwoWordLabel = labelWords.length == 2;

    final ringSize = 62.r;
    final iconSize = widget.iconSize.r;

    return RepaintBoundary(
      child: InkWell(
        borderRadius: BorderRadius.circular(12.r),
        onTap: widget.isLoading ? null : widget.onTap,
        child: Column(
          mainAxisSize: MainAxisSize.max,
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
                Container(
                  height: 54.r,
                  width: 54.r,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 0.5,
                      colors: [
                        Color(0xFFF9F9F9),
                        Color(0xFFF6F6F6),
                      ],
                    ),
                  ),
                  child: Center(
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
            SizedBox(height: widget.labelSpacing ?? 6.h),
            SizedBox(
              width: double.infinity,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final displayLabel = isTwoWordLabel
                      ? '${labelWords.first}\n${labelWords.last}'
                      : _truncateSingleWordLabel(
                          widget.label,
                          constraints.maxWidth,
                          labelTextStyle,
                        );

                  return Text(
                    displayLabel,
                    maxLines: isTwoWordLabel ? 2 : 1,
                    softWrap: isTwoWordLabel,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: labelTextStyle,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _truncateSingleWordLabel(
    String label,
    double maxWidth,
    TextStyle? style,
  ) {
    final trimmed = label.trim();
    if (trimmed.isEmpty || trimmed.contains(' ')) return trimmed;

    final fullTextPainter = TextPainter(
      text: TextSpan(text: trimmed, style: style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);

    if (!fullTextPainter.didExceedMaxLines) {
      return trimmed;
    }

    const suffix = '..';
    for (var end = trimmed.length - 1; end > 0; end--) {
      final candidate = '${trimmed.substring(0, end)}$suffix';
      final candidatePainter = TextPainter(
        text: TextSpan(text: candidate, style: style),
        maxLines: 1,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: maxWidth);

      if (!candidatePainter.didExceedMaxLines) {
        return candidate;
      }
    }

    return suffix;
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
