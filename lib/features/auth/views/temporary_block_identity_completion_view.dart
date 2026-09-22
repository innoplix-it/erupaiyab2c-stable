import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/file_constants.dart';
import '../../../constants/routes_constant.dart';
import '../../../widgets/app_snackbar.dart';
import '../../../widgets/custom_elevated_button.dart';
import '../../../widgets/grey_text_form_field.dart';
import '../../../widgets/k_dialog.dart';
import '../../profile/controllers/profile_controller.dart';
import '../controllers/auth_controller.dart';

class TemporaryBlockIdentityCompletionView extends HookConsumerWidget {
  const TemporaryBlockIdentityCompletionView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final profile = ref.watch(profileControllerProvider).profile;
    final panController = useTextEditingController(
      text: (profile?.panNo ?? '').trim(),
    );
    final aadhaarController = useTextEditingController(
      text: '',
    );

    Future<void> handleContinue() async {
      final pan = panController.text.trim().toUpperCase();
      final aadhaar = aadhaarController.text.replaceAll(RegExp(r'\s+'), '');
      final panRegExp = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$');

      if (!panRegExp.hasMatch(pan)) {
        AppSnackbar.show('Please enter a valid PAN number.');
        return;
      }
      if (aadhaar.length != 12 || int.tryParse(aadhaar) == null) {
        AppSnackbar.show('Please enter a valid 12 digit Aadhaar number.');
        return;
      }

      final message = await ref
          .read(authControllerProvider.notifier)
          .verifyAccountRecoveryKyc(
            panNo: pan,
            aadhaar: aadhaar,
          );
      if (message == null) {
        final latestState = ref.read(authControllerProvider);
        AppSnackbar.show(
          latestState.errorMessage ?? 'Something went wrong. Please try again.',
        );
        return;
      }

      await KDialog.instance.openDialog(
        barrierDismissible: false,
        dialog: _TemporaryBlockSuccessDialog(
          onContinue: () async {
            navigatorKey.currentState?.pop();
            await ref.read(authControllerProvider.notifier).logout();
            navigatorKey.currentContext?.go(RouteConstants.login);
          },
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Complete Identity Verification',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
        ),
        centerTitle: true,
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 0.h, 16.w, 18.h),
          child: CustomElevatedButton(
            onPressed: authState.isSubmitting ? null : handleContinue,
            label:
                authState.isSubmitting ? 'Verifying...' : 'Verify & Continue',
            uppercaseLabel: false,
            height: 42.h,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(
              FileConstants.resetPinIcon,
              height: 72.h,
              fit: BoxFit.contain,
            ),
            SizedBox(height: 18.h),
            Text(
              'Complete Identity Verification',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Verify your PAN and Aadhaar details to reactivate your account and continue using our services securely.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary.withValues(alpha: 0.72),
                    height: 1.45,
                  ),
            ),
            SizedBox(height: 18.h),
            Text(
              'PAN Number',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
            ),
            SizedBox(height: 6.h),
            GreyTextFormField(
              controller: panController,
              enabled: true,
              hintText: 'ABCDE1234F',
              centerText: false,
            ),
            SizedBox(height: 14.h),
            Text(
              'Aadhaar Number',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
            ),
            SizedBox(height: 6.h),
            GreyTextFormField(
              controller: aadhaarController,
              enabled: true,
              hintText: '1234 5678 9012',
              isNumber: true,
              centerText: false,
              maxLength: 14,
              inputFormatters: const [
                _AadhaarInputFormatter(),
              ],
            ),
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF6F2),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.verified_user_outlined,
                    size: 18.r,
                    color: const Color(0xFFE85A2C),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'Your information is encrypted and securely processed for verification purposes only.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                AppColors.textPrimary.withValues(alpha: 0.68),
                            height: 1.4,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AadhaarInputFormatter extends TextInputFormatter {
  const _AadhaarInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final trimmed = digits.length > 12 ? digits.substring(0, 12) : digits;

    final buffer = StringBuffer();
    for (var index = 0; index < trimmed.length; index++) {
      if (index > 0 && index % 4 == 0) {
        buffer.write(' ');
      }
      buffer.write(trimmed[index]);
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _TemporaryBlockSuccessDialog extends StatelessWidget {
  const _TemporaryBlockSuccessDialog({required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24.r),
      ),
      insetPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
      child: Padding(
        padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 22.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64.r,
              height: 64.r,
              decoration: const BoxDecoration(
                color: Color(0xFF1B8E36),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check, color: Colors.white, size: 34.r),
            ),
            SizedBox(height: 14.h),
            Text(
              'Account Verification Successful',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Your PAN and Aadhaar details have been successfully verified. Your account has been reactivated, and you can now securely access all services.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textPrimary.withValues(alpha: 0.72),
                    height: 1.45,
                  ),
            ),
            SizedBox(height: 18.h),
            CustomElevatedButton(
              onPressed: onContinue,
              label: 'Continue to Login',
              showArrow: false,
              height: 40.h,
            ),
          ],
        ),
      ),
    );
  }
}
