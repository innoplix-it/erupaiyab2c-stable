// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../constants/app_colors.dart';
import '../../../widgets/custom_elevated_button.dart';
import 'otp_digit_box.dart';

class OtpVerificationCard extends StatelessWidget {
  const OtpVerificationCard({
    super.key,
    required this.controllers,
    required this.focusNodes,
    required this.onVerify,
    required this.onResend,
    required this.timerText,
    this.errorMessage,
    this.isVerifying = false,
    this.canResend = false,
    this.onInputChanged,
  }) : assert(controllers.length == focusNodes.length);

  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final VoidCallback? onVerify;
  final VoidCallback? onResend;
  final String timerText;
  final String? errorMessage;
  final bool isVerifying;
  final bool canResend;
  final VoidCallback? onInputChanged;

  @override
  Widget build(BuildContext context) {
    final hasError = errorMessage != null && errorMessage!.isNotEmpty;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28.r),
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 35.r,
            offset: Offset(0.w, 16.h),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Verify Your OTP',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
            ),
            SizedBox(height: 16.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(controllers.length, (index) {
                final isFilled = controllers[index].text.isNotEmpty;
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  child: OtpDigitBox(
                    controller: controllers[index],
                    focusNode: focusNodes[index],
                    isFilled: isFilled,
                    isError: hasError,
                    onChanged: (value) {
                      onInputChanged?.call();
                      if (value.isEmpty && index > 0) {
                        focusNodes[index - 1].requestFocus();
                      } else if (value.isNotEmpty &&
                          index < focusNodes.length - 1) {
                        focusNodes[index + 1].requestFocus();
                      }
                    },
                  ),
                );
              }),
            ),
            if (hasError) ...[
              SizedBox(height: 12.h),
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.red.shade700, fontWeight: FontWeight.w600),
              ),
            ],
            SizedBox(height: 12.h),
            Row(
              children: [
                Icon(Icons.access_time,
                    size: 18.r, color: AppColors.textPrimary),
                SizedBox(width: 6.w),
                Text(
                  timerText,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: canResend ? onResend : null,
                  style: TextButton.styleFrom(
                    foregroundColor: canResend
                        ? AppColors.primary
                        : AppColors.textPrimary.withOpacity(0.35),
                  ),
                  child: const Text(
                    'Resend OTP',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.h),
            CustomElevatedButton(
              onPressed: isVerifying ? null : onVerify,
              label: isVerifying ? 'Verifying...' : 'Verify',
              showArrow: false,
            ),
          ],
        ),
      ),
    );
  }
}
