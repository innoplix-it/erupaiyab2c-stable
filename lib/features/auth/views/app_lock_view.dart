// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:ui';

import 'package:e_rupaiya/widgets/custom_elevated_button.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:pinput/pinput.dart';

import '../../../config/app_env.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/file_constants.dart';
import '../../../constants/routes_constant.dart';
import '../../../services/logger_service.dart';
import '../../../services/secure_storage_service.dart';
import '../../../widgets/app_snackbar.dart';
import '../../profile/controllers/profile_controller.dart';
import '../controllers/auth_controller.dart';

void _debugLog(String message) {
  if (!AppEnv.enableLogs || !kDebugMode) return;
  debugPrint(message);
}

class AppLockView extends HookConsumerWidget {
  const AppLockView({super.key});
  static const String _genericErrorMessage =
      'Something went wrong. Please try again.';
  static const int _forgotOtpLength = 4;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final pinController = useTextEditingController();
    final pinFocusNode = useFocusNode();
    final forgotOtpController = useTextEditingController();
    final forgotPinController = useTextEditingController();
    final forgotConfirmController = useTextEditingController();
    final isLoading = useState(true);
    final isUnlocking = useState(false);
    final mobile = useState<String?>(null);
    final biometricAvailable = useState(false);
    final localAuth = useMemoized(() => LocalAuthentication());
    final biometricPrompted = useRef(false);
    final showForgotPin = useState(false);
    final forgotRemainingSeconds = useState(0);
    final forgotTimerRef = useRef<Timer?>(null);
    final isRequestingOtp = useState(false);

    useEffect(() {
      return () {
        pinController.dispose();
        pinFocusNode.dispose();
        forgotOtpController.dispose();
        forgotPinController.dispose();
        forgotConfirmController.dispose();
      };
    }, const []);

    useEffect(() {
      Future.microtask(() async {
        const storage = SecureStorageService.instance;
        final storedMobile = await storage.read(key: 'mobile');
        final canCheck = await localAuth.canCheckBiometrics;
        final isDeviceSupported = await localAuth.isDeviceSupported();
        final enrolled = await localAuth.getAvailableBiometrics();
        biometricAvailable.value =
            canCheck && isDeviceSupported && enrolled.isNotEmpty;
        _debugLog(
          'Biometric checks: canCheck=$canCheck supported=$isDeviceSupported enrolled=${enrolled.length}',
        );
        if (storedMobile == null || storedMobile.isEmpty) {
          await ref.read(authControllerProvider.notifier).logout();
          if (context.mounted) {
            context.go(RouteConstants.login);
          }
          return;
        }
        mobile.value = storedMobile;
        isLoading.value = false;
      });
      return null;
    }, const []);

    Future<void> handleBiometric() async {
      if (!biometricAvailable.value) return;
      try {
        final didAuth = await localAuth.authenticate(
          localizedReason: 'Unlock with biometrics',
          options: const AuthenticationOptions(
            biometricOnly: true,
            stickyAuth: true,
          ),
        );
        if (didAuth && context.mounted) {
          Navigator.of(context).pop();
        }
      } catch (e, stackTrace) {
        logger.error('Biometric authentication failed',
            error: e, stackTrace: stackTrace);
        AppSnackbar.show(_genericErrorMessage);
      }
    }

    useEffect(() {
      if (isLoading.value) return null;
      if (!biometricAvailable.value) return null;
      if (showForgotPin.value) return null;
      if (biometricPrompted.value) return null;
      biometricPrompted.value = true;
      Future.microtask(handleBiometric);
      return null;
    }, [isLoading.value, biometricAvailable.value, showForgotPin.value]);

    Future<void> handleUnlock() async {
      if (isUnlocking.value) return;
      final pin = pinController.text.trim();
      if (pin.length != 4) {
        AppSnackbar.show('Please enter a 4-digit PIN');
        return;
      }
      final phone = mobile.value ?? '';
      if (phone.isEmpty) {
        AppSnackbar.show('Missing mobile number. Please login again.');
        await ref.read(authControllerProvider.notifier).logout();
        if (context.mounted) {
          context.go(RouteConstants.login);
        }
        return;
      }
      isUnlocking.value = true;
      final success = await ref.read(authControllerProvider.notifier).pinLock(
            mobile: phone,
            pin: pin,
          );
      isUnlocking.value = false;
      if (success) {
        await ref
            .read(profileControllerProvider.notifier)
            .fetchProfileIfNeeded(force: true);
        if (context.mounted) {
          Navigator.of(context).pop();
        }
      } else {
        AppSnackbar.show(
          ref.read(authControllerProvider).errorMessage ??
              'Invalid PIN. Try again.',
        );
        pinController.clear();
        pinFocusNode.requestFocus();
      }
    }

