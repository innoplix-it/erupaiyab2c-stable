import 'package:flutter/material.dart';

import '../components/credit_card/credit_card_figma_metrics.dart';

import '../../../constants/app_colors.dart';

class CreditCardMyCardsShimmer extends StatelessWidget {
  const CreditCardMyCardsShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final pad = CreditCardFigmaMetrics.screenPadding(context).copyWith(
      top: CreditCardFigmaMetrics.sy(context, 6),
      bottom: CreditCardFigmaMetrics.sy(context, 12),
    );
    return Padding(
      padding: pad,
      child: _Shimmer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ShimmerLine(width: CreditCardFigmaMetrics.s(context, 90), height: CreditCardFigmaMetrics.sy(context, 14)),
            SizedBox(
              height: CreditCardFigmaMetrics.myCardAfterBannerGap(context),
            ),
            ...List.generate(
              3,
              (index) => Padding(
                padding: EdgeInsets.only(
                  bottom: CreditCardFigmaMetrics.myCardListGap(context),
                ),
                child: const _CardShimmer(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardShimmer extends StatelessWidget {
  const _CardShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(CreditCardFigmaMetrics.myCardRadius(context)),
        border: Border.all(color: AppColors.lightBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: CreditCardFigmaMetrics.myCardShadowBlur(context),
            offset: Offset(0, CreditCardFigmaMetrics.myCardShadowOffsetY(context)),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: CreditCardFigmaMetrics.myCardHeaderPadding(context),
            child: Row(
              children: [
                _ShimmerCircle(
                  size: CreditCardFigmaMetrics.myCardLogoSize(context),
                  radius: CreditCardFigmaMetrics.myCardLogoRadius(context),
                ),
                SizedBox(width: CreditCardFigmaMetrics.s(context, 12)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ShimmerLine(
                        width: CreditCardFigmaMetrics.s(context, 140),
                        height: CreditCardFigmaMetrics.sy(context, 14),
                      ),
                      SizedBox(height: CreditCardFigmaMetrics.sy(context, 2)),
                      _ShimmerLine(
                        width: CreditCardFigmaMetrics.s(context, 90),
                        height: CreditCardFigmaMetrics.sy(context, 12),
                      ),
                    ],
                  ),
                ),
                _ShimmerCircle(size: CreditCardFigmaMetrics.myCardMenuIconSize(context)),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.lightBorder),
          Padding(
            padding: CreditCardFigmaMetrics.myCardBillPadding(context),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ShimmerLine(
                        width: CreditCardFigmaMetrics.s(context, 100),
                        height: CreditCardFigmaMetrics.sy(context, 16),
                      ),
                      SizedBox(height: CreditCardFigmaMetrics.sy(context, 2)),
                      _ShimmerLine(
                        width: CreditCardFigmaMetrics.s(context, 130),
                        height: CreditCardFigmaMetrics.sy(context, 12),
                      ),
                    ],
                  ),
                ),
                _ShimmerBox(
                  height: CreditCardFigmaMetrics.payNowButtonHeight(context),
                  width: CreditCardFigmaMetrics.payNowButtonWidth(context),
                  radius: CreditCardFigmaMetrics.payNowButtonRadius(context),
                ),
              ],
            ),
          ),
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
        borderRadius: BorderRadius.circular(CreditCardFigmaMetrics.s(context, 8)),
      ),
    );
  }
}

class _ShimmerCircle extends StatelessWidget {
  const _ShimmerCircle({required this.size, this.radius});

  final double size;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        shape: radius == null ? BoxShape.circle : BoxShape.rectangle,
        borderRadius:
            radius == null ? null : BorderRadius.circular(radius!),
      ),
    );
  }
}
