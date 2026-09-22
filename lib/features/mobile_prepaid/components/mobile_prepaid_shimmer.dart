// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../constants/app_colors.dart';

class MobilePrepaidShimmer extends StatelessWidget {
  const MobilePrepaidShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return _Shimmer(
      child: Column(
        children: [
          const _ShimmerAppBar(),
          SizedBox(height: 20.h),
          const SizedBox(height: 36),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
              children: [
                _ShimmerBox(height: 46.h, radius: 14.r),
                SizedBox(height: 18.h),
                _ShimmerLine(width: 140.w, height: 16.h),
                SizedBox(height: 14.h),
                SizedBox(
                  height: 150.h,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: 3,
                    separatorBuilder: (_, __) => SizedBox(width: 12.w),
                    itemBuilder: (_, __) => const _SuggestedPlanCardShimmer(),
                  ),
                ),
                SizedBox(height: 12.h),
                const _CategoryTabsShimmer(),
                SizedBox(height: 10.h),
                ...List.generate(
                  3,
                  (index) => Padding(
                    padding: EdgeInsets.only(bottom: 14.h),
                    child: const _PlanCardShimmer(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MobilePrepaidContentShimmer extends StatelessWidget {
  const MobilePrepaidContentShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return _Shimmer(
      child: ListView(
        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
        children: [
          _ShimmerBox(height: 46.h, radius: 14.r),
          SizedBox(height: 18.h),
          _ShimmerLine(width: 140.w, height: 16.h),
          SizedBox(height: 14.h),
          SizedBox(
            height: 150.h,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              separatorBuilder: (_, __) => SizedBox(width: 12.w),
              itemBuilder: (_, __) => const _SuggestedPlanCardShimmer(),
            ),
          ),
          SizedBox(height: 12.h),
          const _CategoryTabsShimmer(),
          SizedBox(height: 10.h),
          ...List.generate(
            3,
            (index) => Padding(
              padding: EdgeInsets.only(bottom: 14.h),
              child: const _PlanCardShimmer(),
            ),
          ),
        ],
      ),
    );
  }
}

class MobilePrepaidMyNumberCardShimmer extends StatelessWidget {
  const MobilePrepaidMyNumberCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return _Shimmer(
      child: Container(
        height: 22.h + 16.h + 45.h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: const Color(0xFFE2E2E2)),
        ),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        child: Row(
          children: [
            _ShimmerBox(height: 44.h, width: 44.w, radius: 14.r),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ShimmerLine(width: 140.w, height: 12.h),
                  SizedBox(height: 8.h),
                  _ShimmerLine(width: 120.w, height: 10.h),
                ],
              ),
            ),
            SizedBox(width: 12.w),
            _ShimmerBox(height: 27.h, width: 86.w, radius: 22.r),
          ],
        ),
      ),
    );
  }
}

class MobilePrepaidRecentRechargeCardShimmer extends StatelessWidget {
  const MobilePrepaidRecentRechargeCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return _Shimmer(
      child: Container(
        width: 300.w,
        height: 22.h + 16.h + 45.h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: const Color(0xFFE2E2E2)),
        ),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        child: Row(
          children: [
            _ShimmerBox(height: 44.h, width: 44.w, radius: 14.r),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ShimmerLine(width: 150.w, height: 12.h),
                  SizedBox(height: 7.h),
                  _ShimmerLine(width: 120.w, height: 10.h),
                ],
              ),
            ),
            SizedBox(width: 10.w),
            _ShimmerBox(height: 27.h, width: 78.w, radius: 22.r),
          ],
        ),
      ),
    );
  }
}

class _ShimmerAppBar extends StatelessWidget {
  const _ShimmerAppBar();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 175,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            margin: EdgeInsets.only(bottom: 20.h),
            color: Colors.white,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    _ShimmerCircle(size: 34.r),
                    const SizedBox(width: 8),
                    _ShimmerLine(width: 160.w, height: 16.h),
                    const Spacer(),
                    _ShimmerLine(width: 46.w, height: 12.h),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: -38.h,
            height: 72.h,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: AppColors.lightBorder),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.cardShadow,
                    blurRadius: 12,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                child: Row(
                  children: [
                    _ShimmerCircle(size: 40.r),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _ShimmerLine(width: 140.w, height: 12.h),
                          SizedBox(height: 6.h),
                          _ShimmerLine(width: 120.w, height: 10.h),
                        ],
                      ),
                    ),
                    _ShimmerBox(height: 30.h, width: 80.w, radius: 16.r),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestedPlanCardShimmer extends StatelessWidget {
  const _SuggestedPlanCardShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260.w,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.lightBorder),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 3,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 16.h, 70.w, 16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ShimmerLine(width: 90.w, height: 18.h),
            SizedBox(height: 6.h),
            _ShimmerLine(width: 120.w, height: 12.h),
            SizedBox(height: 12.h),
            _ShimmerLine(width: 180.w, height: 10.h),
            SizedBox(height: 6.h),
            _ShimmerLine(width: 140.w, height: 10.h),
          ],
        ),
      ),
    );
  }
}

class _CategoryTabsShimmer extends StatelessWidget {
  const _CategoryTabsShimmer();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38.h,
      child: Row(
        children: [
          _ShimmerLine(width: 60.w, height: 12.h),
          SizedBox(width: 28.w),
          _ShimmerLine(width: 72.w, height: 12.h),
          SizedBox(width: 28.w),
          _ShimmerLine(width: 64.w, height: 12.h),
        ],
      ),
    );
  }
}

class _PlanCardShimmer extends StatelessWidget {
  const _PlanCardShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.lightBorder, width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 12,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(10.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _ShimmerLine(width: 80.w, height: 18.h),
                const Spacer(),
                _ShimmerBox(height: 18.h, width: 90.w, radius: 12.r),
              ],
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                _ShimmerLine(width: 60.w, height: 12.h),
                SizedBox(width: 16.w),
                _ShimmerLine(width: 60.w, height: 12.h),
                const Spacer(),
                _ShimmerCircle(size: 24.r),
              ],
            ),
            SizedBox(height: 12.h),
            _ShimmerLine(width: double.infinity, height: 10.h),
            SizedBox(height: 6.h),
            _ShimmerLine(width: 160.w, height: 10.h),
            SizedBox(height: 12.h),
            Row(
              children: [
                _ShimmerLine(width: 80.w, height: 12.h),
                const Spacer(),
                _ShimmerBox(height: 30.h, width: 90.w, radius: 20.r),
              ],
            ),
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

class _ShimmerBox extends StatelessWidget {
  const _ShimmerBox({
    required this.height,
    this.width,
    this.radius = 12,
  });

  final double height;
  final double? width;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(radius),
      ),
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
