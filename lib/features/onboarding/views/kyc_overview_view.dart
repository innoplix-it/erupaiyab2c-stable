// ignore_for_file: deprecated_member_use

import 'package:e_rupaiya/constants/file_constants.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/routes_constant.dart';
import '../../../widgets/custom_elevated_button.dart';
import '../components/kyc_action_tile.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class KycOverviewView extends HookConsumerWidget {
  const KycOverviewView({super.key, this.selectedLanguage});

  final String? selectedLanguage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void navigateToRealKyc() {
      context.go(RouteConstants.kycVerification);
    }

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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Verify KYC Details',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                    ),
                    const SizedBox.shrink(),
                  ],
                ),
                SizedBox(height: 8.h),
                Text(
                  'To use e-Rupaiya and earn rewards, please complete your KYC.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textPrimary.withOpacity(0.8),
                      ),
                ),
                // if (selectedLanguage != null) ...[
                //   SizedBox(height: 6.h),
                //   Text(
                //     'Selected language: $selectedLanguage',
                //     style: Theme.of(context).textTheme.bodySmall?.copyWith(
                //           color: AppColors.textPrimary.withOpacity(0.7),
                //         ),
                //   ),
                // ],
                SizedBox(height: 24.h),
                Expanded(
                  child: ListView(
                    children: [
                      KycActionTile(
                        title: 'PAN Card Verification',
                        iconAsset: FileConstants.pan,
                        onTap: navigateToRealKyc,
                      ),
                      SizedBox(height: 14.h),
                      KycActionTile(
                        title: 'Aadhaar Verification',
                        iconAsset: FileConstants.aadhaar,
                        onTap: navigateToRealKyc,
                      ),
                    ],
                  ),
                ),
                CustomElevatedButton(
                  onPressed: navigateToRealKyc,
                  label: 'Continue',
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