    Future<void> requestForgotOtp() async {
      if (isRequestingOtp.value) return;
      isRequestingOtp.value = true;
      final message =
          await ref.read(authControllerProvider.notifier).requestForgotPinOtp();
      isRequestingOtp.value = false;
      if (!context.mounted) return;
      if (message != null) {
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
      } else {
        AppSnackbar.show(
          ref.read(authControllerProvider).errorMessage ??
              'Failed to request OTP.',
        );
      }
    }

    Future<void> handleForgotResend() async {
      if (forgotRemainingSeconds.value > 0) return;
      await requestForgotOtp();
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
      if (message != null) {
        AppSnackbar.show(message);
        showForgotPin.value = false;
        forgotOtpController.clear();
        forgotPinController.clear();
        forgotConfirmController.clear();
      } else {
        AppSnackbar.show(
          ref.read(authControllerProvider).errorMessage ??
              'Failed to reset PIN.',
        );
      }
    }

    useEffect(() {
      if (!showForgotPin.value) return null;
      Future.microtask(requestForgotOtp);
      return () {
        forgotTimerRef.value?.cancel();
      };
    }, [showForgotPin.value]);

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: !showForgotPin.value,
        body: SafeArea(
          child: Stack(
            fit: StackFit.expand,
            children: [
              isLoading.value
                  ? const Center(
                      child: SpinKitCircle(
                        color: AppColors.primary,
                        size: 48,
                      ),
                    )
                  : Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: 24.w, vertical: 20.h),
                      child: AnimatedPadding(
                        duration: const Duration(milliseconds: 150),
                        curve: Curves.easeOut,
                        padding: EdgeInsets.only(
                          bottom: showForgotPin.value
                              ? MediaQuery.of(context).viewInsets.bottom
                              : 0,
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              SizedBox(height: 16.h),
                              Image.asset(
                                FileConstants.erupaiyaLogo,
                                width: 70.w,
                                height: 70.w,
                              ),
                              SizedBox(height: 14.h),
                              Text(
                                'Please Enter Your Security Pin',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                              ),
                              SizedBox(height: 18.h),
                              if (!showForgotPin.value) ...[
                                _AppLockPinInput(
                                  controller: pinController,
                                  focusNode: pinFocusNode,
                                  enabled: !isUnlocking.value,
                                  obscure: true,
                                  onCompleted: (_) => handleUnlock(),
                                ),
                                SizedBox(height: 12.h),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () => showForgotPin.value = true,
                                    child: Text(
                                      'Forgot PIN ?',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPrimary,
                                          ),
                                    ),
                                  ),
                                ),
                              ] else ...[
                                Text(
                                  'Reset Your PIN',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                ),
                                SizedBox(height: 6.h),
                                Text(
                                  'Enter the 4-digit OTP sent to your mobile number.',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: AppColors.textPrimary
                                            .withOpacity(0.6),
                                      ),
                                ),
                                SizedBox(height: 12.h),
                                _AppLockPinInput(
                                  controller: forgotOtpController,
                                  enabled: !authState.isSubmitting,
                                  length: AppLockView._forgotOtpLength,
                                  onCompleted: (_) {},
                                ),
                                SizedBox(height: 10.h),
                                Row(
                                  children: [
                                    Icon(Icons.access_time,
                                        size: 18.r, color: AppColors.textPrimary),
                                    SizedBox(width: 6.w),
                                    Text(
                                      '${(forgotRemainingSeconds.value ~/ 60).toString().padLeft(2, '0')}:${(forgotRemainingSeconds.value % 60).toString().padLeft(2, '0')}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPrimary,
                                          ),
                                    ),
                                    const Spacer(),
                                    TextButton(
                                      onPressed:
                                          forgotRemainingSeconds.value == 0 &&
                                                  !isRequestingOtp.value
                                              ? handleForgotResend
                                              : null,
                                      style: TextButton.styleFrom(
                                        foregroundColor:
                                            forgotRemainingSeconds.value == 0
                                                ? AppColors.primary
                                                : AppColors.textPrimary
                                                    .withOpacity(0.35),
                                      ),
                                      child: Text(
                                        isRequestingOtp.value
                                            ? 'Sending...'
                                            : 'Resend OTP',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8.h),
                                Divider(
                                  color: AppColors.textPrimary.withOpacity(0.1),
                                ),
                                SizedBox(height: 8.h),
                                Text(
                                  'Create New PIN',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                ),
                                SizedBox(height: 8.h),
                                _AppLockPinInput(
                                  controller: forgotPinController,
                                  enabled: !authState.isSubmitting,
                                  obscure: true,
                                  onCompleted: (_) {},
                                ),
                                SizedBox(height: 14.h),
                                Text(
                                  'Confirm PIN',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                ),
                                SizedBox(height: 8.h),
                                _AppLockPinInput(
                                  controller: forgotConfirmController,
                                  enabled: !authState.isSubmitting,
                                  obscure: true,
                                  onCompleted: (_) {},
                                ),
                                SizedBox(height: 18.h),
                                CustomElevatedButton(
                                  onPressed: authState.isSubmitting
                                      ? null
                                      : handleForgotVerify,
                                  label: authState.isSubmitting
                                      ? 'Verifying...'
                                      : 'Verify & Continue',
                                  uppercaseLabel: false,
                                  showArrow: false,
                                ),
                                SizedBox(height: 8.h),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () {
                                      showForgotPin.value = false;
                                      forgotOtpController.clear();
                                      forgotPinController.clear();
                                      forgotConfirmController.clear();
                                    },
                                    child: const Text('Back'),
                                  ),
                                ),
                              ],
                              SizedBox(height: 26.h),
                              if (!showForgotPin.value) ...[
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _LockOptionButton(
                                      icon: Icons.dialpad_rounded,
                                      label: 'Use PIN',
                                      onTap: () {
                                        pinFocusNode.requestFocus();
                                      },
                                    ),
                                    if (biometricAvailable.value) ...[
                                      SizedBox(width: 18.w),
                                      _LockOptionButton(
                                        icon: Icons.fingerprint,
                                        label: 'Use Fingerprint',
                                        onTap: handleBiometric,
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                              SizedBox(height: 12.h),
                            ],
                          ),
                        ),
                      ),
                    ),
              if (isUnlocking.value)
                Positioned.fill(
                  child: Stack(
                    children: [
                      BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                        child: Container(
                          color: Colors.black.withOpacity(0.15),
                        ),
                      ),
                      Center(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 24.w,
                            vertical: 20.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18.r),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.12),
                                blurRadius: 18.r,
                                offset: Offset(0.w, 10.h),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset(
                                FileConstants.erupaiyaLogo,
                                height: 48.h,
                                width: 48.h,
                              ),
                              SizedBox(height: 12.h),
                              Text(
                                'Unlocking Securely...',
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              SizedBox(height: 10.h),
                              const Center(
                                child: SpinKitCircle(
                                  color: AppColors.primary,
                                  size: 48,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LockOptionButton extends StatelessWidget {
  const _LockOptionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64.w,
            height: 64.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey.shade100,
              boxShadow: [
                BoxShadow(
                  color: AppColors.cardShadow,
                  blurRadius: 10.r,
                  offset: Offset(0.w, 6.h),
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 30.sp,
              color: AppColors.textPrimary.withOpacity(0.7),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textPrimary.withOpacity(0.7),
                ),
          ),
        ],
      ),
    );
  }
}

