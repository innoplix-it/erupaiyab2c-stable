import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../widgets/custom_elevated_button.dart';

class DigitalGoldTradeSuccessV2View extends StatelessWidget {
  const DigitalGoldTradeSuccessV2View({
    super.key,
    required this.title,
    this.subtitle,
    this.details,
    required this.primaryCtaLabel,
    required this.onPrimaryCta,
    this.secondaryCtaLabel,
    this.onSecondaryCta,
  });

  final String title;
  final String? subtitle;
  final Widget? details;
  final String primaryCtaLabel;
  final VoidCallback onPrimaryCta;
  final String? secondaryCtaLabel;
  final VoidCallback? onSecondaryCta;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.help_outline_rounded),
                  ),
                ],
              ),
            ),
            SizedBox(height: 8.h),
            Container(
              width: 64.r,
              height: 64.r,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF0B8A3B),
              ),
              child: Icon(Icons.check, color: Colors.white, size: 32.r),
            ),
            SizedBox(height: 14.h),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
            ),
            if ((subtitle ?? '').trim().isNotEmpty) ...[
              SizedBox(height: 8.h),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.black.withOpacity(0.6),
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
              ),
            ],
            if (details != null) ...[
              SizedBox(height: 16.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 18.w),
                child: details!,
              ),
            ],
            SizedBox(height: 14.h),
            if ((secondaryCtaLabel ?? '').trim().isNotEmpty)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 18.w),
                child: CustomElevatedButton(
                  onPressed: onSecondaryCta,
                  label: secondaryCtaLabel!,
                  uppercaseLabel: false,
                  height: 46.h,
                  backgroundColor: Colors.white,
                  borderColor: const Color(0xFFE85A2C),
                  labelColor: const Color(0xFFE85A2C),
                ),
              ),
            const Spacer(),
            Padding(
              padding: EdgeInsets.fromLTRB(18.w, 8.h, 18.w, 16.h),
              child: CustomElevatedButton(
                onPressed: onPrimaryCta,
                label: primaryCtaLabel,
                uppercaseLabel: false,
                height: 46.h,
                backgroundColor: const Color(0xFFE85A2C),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
