// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../constants/app_colors.dart';
import '../../../widgets/app_network_image.dart';
import '../models/latest_transaction.dart';

class RecentRechargePayments extends StatelessWidget {
  const RecentRechargePayments({
    super.key,
    required this.recentPayments,
    required this.onRepeat,
    this.onViewAll,
  });

  final AsyncValue<List<LatestTransaction>> recentPayments;
  final ValueChanged<LatestTransaction> onRepeat;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    return recentPayments.when(
      loading: () => Container(
        padding: EdgeInsets.fromLTRB(0.w, 8.h, 0.w, 8.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(onViewAll: onViewAll),
            SizedBox(height: 12.h),
            const _RecentPaymentsShimmer(),
          ],
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        return Container(
          padding: EdgeInsets.fromLTRB(0.w, 8.h, 0.w, 8.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(onViewAll: onViewAll),
              SizedBox(height: 12.h),
              SizedBox(height: 75.h,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.zero,
                  itemBuilder: (context, index) => _RecentPaymentCard(
                    item: items[index],
                    onRepeat: () => onRepeat(items[index]),
                  ),
                  separatorBuilder: (_, __) => SizedBox(width: 12.w),
                  itemCount: items.length,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({this.onViewAll});
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'Recent',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
        ),
        const Spacer(),
        // if (onViewAll != null)
        // InkWell(
        //   onTap: onViewAll,
        //   child: Text(
        //     'View all',
        //     style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        //           color: AppColors.primary,
        //           fontWeight: FontWeight.w700,
        //         ),
        //   ),
        // ),
      ],
    );
  }
}

class _RecentPaymentCard extends StatelessWidget {
  const _RecentPaymentCard({
    required this.item,
    required this.onRepeat,
  });

  final LatestTransaction item;
  final VoidCallback onRepeat;

  @override
  Widget build(BuildContext context) {
    final title = item.serviceNo.trim().isNotEmpty ? item.serviceNo : '--';
    final subtitleParts = <String>[
      if (item.billerName.trim().isNotEmpty) item.billerName,
      if (item.amount > 0) '₹${item.amount}',
      if (item.status.trim().isNotEmpty) item.status,
    ];
    final subtitle = subtitleParts.join(' • ');

    return InkWell(
      onTap: onRepeat,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        width: 300.w,
        constraints: BoxConstraints(minHeight: 62.h),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xffE2E2E2)),
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          children: [
            Container(
              height: 45.h,
              width: 45.h,
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: const Color.fromARGB(255, 239, 238, 238),
                  width: 1,
                ),
              ),
              child: AppNetworkImage(
                url: item.icon,
                fit: BoxFit.contain,
                showShimmer: false,
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          fontSize: 13.sp,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle.isNotEmpty) SizedBox(height: 2.h),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textPrimary.withOpacity(0.65),
                            fontSize: 8.sp,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            GestureDetector(
              onTap: onRepeat,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 12.w,
                  vertical: 8.h,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE85A2C),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  'Repeat',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentPaymentsShimmer extends StatelessWidget {
  const _RecentPaymentsShimmer();

  @override
  Widget build(BuildContext context) {
    return _Shimmer(
      child: SizedBox(height: 78.h,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: 3,
          separatorBuilder: (_, __) => SizedBox(width: 12.w),
          itemBuilder: (_, __) => Container(
            width: 300.w,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: const Color(0xffE2E2E2)),
            ),
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            child: Row(
              children: [
                Container(
                  height: 45.h,
                  width: 45.h,
                  decoration: BoxDecoration(
                    color: AppColors.lightBorder.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Box(height: 12.h, width: 140.w),
                      SizedBox(height: 6.h),
                      _Box(height: 10.h, width: 180.w),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                _Box(height: 30.h, width: 74.w, radius: 20.r),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Box extends StatelessWidget {
  const _Box({
    required this.height,
    required this.width,
    this.radius,
  });

  final double height;
  final double width;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: AppColors.lightBorder.withOpacity(0.25),
        borderRadius: BorderRadius.circular(radius ?? 6.r),
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
