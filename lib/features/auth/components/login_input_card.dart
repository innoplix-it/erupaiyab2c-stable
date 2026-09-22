// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../constants/app_colors.dart';
import '../../../widgets/custom_elevated_button.dart';
import '../../../widgets/grey_text_form_field.dart';
import 'pin_input_row.dart';

class LoginInputCard extends StatelessWidget {
  const LoginInputCard({
    super.key,
    required this.phoneController,
    required this.pinControllers,
    required this.pinFocusNodes,
    required this.onContinue,
    this.onForgotPin,
    this.enabled = true,
  });

  final TextEditingController phoneController;
  final List<TextEditingController> pinControllers;
  final List<FocusNode> pinFocusNodes;
  final VoidCallback? onContinue;
  final VoidCallback? onForgotPin;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 30.r,
            offset: Offset(0.w, 14.h),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome Back',
              textAlign: TextAlign.left,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 20.sp,
                    color: AppColors.textPrimary,
                  ),
            ),
            SizedBox(height: 4.h),
            Text(
              'Log in to continue earning rewards.',
              textAlign: TextAlign.left,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textPrimary.withOpacity(0.6),
                  ),
            ),
            SizedBox(height: 14.h),
            Text(
              'Enter Mobile Number',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
            ),
            SizedBox(height: 6.h),
            GreyTextFormField(
              controller: phoneController,
              enabled: enabled,
              isNumber: true,
              validator: (value) {
                final trimmed = value?.trim() ?? '';
                if (trimmed.isEmpty) {
                  return 'Please enter mobile number';
                }
                if (trimmed.length != 10) {
                  return 'Enter 10-digit mobile number';
                }
                return null;
              },
            ),
            SizedBox(height: 14.h),
            Text(
              'Enter PIN',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
            ),
            SizedBox(height: 6.h),
            PinInputRow(
              controllers: pinControllers,
              focusNodes: pinFocusNodes,
              enabled: enabled,
            ),
            SizedBox(height: 8.h),
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: onForgotPin,
                child: Text(
                  'Forgot PIN ?',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                ),
              ),
            ),
            SizedBox(height: 18.h),
            CustomElevatedButton(
              onPressed: enabled ? onContinue : null,
              label: 'Continue',
            ),
          ],
        ),
      ),
    );
  }
}