class _AppLockPinInput extends StatelessWidget {
  const _AppLockPinInput({
    required this.controller,
    this.focusNode,
    this.enabled = true,
    this.obscure = false,
    this.length = 4,
    required this.onCompleted,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final bool enabled;
  final bool obscure;
  final int length;
  final ValueChanged<String> onCompleted;

  @override
  Widget build(BuildContext context) {
    final pinTheme = PinTheme(
      width: 58.w,
      height: 54.h,
      textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.lightBorder),
      ),
    );
    final cursor = Container(
      width: 2.w,
      height: 22.h,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(2.r),
      ),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        const gap = 10.0;
        final fieldWidth = (totalWidth - (gap * (length - 1))) / length;
        final stretchedTheme = pinTheme.copyWith(width: fieldWidth);
        return Pinput(
          controller: controller,
          focusNode: focusNode,
          length: length,
          enabled: enabled,
          obscureText: obscure,
          obscuringCharacter: '●',
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          defaultPinTheme: stretchedTheme,
          focusedPinTheme: stretchedTheme.copyWith(
            decoration: stretchedTheme.decoration?.copyWith(
              border: Border.all(color: AppColors.primary, width: 1.5),
            ),
          ),
          cursor: cursor,
          separatorBuilder: (_) => const SizedBox(width: gap),
          onCompleted: onCompleted,
        );
      },
    );
  }
}
