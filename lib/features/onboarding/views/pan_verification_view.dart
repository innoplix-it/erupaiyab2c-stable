// ignore_for_file: deprecated_member_use

import 'package:e_rupaiya/constants/file_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/routes_constant.dart';
import '../../../widgets/custom_elevated_button.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PanVerificationView extends HookConsumerWidget {
  const PanVerificationView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        context.go(RouteConstants.kycVerification);
      });
      return null;
    }, const []);

    return Scaffold(
      backgroundColor: Colors.white,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: AppColors.onboardingBackground,
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PAN Verification',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'To use e-Rupaiya and earn rewards, please complete your KYC.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textPrimary.withOpacity(0.8),
                      ),
                ),
                SizedBox(height: 24.h),
                Center(
                  child: Image.asset(
                    FileConstants.pan,
                    height: 64.r,
                    width: 64.r,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 20.h),
                Text(
                  'This screen has been replaced with the secure KYC verification flow.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimary.withOpacity(0.75),
                      ),
                ),
                SizedBox(height: 12.h),
                Text(
                  'Redirecting you now.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textPrimary.withOpacity(0.6),
                      ),
                ),
                const Spacer(),
                CustomElevatedButton(
                  onPressed: () => context.go(RouteConstants.kycVerification),
                  label: 'Open Secure KYC',
                  showArrow: false,
                  uppercaseLabel: false,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
