// ignore_for_file: deprecated_member_use

import 'package:e_rupaiya/constants/app_colors.dart';
import 'package:e_rupaiya/core/barrel_file.dart';
import 'package:e_rupaiya/features/home/components/quick_action_header_card.dart';
import 'package:e_rupaiya/features/services/components/fetch_provider_metrics.dart';
import 'package:google_fonts/google_fonts.dart';

class SimpleQuickActionCard extends StatelessWidget {
  const SimpleQuickActionCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.leadingAsset,
    this.leadingImageUrl,
    this.onTap,
    this.actionLabel,
    this.onAction,
    this.showShadow = true,
    this.operatorStyle = false,
  });

  final String title;
  final String subtitle;
  final String? leadingAsset;
  final String? leadingImageUrl;
  final VoidCallback? onTap;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool showShadow;

  /// Figma operator card (Electricity Pay Now): 50x50 logo box, larger title,
  /// and a card that grows with text instead of a fixed height.
  final bool operatorStyle;

  /// Figma soft elevation for the Maharashtra / operator card (440 frame):
  /// 0 10 22 #7070701A, 0 41 41 #70707017, 0 91 55 #7070700D,
  /// 0 163 65 #70707003, 0 254 71 #70707000.
  static List<BoxShadow> get figmaOperatorCardShadows => [
        BoxShadow(
          color: const Color(0x1A707070),
          offset: Offset(0, FetchProviderMetrics.h(10)),
          blurRadius: FetchProviderMetrics.r(22),
        ),
        BoxShadow(
          color: const Color(0x17707070),
          offset: Offset(0, FetchProviderMetrics.h(41)),
          blurRadius: FetchProviderMetrics.r(41),
        ),
        BoxShadow(
          color: const Color(0x0D707070),
          offset: Offset(0, FetchProviderMetrics.h(91)),
          blurRadius: FetchProviderMetrics.r(55),
        ),
        BoxShadow(
          color: const Color(0x03707070),
          offset: Offset(0, FetchProviderMetrics.h(163)),
          blurRadius: FetchProviderMetrics.r(65),
        ),
        BoxShadow(
          color: const Color(0x00707070),
          offset: Offset(0, FetchProviderMetrics.h(254)),
          blurRadius: FetchProviderMetrics.r(71),
        ),
      ];

  static String _capitalizeWords(String value) => value
      .split(' ')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');

  @override
  Widget build(BuildContext context) {
    final hasAction = (actionLabel ?? '').trim().isNotEmpty;
    final titleText = operatorStyle ? _capitalizeWords(title) : title;
    final titleSize =
        operatorStyle ? FetchProviderMetrics.font(14, min: 12) : 13.sp;
    // Electricity fetched biller name (e.g. Maharashtra State Electricity):
    // Figma weight 500.
    final titleStyle = operatorStyle
        ? GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w500,
            fontSize: titleSize,
            height: 1,
            letterSpacing: -0.02 * titleSize,
            color: const Color(0xFF000000),
          )
        : GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w600,
            fontSize: titleSize,
            color: const Color(0xFF000000),
          );

    // Tight height is required: a Container with [alignment] and only
    // minHeight expands to the Row's max cross-axis extent (often the full
    // body height) on the first layout pass — the Change pill looked huge
    // then "shrank" once constraints settled.
    final changeHeight = operatorStyle ? FetchProviderMetrics.h(28) : 26.h;
    final changeFont =
        operatorStyle ? FetchProviderMetrics.font(12, min: 11) : 11.sp;
    final changeMinWidth =
        operatorStyle ? FetchProviderMetrics.w(72) : FetchProviderMetrics.w(64);
    final changeHPad =
        operatorStyle ? FetchProviderMetrics.w(14) : FetchProviderMetrics.w(12);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(
        operatorStyle ? FetchProviderMetrics.r(16) : 22.r,
      ),
      child: Container(
        width: double.infinity,
        height: operatorStyle ? null : 68.h,
        padding: operatorStyle
            ? EdgeInsets.symmetric(
                horizontal: FetchProviderMetrics.w(16),
                vertical: FetchProviderMetrics.h(15),
              )
            : EdgeInsets.symmetric(horizontal: 14.w),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(
            operatorStyle ? FetchProviderMetrics.r(16) : 16.r,
          ),
          border: Border.all(
            color:
                operatorStyle ? const Color(0xFFE2E0E0) : AppColors.lightBorder,
            width: 1,
          ),
          boxShadow: showShadow
              ? (operatorStyle
                  ? figmaOperatorCardShadows
                  : [
                      BoxShadow(
                        color: const Color(0x1A707070),
                        offset: Offset(0, 10.h),
                        blurRadius: 22.r,
                      ),
                      BoxShadow(
                        color: const Color(0x17707070),
                        offset: Offset(0, 41.h),
                        blurRadius: 41.r,
                      ),
                      BoxShadow(
                        color: const Color(0x0D707070),
                        offset: Offset(0, 91.h),
                        blurRadius: 55.r,
                      ),
                      BoxShadow(
                        color: const Color(0x03707070),
                        offset: Offset(0, 163.h),
                        blurRadius: 65.r,
                      ),
                      BoxShadow(
                        color: const Color(0x00707070),
                        offset: Offset(0, 254.h),
                        blurRadius: 71.r,
                      ),
                    ])
              : const [],
        ),
        child: Row(
          children: [
            SimCardIconContainer(
              asset: leadingAsset,
              url: leadingImageUrl,
              width: operatorStyle ? FetchProviderMetrics.r(50) : 44.r,
              height: operatorStyle ? FetchProviderMetrics.r(50) : 44.r,
              borderRadius: operatorStyle ? FetchProviderMetrics.r(20) : 12.r,
              padding: operatorStyle ? FetchProviderMetrics.w(10) : 10.w,
              borderWidth: operatorStyle ? 1 : 0.5,
            ),
            SizedBox(
              width: operatorStyle ? FetchProviderMetrics.w(10) : 10.w,
            ),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (title.trim().isNotEmpty)
                    Text(
                      titleText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: titleStyle,
                    ),
                  if (title.trim().isNotEmpty && subtitle.trim().isNotEmpty)
                    SizedBox(height: 2.h),
                  if (subtitle.trim().isNotEmpty)
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w500,
                        fontSize: 9.sp,
                        color: const Color(0xFF7C7C7C),
                      ),
                    ),
                ],
              ),
            ),
            if (hasAction) ...[
              SizedBox(
                width: operatorStyle ? FetchProviderMetrics.w(8) : 10.w,
              ),
              // Figma Change pill: fixed height so first-frame Row constraints
              // cannot stretch it; width hugs label with a Figma minWidth.
              GestureDetector(
                key: const ValueKey('simple-quick-action-change'),
                onTap: onAction ?? onTap,
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  height: changeHeight,
                  child: Container(
                    constraints: BoxConstraints(minWidth: changeMinWidth),
                    padding: EdgeInsets.symmetric(horizontal: changeHPad),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(
                        operatorStyle ? FetchProviderMetrics.r(20) : 20.r,
                      ),
                    ),
                    child: Text(
                      actionLabel!,
                      maxLines: 1,
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: changeFont,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class SimCardIconContainer extends StatelessWidget {
  const SimCardIconContainer({
    super.key,
    this.asset,
    this.url,
    this.width,
    this.height,
    this.borderRadius,
    this.padding,
    this.borderWidth,
  });

  final String? asset;
  final String? url;
  final double? width;
  final double? height;
  final double? borderRadius;
  final double? padding;
  final double? borderWidth;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? 20.r;
    final inset = padding ?? 8.w;
    final stroke = borderWidth ?? 1.w;
    return Container(
      width: width ?? 50.w,
      height: height ?? 45.h,
      padding: EdgeInsets.all(inset),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: const Color(0xFFE2E2E2),
          width: stroke,
        ),
      ),
      child: Center(
        child: FittedBox(
          fit: BoxFit.contain,
          child: LeadingIcon(
            asset: asset,
            url: url,
          ),
        ),
      ),
    );
  }
}
