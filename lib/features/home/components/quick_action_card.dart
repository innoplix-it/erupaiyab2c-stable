// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/file_constants.dart';
import '../../../widgets/app_network_image.dart';

class QuickActionCard extends StatelessWidget {
  const QuickActionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.buttonLabel,
    this.imageAsset,
    this.imageUrl,
    this.onTap,
    this.showTail = true,
    this.showLeadingImage = true,
  });

  final String title;
  final String subtitle;
  final String amount;
  final String buttonLabel;
  final String? imageAsset;
  final String? imageUrl;
  final VoidCallback? onTap;
  final bool showTail;
  final bool showLeadingImage;

  @override
  Widget build(BuildContext context) {
    final hasSubtitle = subtitle.trim().isNotEmpty;
    final hasTailContent =
        amount.trim().isNotEmpty || buttonLabel.trim().isNotEmpty;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18.r),
          boxShadow: [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 18.r,
              offset: Offset(0.w, 8.h),
            ),
          ],
        ),
        child: Row(
          children: [
            if (showLeadingImage)
              Padding(
                padding: EdgeInsets.only(left: 14.w, top: 14.h, bottom: 14.h),
                child: imageUrl != null
                    ? AppNetworkImage(
                        url: imageUrl,
                        height: 56.r,
                        width: 56.r,
                        fit: BoxFit.contain,
                        borderRadius: BorderRadius.circular(16.r),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(16.r),
                        child: Image.asset(
                          imageAsset ?? FileConstants.mahavitaran,
                          height: 56.r,
                          width: 56.r,
                          fit: BoxFit.cover,
                        ),
                      ),
              ),
            SizedBox(width: 12.w),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 6.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: hasSubtitle
                      ? MainAxisAlignment.start
                      : MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                    ),
                    if (hasSubtitle) ...[
                      SizedBox(height: 4.h),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textPrimary.withOpacity(0.65),
                            ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (showTail)
              ClipRRect(
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(18.r),
                  bottomRight: Radius.circular(18.r),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.asset(
                      FileConstants.quickAction,
                      height: 84.h,
                      fit: BoxFit.cover,
                    ),
                    if (hasTailContent)
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            amount,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            buttonLabel,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: Colors.white,
                                  letterSpacing: 0.6,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      )
                    else
                      Icon(
                        Icons.arrow_forward,
                        color: Colors.white,
                        size: 30.r,
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
