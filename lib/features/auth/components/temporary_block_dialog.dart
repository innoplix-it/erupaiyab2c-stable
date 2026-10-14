import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../config/temporary_block_debug_config.dart';
import '../../../constants/app_colors.dart';
import '../../../widgets/custom_elevated_button.dart';
import 'auth_step_parts.dart';

class TemporaryBlockDialog extends StatelessWidget {
  const TemporaryBlockDialog({
    super.key,
    required this.flowType,
    required this.onPrimaryTap,
    required this.onSupportTap,
  });

  final TemporaryBlockFlowType flowType;
  final VoidCallback onPrimaryTap;
  final VoidCallback onSupportTap;

  @override
  Widget build(BuildContext context) {
    final primaryLabel = flowType == TemporaryBlockFlowType.noKyc
        ? 'Complete KYC'
        : 'Verify now';
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 24.h),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24.r),
        ),
        // Scrolls on short phones / large text instead of overflowing.
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20.w, 22.h, 20.w, 20.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 68.r,
                height: 68.r,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF1F1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.block,
                  color: const Color(0xFFDA291C),
                  size: 34.r,
                ),
              ),
              SizedBox(height: 14.h),
              Text(
                'Account Temporarily Blocked',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              SizedBox(height: 8.h),
              Text(
                'For your security, your account has been temporarily blocked due to verification requirements. Please complete your KYC/re-KYC process to restore access and continue using our services.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textPrimary.withValues(alpha: 0.72),
                      height: 1.45,
                    ),
              ),
              SizedBox(height: 18.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onSupportTap,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22.r),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 11.h),
                      ),
                      child: const Text('Contact Support'),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: AuthButtonTheme(
                      child: CustomElevatedButton(
                        onPressed: onPrimaryTap,
                        label: primaryLabel,
                        showArrow: false,
                        height: authButtonHeight(context, fraction: 40 / 360),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
