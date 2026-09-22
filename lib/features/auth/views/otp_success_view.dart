// ignore_for_file: deprecated_member_use

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/file_constants.dart';
import '../../../constants/routes_constant.dart';
import '../../../widgets/custom_elevated_button.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class OtpSuccessView extends HookConsumerWidget {
  const OtpSuccessView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remainingSeconds = useState(5);
    useEffect(() {
      final timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        final nextValue = remainingSeconds.value - 1;
        remainingSeconds.value = nextValue;
        if (nextValue <= 0) {
          timer.cancel();
          if (context.mounted) {
            context.go(RouteConstants.addPin);
          }
        }
      });
      return timer.cancel;
    }, const []);

    return Scaffold(
      backgroundColor: Colors.white,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: AppColors.otpSuccessBackground,
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 48.h),
                Center(
                  child: Image.asset(
                    FileConstants.erupaiyaLogo,
                    height: 48.h,
                  ),
                ),
                SizedBox(height: 32.h),
                Text(
                  'OTP Verified Successfully',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                ),
                SizedBox(height: 12.h),
                Text(
                  'Your number has been verified.\nRedirecting you to the home page...',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimary.withOpacity(0.75),
                      ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Redirecting in ${remainingSeconds.value.clamp(0, 5)} sec',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textPrimary.withOpacity(0.7),
                      ),
                ),
                const Spacer(),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.black,
                      child: Icon(Icons.info_outline,
                          size: 16.r, color: Colors.white),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        'Protect your account and keep every transaction secure.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textPrimary,
                            ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20.h),
                CustomElevatedButton(
                  onPressed: () => context.go(RouteConstants.addPin),
                  label: 'Secure app',
                  showArrow: false,
                ),
                SizedBox(height: 24.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
