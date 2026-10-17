// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../constants/file_constants.dart';
import '../../../widgets/app_network_image.dart';
import '../../home/models/banner_model.dart';

class CreditCardMyCardsBanner extends StatelessWidget {
  const CreditCardMyCardsBanner({
    super.key,
    required this.banners,
  });

  final AsyncValue<List<BannerModel>> banners;

  @override
  Widget build(BuildContext context) {
    return banners.when(
      loading: () => _fallback(),
      error: (_, __) => _fallback(),
      data: (items) {
        final banner = items.isNotEmpty ? items.first : null;
        final image = banner?.image.trim() ?? '';
        if (image.isEmpty) return _fallback();

        return AppNetworkImage(
          url: image,
          width: double.infinity,
          fit: BoxFit.contain,
          showShimmer: true,
          borderRadius: BorderRadius.circular(14.r),
        );
      },
    );
  }

  Widget _fallback() {
    // Figma promo banner ~ wide card; keep aspect without clipping art.
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width - 32.w;
        final height = (width * (120 / 360)).clamp(88.h, 140.h);
        return ClipRRect(
          borderRadius: BorderRadius.circular(12.r),
          child: SizedBox(
            width: width,
            height: height,
            child: Image.asset(
              FileConstants.homeBanner4,
              width: width,
              height: height,
              fit: BoxFit.cover,
            ),
          ),
        );
      },
    );
  }
}
