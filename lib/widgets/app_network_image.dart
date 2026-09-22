// ignore_for_file: deprecated_member_use

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../constants/app_colors.dart';
import '../constants/file_constants.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.cacheWidth,
    this.cacheHeight,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
    this.showShimmer = true,
    this.fitToDeviceWidth = false,
  });

  final String? url;
  final double? width;
  final double? height;
  final int? cacheWidth;
  final int? cacheHeight;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;
  final bool showShimmer;
  final bool fitToDeviceWidth;

  @override
  Widget build(BuildContext context) {
    final trimmed = url?.trim() ?? '';
    if (trimmed.isEmpty) {
      return _wrap(_buildPlaceholder());
    }

    final isSvg = trimmed.toLowerCase().endsWith('.svg');
    final isGif = trimmed.toLowerCase().endsWith('.gif');
    final resolvedUrl = fitToDeviceWidth && !isSvg
        ? _appendWidthParam(context, trimmed)
        : trimmed;
    if (isSvg) {
      return _wrap(
        SvgPicture.network(
          resolvedUrl,
          width: width,
          height: height,
          fit: fit,
          placeholderBuilder: (_) => _buildLoading(),
        ),
      );
    }

    return _wrap(
      CachedNetworkImage(
        imageUrl: resolvedUrl,
        width: width,
        height: height,
        fit: fit,
        // For animated GIFs, resizing via memCacheWidth/Height can result in a
        // non-animated (single-frame) image on some platforms.
        memCacheWidth: isGif ? null : cacheWidth,
        memCacheHeight: isGif ? null : cacheHeight,
        placeholder: (_, __) => _buildLoading(),
        errorWidget: (_, __, ___) => errorWidget ?? _buildPlaceholder(),
      ),
    );
  }

  Widget _wrap(Widget child) {
    final radius = borderRadius;
    if (radius == null) return child;
    return ClipRRect(
      borderRadius: radius,
      child: child,
    );
  }

  String _appendWidthParam(BuildContext context, String rawUrl) {
    final uri = Uri.tryParse(rawUrl);
    if (uri == null) return rawUrl;
    if (uri.queryParameters.containsKey('w')) return rawUrl;
    final logicalWidth = width ?? 1.sw;
    final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
    final targetWidth = (logicalWidth * devicePixelRatio).round();
    if (targetWidth <= 0) return rawUrl;
    final params = Map<String, String>.from(uri.queryParameters);
    params['w'] = targetWidth.toString();
    return uri.replace(queryParameters: params).toString();
  }

  Widget _buildPlaceholder() {
    if (placeholder != null) return placeholder!;
    if (!showShimmer) {
      return _FallbackBox(width: width, height: height);
    }
    return _Shimmer(
      child: _FallbackBox(width: width, height: height),
    );
  }

  Widget _buildLoading() {
    if (placeholder != null) return placeholder!;
    final shimmer = showShimmer
        ? _Shimmer(child: _FallbackBox(width: width, height: height))
        : _FallbackBox(width: width, height: height);
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          shimmer,
          Center(
            child: Image.asset(
              FileConstants.loadingGif,
              width: 32.r,
              height: 32.r,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
}

class _FallbackBox extends StatelessWidget {
  const _FallbackBox({this.width, this.height});

  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: AppColors.lightBorder.withOpacity(0.25),
      alignment: Alignment.center,
      child: Icon(
        Icons.image_outlined,
        size: 18.r,
        color: AppColors.textPrimary.withOpacity(0.5),
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
