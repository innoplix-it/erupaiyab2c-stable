// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../constants/app_colors.dart';

class ScanFrame extends StatelessWidget {
  const ScanFrame({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ScanFramePainter(),
        child: Container(
          margin: EdgeInsets.all(10.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18.r),
          ),
          child: Center(
            child: Icon(
              Icons.qr_code_2_rounded,
              size: 110.sp,
              color: AppColors.textPrimary.withOpacity(0.35),
            ),
          ),
        ),
      ),
    );
  }
}

class _ScanFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cornerPaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const cornerLength = 24.0;
    final radius = 18.0.r;
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(radius),
    );

    canvas.drawRRect(
      rect,
      Paint()
        ..color = Colors.white.withOpacity(0.08)
        ..style = PaintingStyle.fill,
    );

    // Top-left
    canvas.drawLine(
      const Offset(0, cornerLength),
      Offset(0.w, 0.h),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(0.w, 0.h),
      const Offset(cornerLength, 0),
      cornerPaint,
    );

    // Top-right
    canvas.drawLine(
      Offset(size.width - cornerLength, 0),
      Offset(size.width, 0),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(size.width, 0),
      Offset(size.width, cornerLength),
      cornerPaint,
    );

    // Bottom-left
    canvas.drawLine(
      Offset(0, size.height - cornerLength),
      Offset(0, size.height),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(0, size.height),
      Offset(cornerLength, size.height),
      cornerPaint,
    );

    // Bottom-right
    canvas.drawLine(
      Offset(size.width - cornerLength, size.height),
      Offset(size.width, size.height),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(size.width, size.height - cornerLength),
      Offset(size.width, size.height),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
