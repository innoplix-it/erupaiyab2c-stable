import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../constants/app_colors.dart';
import '../../../widgets/custom_elevated_button.dart';

class NewDeviceVerificationDialog extends StatelessWidget {
  const NewDeviceVerificationDialog({
    super.key,
    required this.onPrimaryTap,
  });

  final VoidCallback onPrimaryTap;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 24.h),
      child: Container(
        padding: EdgeInsets.fromLTRB(20.w, 22.h, 20.w, 20.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 82.r,
              height: 82.r,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.account_circle,
                color: const Color(0xFFB40000),
                size: 82.r,
              ),
            ),
            SizedBox(height: 14.h),
            Text(
              'New Device Login Detected',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            SizedBox(height: 8.h),
            Text(
              'We noticed a login attempt to your account from a new device. For your security, please verify your identity before continuing.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textPrimary.withValues(alpha: 0.78),
                    height: 1.45,
                  ),
            ),
            SizedBox(height: 20.h),
            CustomElevatedButton(
              onPressed: onPrimaryTap,
              label: 'Verify Now',
              showArrow: false,
              height: 40.h,
            ),
          ],
        ),
      ),
    );
  }
}
