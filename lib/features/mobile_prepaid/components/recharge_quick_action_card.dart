// ignore_for_file: deprecated_member_use

import 'package:e_rupaiya/constants/app_colors.dart';
import 'package:e_rupaiya/core/barrel_file.dart';
import 'package:e_rupaiya/features/home/components/quick_action_header_card.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
  });

  final String title;
  final String subtitle;
  final String? leadingAsset;
  final String? leadingImageUrl;
  final VoidCallback? onTap;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool showShadow;

  @override
  Widget build(BuildContext context) {
    final hasAction = (actionLabel ?? '').trim().isNotEmpty;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22.r),
      child: Container(
        width: double.infinity,
        height: 56.h,
        padding: EdgeInsets.symmetric(horizontal: 14.w),
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
              width: 42.w,
              height: 38.h,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (title.trim().isNotEmpty)
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600,
                        fontSize: 13.sp,
                        color: const Color(0xFF000000),
                      ),
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
                  width: 60.w,
                  height: 22.h,
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
  });

  final String? asset;
  final String? url;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? 50.w,
      height: height ?? 45.h,
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: const Color(0xFFE2E2E2),
          width: 1.w,
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
