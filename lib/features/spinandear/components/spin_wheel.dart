import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../constants/file_constants.dart';
import '../models/spin_reward.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SpinWheel extends StatelessWidget {
  const SpinWheel({
    super.key,
    required this.rewards,
    required this.rotation,
    this.size = 260,
  });

  final List<SpinReward> rewards;
  final double rotation;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.rotate(
            angle: rotation,
            child: CustomPaint(
              size: Size.square(size),
              painter: _WheelPainter(rewards: rewards),
            ),
          ),
          Container(
            width: size * 0.28,
            height: size * 0.28,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF057B83),
                  Color(0xFF011B1D),
                ],
              ),
            ),
            child: Center(
              child: Image.asset(
                FileConstants.rLogo,
                width: size * 0.1,
                height: size * 0.1,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WheelPainter extends CustomPainter {
  _WheelPainter({required this.rewards});

  final List<SpinReward> rewards;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;
    final sweep = (2 * math.pi) / rewards.length;
    const colors = [
      Color(0xFF0F6B6F),
      Color(0xFFFFFFFF),
    ];
    final dividerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.02
      ..color = const Color(0xFFE6F0F0);

    for (var i = 0; i < rewards.length; i++) {
      final sliceColor = colors[i % colors.length];
      final paint = Paint()
        ..style = PaintingStyle.fill
        ..color = sliceColor;
      final start = -math.pi / 2 + (i * sweep);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        sweep,
        true,
        paint,
      );
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        sweep,
        true,
        dividerPaint,
      );

      final label = rewards[i].label;
      final isLightSlice = sliceColor == Colors.white;
      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: isLightSlice ? const Color(0xFF0F6B6F) : Colors.white,
            fontSize: 12.sp,
            fontWeight: isLightSlice ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: radius * 0.7);

      final angle = start + sweep / 2;
      final textRadius = radius * 0.68;
      final offset = Offset(
        center.dx + math.cos(angle) * textRadius,
        center.dy + math.sin(angle) * textRadius,
      );

      canvas.save();
      canvas.translate(offset.dx, offset.dy);
      final normalized = (angle + 2 * math.pi) % (2 * math.pi);
      final rotation =
          (normalized > math.pi / 2 && normalized < 3 * math.pi / 2)
              ? angle + math.pi
              : angle;
      canvas.rotate(rotation);
      textPainter.paint(
        canvas,
        Offset(-textPainter.width / 2, -textPainter.height / 2),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _WheelPainter oldDelegate) {
    return oldDelegate.rewards != rewards;
  }
}
