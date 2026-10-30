// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../../../config/app_env.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/file_constants.dart';
import '../../../constants/routes_constant.dart';
import '../../../services/logger_service.dart';
import '../../../services/secure_storage_service.dart';
import '../../../widgets/app_snackbar.dart';
import '../../profile/controllers/profile_controller.dart';
import '../components/auth_app_lock_step.dart';
import '../components/auth_reset_mpin_step.dart';
import '../components/auth_feedback.dart';
import '../components/auth_step_parts.dart';
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
    final pinShake = useAuthShakeController();
    final forgotOtpShake = useAuthShakeController();
    final pinError = useState<String?>(null);
    final forgotOtpError = useState<String?>(null);
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
          return;
        }
      } catch (e, stackTrace) {
        logger.error('Biometric authentication failed',
            error: e, stackTrace: stackTrace);
        AppSnackbar.show(_genericErrorMessage);
      }
      if (context.mounted && !showForgotPin.value) {
        showAuthKeyboard(pinFocusNode);
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
        final error = ref.read(authControllerProvider).errorMessage;
        if (isAuthConnectivityError(error)) {
          AppSnackbar.show(error!);
        } else {
          pinShake.shake();
          pinError.value = authInvalidPinMessage;
        }
        pinController.clear();
        showAuthKeyboard(pinFocusNode);
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
        final error = ref.read(authControllerProvider).errorMessage;
        if (isAuthConnectivityError(error)) {
          AppSnackbar.show(error!);
        } else {
          forgotOtpShake.shake();
          forgotOtpError.value = authInvalidOtpMessage;
        }
      }
    }

    useEffect(() {
      if (!showForgotPin.value) return null;
      Future.microtask(requestForgotOtp);
      return () {
        forgotTimerRef.value?.cancel();
      };
    }, [showForgotPin.value]);

    void closeForgotPin() {
      showForgotPin.value = false;
      forgotOtpError.value = null;
      forgotOtpController.clear();
      forgotPinController.clear();
      forgotConfirmController.clear();
    }

    final forgotTimerText =
        '${(forgotRemainingSeconds.value ~/ 60).toString().padLeft(2, '0')}:${(forgotRemainingSeconds.value % 60).toString().padLeft(2, '0')}';

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          fit: StackFit.expand,
          children: [
            if (isLoading.value)
              Center(
                child: SpinKitCircle(
                  color: AppColors.primary,
                  size: 48.r,
                ),
              )
            else if (showForgotPin.value)
              AuthResetMpinStep(
                otpLength: _forgotOtpLength,
                otpController: forgotOtpController,
                newPinController: forgotPinController,
                confirmPinController: forgotConfirmController,
                timerText: forgotTimerText,
                canResend:
                    forgotRemainingSeconds.value == 0 && !isRequestingOtp.value,
                onResend: handleForgotResend,
                resendLabel: isRequestingOtp.value ? 'Sending...' : 'Resend',
                isSubmitting: authState.isSubmitting,
                onVerify: handleForgotVerify,
                onBack: closeForgotPin,
                shakeController: forgotOtpShake,
                codeErrorText: forgotOtpError.value,
                onOtpChanged: (_) => forgotOtpError.value = null,
              )
            else
              AuthAppLockStep(
                pinController: pinController,
                pinFocusNode: pinFocusNode,
                enabled: !isUnlocking.value,
                onPinCompleted: (_) => handleUnlock(),
                shakeController: pinShake,
                errorText: pinError.value,
                onPinChanged: (value) {
                  if (value.isNotEmpty) pinError.value = null;
                },
                onForgotPin: () {
                  pinError.value = null;
                  showForgotPin.value = true;
                },
                showFingerprint: biometricAvailable.value,
                onFingerprint: handleBiometric,
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
                              height: 48.r,
                              width: 48.r,
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
                            Center(
                              child: SpinKitCircle(
                                color: AppColors.primary,
                                size: 48.r,
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
    );
  }
}
