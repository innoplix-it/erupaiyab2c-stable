// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class HomeShimmer extends StatelessWidget {
  const HomeShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: ColoredBox(
        color: Colors.white,
        child: Align(
          alignment: Alignment.topCenter,
          child: ClipRRect(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24.r),
              topRight: Radius.circular(24.r),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.cardShadow,
                    blurRadius: 20.r,
                    offset: Offset(0, -10),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12.h),
                child: _ShimmerBody(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShimmerBody extends StatelessWidget {
  const _ShimmerBody();

  @override
  Widget build(BuildContext context) {
    return _Shimmer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 4.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: _ShimmerLine(width: 140.w, height: 16.h),
          ),
          SizedBox(height: 12.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: _ShimmerBox(
              height: 76.h,
              radius: 16.r,
              child: Row(
                children: [
                  SizedBox(width: 16.w),
                  _ShimmerCircle(size: 34),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ShimmerLine(width: double.infinity, height: 12.h),
                        SizedBox(height: 6.h),
                        _ShimmerLine(width: 180.w, height: 10.h),
                      ],
                    ),
                  ),
                  SizedBox(width: 12.w),
                  _ShimmerBox(
                    height: 48.h,
                    width: 90.w,
                    radius: 14.r,
                  ),
                  SizedBox(width: 12.w),
                ],
              ),
            ),
          ),
          SizedBox(height: 10.h),
          _PagerDotsShimmer(),
          SizedBox(height: 16.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: _ShimmerLine(width: 120.w, height: 14.h),
          ),
          SizedBox(height: 12.h),
          _IconGridShimmer(rows: 2, columns: 4),
          SizedBox(height: 18.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: _ShimmerLine(width: 150.w, height: 14.h),
          ),
          SizedBox(height: 12.h),
          _IconGridShimmer(rows: 2, columns: 4),
          SizedBox(height: 12.h),
        ],
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
        final value = _controller.value * 3 - 1; // -1 to 2
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

class _ShimmerBox extends StatelessWidget {
  const _ShimmerBox({
    required this.height,
    this.width,
    this.radius = 12,
    this.child,
  });

  final double height;
  final double? width;
  final double radius;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: child,
    );
  }
}

class _ShimmerLine extends StatelessWidget {
  const _ShimmerLine({required this.width, required this.height});

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

class _ShimmerCircle extends StatelessWidget {
  const _ShimmerCircle({required this.size});

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

class _IconGridShimmer extends StatelessWidget {
  const _IconGridShimmer({required this.rows, required this.columns});

  final int rows;
  final int columns;

  @override
  Widget build(BuildContext context) {
    final items = rows * columns;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Wrap(
        spacing: 16.w,
        runSpacing: 16.h,
        children: List.generate(items, (index) {
          return SizedBox(
            width: (1.sw - 16.w * 2 - 16.w * (columns - 1)) / columns,
            child: Column(
              children: [
                _ShimmerBox(height: 56.h, width: 56.w, radius: 16.r),
                SizedBox(height: 8.h),
                _ShimmerLine(width: 56.w, height: 10.h),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _PagerDotsShimmer extends StatelessWidget {
  const _PagerDotsShimmer();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _Dot(width: 24.w),
        SizedBox(width: 6.w),
        _Dot(width: 8.w),
        SizedBox(width: 6.w),
        _Dot(width: 8.w),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 6,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8.r),
      ),
    );
  }
}
