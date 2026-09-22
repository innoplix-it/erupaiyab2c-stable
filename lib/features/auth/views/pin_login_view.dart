// ignore_for_file: deprecated_member_use

import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:pinput/pinput.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/file_constants.dart';
import '../../../constants/routes_constant.dart';
import '../../../widgets/app_snackbar.dart';
import '../../../widgets/custom_elevated_button.dart';
import '../../profile/controllers/profile_controller.dart';
import '../components/auth_brand_header.dart';
import '../components/login_input_card.dart';
import '../controllers/auth_controller.dart';
import '../utils/temporary_block_flow_launcher.dart';

class PinLoginView extends HookConsumerWidget {
  const PinLoginView({super.key});
  static const int _forgotOtpLength = 6;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);

    final phoneController = useTextEditingController();
    final pinControllers = List.generate(4, (_) => useTextEditingController());
    final pinFocusNodes = List.generate(4, (_) => useFocusNode());
    final showForgotPin = useState(false);
    final forgotOtpController = useTextEditingController();
    final forgotPinController = useTextEditingController();
    final forgotConfirmController = useTextEditingController();
    final forgotRemainingSeconds = useState(0);
    final forgotTimerRef = useRef<Timer?>(null);
    final isRequestingOtp = useState(false);

    useEffect(() {
      return () {
        forgotTimerRef.value?.cancel();
        forgotOtpController.dispose();
        forgotPinController.dispose();
        forgotConfirmController.dispose();
      };
    }, const []);

    Future<void> handleLogin() async {
      final phone = phoneController.text.trim();
      if (phone.isEmpty || phone.length != 10) {
        AppSnackbar.show('Enter a valid 10-digit mobile number');
        return;
      }
      final pin = pinControllers.map((c) => c.text).join();
      if (pin.length != 4) {
        AppSnackbar.show('Please enter a 4-digit PIN');
        return;
      }
      final result = await ref
          .read(authControllerProvider.notifier)
          .login(mobile: phone, pin: pin);
      if (result.isSuccess) {
        await ref
            .read(profileControllerProvider.notifier)
            .fetchProfileIfNeeded(force: true);
        if (context.mounted) {
          context.go(RouteConstants.home);
        }
      } else if (result.requiresDeviceVerification) {
        for (final controller in pinControllers) {
          controller.clear();
        }
        pinFocusNodes.first.requestFocus();
        if (!context.mounted) return;
        await launchNewDeviceVerificationFlow(
          context: context,
          phoneNumber: phone,
          verificationId: result.verificationId ?? '',
        );
      } else if (result.isSuspected) {
        for (final controller in pinControllers) {
          controller.clear();
        }
        pinFocusNodes.first.requestFocus();
        if (!context.mounted) return;
        await launchTemporaryBlockedFlow(
          context: context,
          phoneNumber: phone,
          isKycVerified: result.isKycVerified == true,
        );
      } else {
        final latestState = ref.read(authControllerProvider);
        AppSnackbar.show(
          result.message ??
              latestState.errorMessage ??
              'Login failed. Please try again.',
        );
      }
    }

    Future<void> handleForgotPinOpen() async {
      final phone = phoneController.text.trim();
      if (phone.isEmpty || phone.length != 10) {
        AppSnackbar.show('Enter a valid 10-digit mobile number');
        return;
      }
      if (isRequestingOtp.value) return;
      isRequestingOtp.value = true;
      final flow = await ref
          .read(authControllerProvider.notifier)
          .checkLogin(mobile: phone);
      if (flow == null) {
        isRequestingOtp.value = false;
        AppSnackbar.show(
          ref.read(authControllerProvider).errorMessage ??
              'Unable to verify mobile number.',
        );
        return;
      }
      final message = await ref
          .read(authControllerProvider.notifier)
          .requestForgotPinOtp(mobile: phone);
      isRequestingOtp.value = false;
      if (!context.mounted) return;
      if (message == null) {
        AppSnackbar.show(
          ref.read(authControllerProvider).errorMessage ??
              'Failed to request OTP.',
        );
        return;
      }
      AppSnackbar.show(message);
      showForgotPin.value = true;
      forgotRemainingSeconds.value = 60;
      forgotTimerRef.value?.cancel();
      forgotTimerRef.value =
          Timer.periodic(const Duration(seconds: 1), (timer) {
        if (forgotRemainingSeconds.value <= 1) {
          forgotRemainingSeconds.value = 0;
          timer.cancel();
        } else {
          forgotRemainingSeconds.value -= 1;
        }
      });
    }

    Future<void> handleForgotResend() async {
      if (forgotRemainingSeconds.value > 0 || isRequestingOtp.value) return;
      final message = await ref
          .read(authControllerProvider.notifier)
          .requestForgotPinOtp(mobile: phoneController.text.trim());
      if (message == null) {
        AppSnackbar.show(
          ref.read(authControllerProvider).errorMessage ??
              'Failed to request OTP.',
        );
        return;
      }
      AppSnackbar.show(message);
      forgotRemainingSeconds.value = 60;
      forgotTimerRef.value?.cancel();
      forgotTimerRef.value =
          Timer.periodic(const Duration(seconds: 1), (timer) {
        if (forgotRemainingSeconds.value <= 1) {
          forgotRemainingSeconds.value = 0;
          timer.cancel();
        } else {
          forgotRemainingSeconds.value -= 1;
        }
      });
    }

    Future<void> handleForgotVerify() async {
      final otp = forgotOtpController.text.trim();
      final pin = forgotPinController.text.trim();
      final confirmPin = forgotConfirmController.text.trim();
      if (otp.length != _forgotOtpLength) {
        AppSnackbar.show('Please enter the $_forgotOtpLength-digit OTP.');
        return;
      }
      if (pin.length != 4) {
        AppSnackbar.show('Please enter a 4-digit PIN.');
        return;
      }
      if (confirmPin.length != 4) {
        AppSnackbar.show('Please confirm your 4-digit PIN.');
        return;
      }
      if (pin != confirmPin) {
        AppSnackbar.show('PIN and confirm PIN do not match.');
        return;
      }
      final message = await ref
          .read(authControllerProvider.notifier)
          .forgotPin(otp: otp, pin: pin);
      if (!context.mounted) return;
      if (message == null) {
        AppSnackbar.show(
          ref.read(authControllerProvider).errorMessage ??
              'Failed to reset PIN.',
        );
        return;
      }
      AppSnackbar.show(message);
      showForgotPin.value = false;
      forgotTimerRef.value?.cancel();
      forgotRemainingSeconds.value = 0;
      forgotOtpController.clear();
      forgotPinController.clear();
      forgotConfirmController.clear();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final headerHeight = constraints.maxHeight * 0.62;

          return Stack(
            children: [
              Column(
                children: [
                  Container(
                    height: headerHeight,
                    decoration: BoxDecoration(
                      gradient: AppColors.authBackgroundGradient,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(20.r),
                        bottomRight: Radius.circular(20.r),
                      ),
                    ),
                  ),
                  const Expanded(
                    child: ColoredBox(color: Colors.white),
                  ),
                ],
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: headerHeight,
                child: const AuthBrandHeader(),
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 24,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.w),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!showForgotPin.value)
                        LoginInputCard(
                          phoneController: phoneController,
                          pinControllers: pinControllers,
                          pinFocusNodes: pinFocusNodes,
                          onContinue: handleLogin,
                          onForgotPin: handleForgotPinOpen,
                          enabled: !authState.isSubmitting,
                        )
                      else
                        _ForgotPinCard(
                          otpController: forgotOtpController,
                          pinController: forgotPinController,
                          confirmPinController: forgotConfirmController,
                          remainingSeconds: forgotRemainingSeconds.value,
                          isSubmitting: authState.isSubmitting,
                          isRequestingOtp: isRequestingOtp.value,
                          onResend: handleForgotResend,
                          onVerify: handleForgotVerify,
                          onBack: () {
                            showForgotPin.value = false;
                            forgotTimerRef.value?.cancel();
                            forgotRemainingSeconds.value = 0;
                            forgotOtpController.clear();
                            forgotPinController.clear();
                            forgotConfirmController.clear();
                          },
                        ),
                      SizedBox(height: 18.h),
                      if (!showForgotPin.value)
                        Text.rich(
                          TextSpan(
                            text: "Don\u2019t Have an account ? ",
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                            children: [
                              TextSpan(
                                text: 'Register',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  decoration: TextDecoration.underline,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    context.go(RouteConstants.register);
                                  },
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ForgotPinCard extends StatelessWidget {
  const _ForgotPinCard({
    required this.otpController,
    required this.pinController,
    required this.confirmPinController,
    required this.remainingSeconds,
    required this.isSubmitting,
    required this.isRequestingOtp,
    required this.onResend,
    required this.onVerify,
    required this.onBack,
  });

  final TextEditingController otpController;
  final TextEditingController pinController;
  final TextEditingController confirmPinController;
  final int remainingSeconds;
  final bool isSubmitting;
  final bool isRequestingOtp;
  final VoidCallback onResend;
  final VoidCallback onVerify;
  final VoidCallback onBack;

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Image.asset(
                FileConstants.erupaiyaLogo,
                width: 60.w,
                height: 60.w,
              ),
            ),
            SizedBox(height: 14.h),
            Text(
              'Reset Your PIN',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
            ),
            SizedBox(height: 6.h),
            Text(
              'Enter the 6-digit OTP sent to your mobile number.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textPrimary.withOpacity(0.6),
                  ),
            ),
            SizedBox(height: 12.h),
            _ForgotPinInput(
              controller: otpController,
              length: PinLoginView._forgotOtpLength,
            ),
            SizedBox(height: 10.h),
            Row(
              children: [
                Icon(Icons.access_time,
                    size: 18.r, color: AppColors.textPrimary),
                SizedBox(width: 6.w),
                Text(
                  '${(remainingSeconds ~/ 60).toString().padLeft(2, '0')}:${(remainingSeconds % 60).toString().padLeft(2, '0')}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: remainingSeconds == 0 && !isRequestingOtp
                      ? onResend
                      : null,
                  style: TextButton.styleFrom(
                    foregroundColor: remainingSeconds == 0
                        ? AppColors.primary
                        : AppColors.textPrimary.withOpacity(0.35),
                  ),
                  child: Text(
                    isRequestingOtp ? 'Sending...' : 'Resend OTP',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Divider(color: AppColors.textPrimary.withOpacity(0.1)),
            SizedBox(height: 8.h),
            Text(
              'Create New PIN',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
            ),
            SizedBox(height: 8.h),
            _ForgotPinInput(
              controller: pinController,
              obscureText: true,
            ),
            SizedBox(height: 14.h),
            Text(
              'Confirm PIN',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
            ),
            SizedBox(height: 8.h),
            _ForgotPinInput(
              controller: confirmPinController,
              obscureText: true,
            ),
            SizedBox(height: 18.h),
            CustomElevatedButton(
              onPressed: isSubmitting ? null : onVerify,
              label: isSubmitting ? 'Verifying...' : 'Verify & Continue',
              uppercaseLabel: false,
              showArrow: false,
            ),
            SizedBox(height: 8.h),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onBack,
                child: const Text('Back'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ForgotPinInput extends StatelessWidget {
  const _ForgotPinInput({
    required this.controller,
    this.obscureText = false,
    this.length = 4,
  });

  final TextEditingController controller;
  final bool obscureText;
  final int length;

  @override
  Widget build(BuildContext context) {
    return Pinput(
      controller: controller,
      length: length,
      obscureText: obscureText,
      keyboardType: TextInputType.number,
      defaultPinTheme: PinTheme(
        width: 50.w,
        height: 52.h,
        textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: AppColors.lightBorder),
          color: Colors.white,
        ),
      ),
      focusedPinTheme: PinTheme(
        width: 50.w,
        height: 52.h,
        textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: AppColors.primary),
          color: Colors.white,
        ),
      ),
    );
  }
}
