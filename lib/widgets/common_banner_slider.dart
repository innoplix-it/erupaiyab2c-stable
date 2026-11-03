import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../constants/app_colors.dart';
import '../features/home/models/banner_model.dart';
import 'app_network_image.dart';

/// Reusable, auto-advancing image banner slider.
///
/// Mirrors the Home "Banking & Investments" carousel behaviour so the same
/// "common" slider can be dropped into any screen (Profile, etc.): it
/// auto-advances every [interval] when more than one banner is present,
/// supports manual swipe, and shows a dot indicator. Feed it any
/// [BannerModel] list; taps bubble up through [onTap]. Renders nothing when
/// the list is empty, so callers can drop it in unconditionally.
class CommonBannerSlider extends StatefulWidget {
  const CommonBannerSlider({
    super.key,
    required this.banners,
    required this.height,
    this.borderRadius = 10,
    this.interval = const Duration(seconds: 3),
    this.onTap,
  });

  final List<BannerModel> banners;
  final double height;
  final double borderRadius;
  final Duration interval;
  final ValueChanged<BannerModel>? onTap;

  @override
  State<CommonBannerSlider> createState() => _CommonBannerSliderState();
}

class _CommonBannerSliderState extends State<CommonBannerSlider> {
  final PageController _controller = PageController();
  Timer? _timer;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _startAutoPlay();
  }

  @override
  void didUpdateWidget(covariant CommonBannerSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.banners.length != widget.banners.length) {
      _stopAutoPlay();
      if (_page >= widget.banners.length) _page = 0;
      _startAutoPlay();
    }
  }

  void _startAutoPlay() {
    if (widget.banners.length < 2) return;
    _timer = Timer.periodic(widget.interval, (_) {
      if (!mounted || !_controller.hasClients) return;
      final next = (_page + 1) % widget.banners.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  void _stopAutoPlay() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _stopAutoPlay();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final banners = widget.banners;
    if (banners.isEmpty) return const SizedBox.shrink();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius.r),
          child: SizedBox(
            height: widget.height,
            width: double.infinity,
            child: PageView.builder(
              controller: _controller,
              itemCount: banners.length,
              onPageChanged: (index) => setState(() => _page = index),
              itemBuilder: (context, index) {
                final banner = banners[index];
                return GestureDetector(
                  onTap: () => widget.onTap?.call(banner),
                  child: AppNetworkImage(
                    url: banner.image,
                    width: double.infinity,
                    height: widget.height,
                    fit: BoxFit.contain,
                  ),
                );
              },
            ),
          ),
        ),
        if (banners.length > 1) ...[
          SizedBox(height: 8.h),
          _Dots(count: banners.length, active: _page),
        ],
      ],
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.active});

  final int count;
  final int active;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List<Widget>.generate(count, (i) {
        final isActive = i == active;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: EdgeInsets.symmetric(horizontal: 3.w),
          height: 6.r,
          width: isActive ? 16.r : 6.r,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : const Color(0xFFD9D9D9),
            borderRadius: BorderRadius.circular(999.r),
          ),
        );
      }),
    );
  }
}
