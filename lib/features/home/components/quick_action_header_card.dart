// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/file_constants.dart';
import '../../../widgets/app_network_image.dart';

class QuickActionHeaderCard extends StatelessWidget {
  const QuickActionHeaderCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.leadingAsset,
    this.leadingImageUrl,
    this.onTap,
    this.actionLabel,
    this.onAction,
    this.actionBackgroundAsset,
  });

  final String title;
  final String subtitle;
  final String? leadingAsset;
  final String? leadingImageUrl;
  final VoidCallback? onTap;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? actionBackgroundAsset;

  @override
  Widget build(BuildContext context) {
    final hasAction = (actionLabel ?? '').trim().isNotEmpty;
    final bgAsset = actionBackgroundAsset ?? FileConstants.quickAction;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18.r),
      child: Container(
        constraints: BoxConstraints(minHeight: 72.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18.r),
          boxShadow: const [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: EdgeInsets.only(left: 12.w, top: 8.h, bottom: 8.h),
              child: CircleAvatar(
                radius: 26.r,
                backgroundColor: AppColors.primary.withOpacity(0.12),
                child: LeadingIcon(
                  asset: leadingAsset,
                  url: leadingImageUrl,
                ),
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8.h),
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
                    SizedBox(height: 2.h),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textPrimary.withOpacity(0.65),
                            fontSize: 10.sp,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            if (hasAction)
              SizedBox(
                width: 88.w,
                height: 72.h,
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(18.r),
                    bottomRight: Radius.circular(18.r),
                  ),
                  child: InkWell(
                    onTap: onAction ?? onTap,
                    child: Stack(
                      fit: StackFit.expand,
                      alignment: Alignment.center,
                      children: [
                        Image.asset(
                          bgAsset,
                          fit: BoxFit.fill,
                        ),
                        Center(
                          child: Text(
                            actionLabel!,
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.4,
                                  fontSize: 11.sp,
                                ),
                          ),
                        ),
                      ],
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

class LeadingIcon extends StatelessWidget {
  const LeadingIcon({
    super.key,
    required this.asset,
    required this.url,
    this.size,
  });

  final String? asset;
  final String? url;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final resolvedAsset = (asset ?? '').trim();
    final resolvedUrl = (url ?? '').trim();
    final iconSize = size ?? 34.w;

    // Prefer remote icon (when present) over any provided fallback asset.
    if (resolvedUrl.isNotEmpty) {
      return AppNetworkImage(
        url: resolvedUrl,
        width: iconSize,
        height: iconSize,
        fit: BoxFit.contain,
        showShimmer: false,
        placeholder: Center(
          child: Image.asset(
            FileConstants.loadingGif,
            width: iconSize * 0.7,
            height: iconSize * 0.7,
            fit: BoxFit.cover,
          ),
        ),
        errorWidget: _fallbackPlaceholder(context, iconSize),
      );
    }

    if (resolvedAsset.isNotEmpty) {
      return Image.asset(
        resolvedAsset,
        width: iconSize,
        height: iconSize,
        fit: BoxFit.contain,
      );
    }

    return _fallbackPlaceholder(context, iconSize);
  }

  Widget _fallbackPlaceholder(BuildContext context, double iconSize) {
    return Container(
      width: iconSize,
      height: iconSize,
      color: AppColors.white,
      child: Icon(
        Icons.broken_image_outlined,
        color: AppColors.textPrimary.withOpacity(0.5),
        size: iconSize * 0.7,
      ),
    );
  }
}
