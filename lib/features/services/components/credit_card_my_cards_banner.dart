// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../constants/file_constants.dart';
import '../../../widgets/app_network_image.dart';
import '../../home/models/banner_model.dart';
import 'credit_card/credit_card_figma_metrics.dart';

class CreditCardMyCardsBanner extends StatelessWidget {
  const CreditCardMyCardsBanner({
    super.key,
    required this.banners,
  });

  final AsyncValue<List<BannerModel>> banners;

  @override
  Widget build(BuildContext context) {
    double sx(double v) => CreditCardFigmaMetrics.s(context, v);
    return banners.when(
      loading: () => _fallback(context),
      error: (_, __) => _fallback(context),
      data: (items) {
        final banner = items.isNotEmpty ? items.first : null;
        final image = banner?.image.trim() ?? '';
        if (image.isEmpty) return _fallback(context);

        return AppNetworkImage(
          url: image,
          width: double.infinity,
          fit: BoxFit.contain,
          showShimmer: true,
          borderRadius: BorderRadius.circular(sx(14)),
        );
      },
    );
  }

  Widget _fallback(BuildContext context) {
    double sx(double v) => CreditCardFigmaMetrics.s(context, v);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final height = CreditCardFigmaMetrics.myCardsBannerHeightForWidth(
          context,
          width,
        );
        return ClipRRect(
          borderRadius: BorderRadius.circular(
            CreditCardFigmaMetrics.myCardRadius(context),
          ),
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
