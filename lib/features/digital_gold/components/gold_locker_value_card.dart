import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/file_constants.dart';

class GoldLockerValueCard extends StatelessWidget {
  const GoldLockerValueCard({
    super.key,
    required this.value,
    required this.changeText,
    required this.investedText,
    required this.subtitle,
    required this.backgroundGradient,
    this.designTint = const Color(0xFFE3B256),
  });

  final String value;
  final String changeText;
  final String investedText;
  final String subtitle;
  final Gradient backgroundGradient;
  final Color designTint;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
        borderRadius: BorderRadius.circular(18.r),
        child: Container(
          height: 150.w,
          width: double.infinity,
          decoration: BoxDecoration(gradient: backgroundGradient),
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                child: Image.asset(
                  FileConstants.designTopLeft,
                  width: 90.w,
                  fit: BoxFit.contain,
                  color: designTint,
                  colorBlendMode: BlendMode.srcIn,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Image.asset(
                  FileConstants.designBottomRight,
                  width: 90.w,
                  fit: BoxFit.contain,
                  color: designTint,
                  colorBlendMode: BlendMode.srcIn,
                ),
              ),
              Center(
                child: Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                  child: SizedBox(
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Current Value',
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          value,
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .displaySmall
                              ?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          changeText,
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: const Color(0xFF1D8E3A),
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        SizedBox(height: 10.h),
                        Text(
                          investedText,
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          subtitle,
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: AppColors.textPrimary.withOpacity(0.7),
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ));
  }
}
