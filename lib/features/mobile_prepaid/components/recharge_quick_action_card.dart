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

  static String _capitalizeWords(String value) => value
      .split(' ')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');

  @override
  Widget build(BuildContext context) {
    final hasAction = (actionLabel ?? '').trim().isNotEmpty;
    final titleText = operatorStyle ? _capitalizeWords(title) : title;
    final titleStyle = operatorStyle
        ? GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w500,
            fontSize: 14.sp,
            height: 1,
            letterSpacing: -0.02 * 14.sp,
            color: const Color(0xFF000000),
          )
        : GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w600,
            fontSize: 13.sp,
            color: const Color(0xFF000000),
          );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22.r),
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
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppColors.lightBorder, width: 1.w),
          boxShadow: showShadow
              ? [
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
                ]
              : const [],
        ),
        child: Row(
          children: [
            SimCardIconContainer(
              asset: leadingAsset,
              url: leadingImageUrl,
              width: operatorStyle ? FetchProviderMetrics.r(50) : 44.w,
              height: operatorStyle ? FetchProviderMetrics.r(50) : 44.w,
              borderRadius: operatorStyle ? FetchProviderMetrics.r(20) : 12.r,
              padding: operatorStyle ? FetchProviderMetrics.w(10) : 10.w,
              borderWidth: operatorStyle ? 1 : 0.5,
            ),
            SizedBox(width: 10.w),
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
              SizedBox(width: 10.w),
              GestureDetector(
                onTap: onAction ?? onTap,
                child: Container(
                  width: 68.w,
                  height: 26.h,
                  padding: EdgeInsets.fromLTRB(8.w, 4.h, 8.w, 4.h),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(50.r),
                  ),
                  child: Text(
                    actionLabel!,
                    maxLines: 1,
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 10.sp,
                      height: 1,
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
