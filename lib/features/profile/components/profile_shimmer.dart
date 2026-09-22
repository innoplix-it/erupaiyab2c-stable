// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ProfileShimmer extends StatelessWidget {
  const ProfileShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return _Shimmer(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 18.h),
            Row(
              children: [
                _Circle(size: 48),
                SizedBox(width: 14.w),
                _Line(width: 120.w, height: 16.h),
                Spacer(),
                _Line(width: 18.w, height: 18.h),
              ],
            ),
            SizedBox(height: 18.h),
            _Card(height: 84.h),
            SizedBox(height: 18.h),
            _MenuRow(),
            _MenuRow(),
            _MenuRow(),
            _MenuRow(),
            _MenuRow(),
            _MenuRow(),
            _MenuRow(),
            _MenuRow(),
            _MenuRow(),
            SizedBox(height: 18.h),
            Center(child: _Line(width: 120.w, height: 12.h)),
            SizedBox(height: 12.h),
          ],
        ),
      ),
    );
  }
}

class _Shimmer extends StatefulWidget {
  const _Shimmer({required this.child});

  final Widget child;

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final value = _controller.value * 3 - 1;
        return ShaderMask(
          shaderCallback: (rect) {
            return LinearGradient(
              colors: [
                AppColors.lightBorder.withOpacity(0.2),
                AppColors.lightBorder.withOpacity(0.6),
                AppColors.lightBorder.withOpacity(0.2),
              ],
              stops: const [0.25, 0.5, 0.75],
              begin: const Alignment(-1, -0.3),
              end: const Alignment(1, 0.3),
              transform: _SlidingGradientTransform(value),
            ).createShader(rect);
          },
          blendMode: BlendMode.srcATop,
          child: widget.child,
        );
      },
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform(this.slidePercent);

  final double slidePercent;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0, 0);
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8.r),
      ),
    );
  }
}

class _Circle extends StatelessWidget {
  const _Circle({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(18.r),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Row(
        children: [
          _Line(width: 22.w, height: 22.h),
          SizedBox(width: 16.w),
          _Line(width: 160.w, height: 14.h),
        ],
      ),
    );
  }
}
