// ignore_for_file: deprecated_member_use

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:sms_autofill/sms_autofill.dart';

import '../../../config/temporary_block_debug_config.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/routes_constant.dart';
import '../../../widgets/app_snackbar.dart';
import '../../../widgets/custom_elevated_button.dart';
import '../../../widgets/k_dialog.dart';
import '../components/auth_step_parts.dart';
import '../components/otp_verify_step.dart';
import '../components/auth_feedback.dart';
import '../components/auth_identity_otp_step.dart';
import '../controllers/auth_controller.dart';
import '../models/otp_verification_args.dart';

class OtpVerificationView extends HookConsumerWidget {
  const OtpVerificationView({super.key, required this.args});

  static const int _otpLength = 6;

  final OtpVerificationArgs args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final otpController = useTextEditingController();
    final otpFocusNode = useFocusNode();
    final otpShake = useAuthShakeController();
    final autoFilledCode = useState<String?>(null);
    final showIdentityVariant = args.temporaryBlockFlowType != null;
    final isDeviceVerificationFlow = args.temporaryBlockFlowType ==
        TemporaryBlockFlowType.deviceVerification;
    final mobileOtpControllers = useMemoized(
      () => List.generate(_otpLength, (_) => TextEditingController()),
      const [],
    );
    final mobileOtpFocusNodes = useMemoized(
      () => List.generate(_otpLength, (_) => FocusNode()),
      const [],
    );
    final emailOtpControllers = useMemoized(
      () => List.generate(_otpLength, (_) => TextEditingController()),
      const [],
    );
    final emailOtpFocusNodes = useMemoized(
      () => List.generate(_otpLength, (_) => FocusNode()),
      const [],
    );
    final mobileOtpInput = useTextEditingController();
    final emailOtpInput = useTextEditingController();
    final mobileOtpInputFocus = useFocusNode();
    final emailOtpInputFocus = useFocusNode();

    /// The boxes edit a single string; verification still reads the per-digit
    /// controllers.
    void syncOtpDigits(String value, List<TextEditingController> digits) {
      for (var i = 0; i < digits.length; i++) {
        digits[i].text = i < value.length ? value[i] : '';
      }
    }

    useListenable(otpController);

    final remainingSeconds = useState(0);
    final emailRemainingSeconds = useState(59);
    final errorText = useState<String?>(null);
    final codeError = useState<String?>(null);
    final timerRef = useRef<Timer?>(null);
    final emailTimerRef = useRef<Timer?>(null);

    void startTimer() {
      timerRef.value?.cancel();
      timerRef.value = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (remainingSeconds.value <= 1) {
          remainingSeconds.value = 0;
          timer.cancel();
          timerRef.value = null;
        } else {
          remainingSeconds.value--;
        }
      });
    }

    void startEmailTimer() {
      emailTimerRef.value?.cancel();
      emailTimerRef.value = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (emailRemainingSeconds.value <= 1) {
          emailRemainingSeconds.value = 0;
          timer.cancel();
          emailTimerRef.value = null;
        } else {
          emailRemainingSeconds.value--;
        }
      });
    }

    Future<void> sendTemporaryBlockOtp({bool showToast = false}) async {
      final message = isDeviceVerificationFlow
          ? await ref.read(authControllerProvider.notifier).sendDeviceOtp(
                verificationId: args.deviceVerificationId ?? '',
              )
          : await ref
              .read(authControllerProvider.notifier)
              .sendAccountRecoveryOtp();
      if (message != null) {
        remainingSeconds.value = 60;
        emailRemainingSeconds.value = 60;
        errorText.value = null;
        codeError.value = null;
        startTimer();
        startEmailTimer();
        if (showToast) {
          AppSnackbar.show(message);
        }
      } else if (showToast) {
        final latestState = ref.read(authControllerProvider);
        AppSnackbar.show(
          latestState.errorMessage ?? 'Failed to resend OTP. Please try again.',
        );
      }
    }

    useEffect(() {
      if (showIdentityVariant) {
        Future.microtask(() => sendTemporaryBlockOtp());
      } else {
        remainingSeconds.value = 60;
        startTimer();
      }
      return () {
        timerRef.value?.cancel();
        emailTimerRef.value?.cancel();
      };
    }, [showIdentityVariant]);

    final timerText =
        '${(remainingSeconds.value ~/ 60).toString().padLeft(2, '0')}:${(remainingSeconds.value % 60).toString().padLeft(2, '0')}';
    final emailTimerText =
        '${(emailRemainingSeconds.value ~/ 60).toString().padLeft(2, '0')}:${(emailRemainingSeconds.value % 60).toString().padLeft(2, '0')}';

    Future<void> handleVerify() async {
      if (showIdentityVariant) {
        final mobileOtp = mobileOtpControllers.map((c) => c.text).join();
        final emailOtp = emailOtpControllers.map((c) => c.text).join();
        if (mobileOtp.length < _otpLength || emailOtp.length < _otpLength) {
          errorText.value = 'Please enter both $_otpLength-digit OTPs.';
          return;
        }
        errorText.value = null;
        codeError.value = null;
        final message = isDeviceVerificationFlow
            ? await ref.read(authControllerProvider.notifier).verifyDeviceOtp(
                  verificationId: args.deviceVerificationId ?? '',
                  mobileOtp: mobileOtp,
                  emailOtp: emailOtp,
                )
            : (await ref
                    .read(authControllerProvider.notifier)
                    .verifyAccountRecoveryOtp(
                      mobileOtp: mobileOtp,
                      emailOtp: emailOtp,
                    ))
                ? 'success'
                : null;
        if (message != null) {
          if (context.mounted) {
            if ((args.successDialogTitle?.isNotEmpty ?? false) ||
                (args.successDialogMessage?.isNotEmpty ?? false)) {
              await KDialog.instance.openDialog(
                barrierDismissible: false,
                dialog: _OtpCustomSuccessDialog(
                  title: args.successDialogTitle ?? 'Verified successfully',
                  message: args.successDialogMessage ?? '',
                  buttonLabel: args.successButtonLabel ?? 'Continue',
                  onContinue: () async {
                    Navigator.of(context, rootNavigator: true).pop();
                    if (args.clearTemporaryAccessOnSuccess) {
                      await ref.read(authControllerProvider.notifier).logout();
                    }
                    final route = args.successRoute;
                    if (route != null) {
                      Future.microtask(() {
                        if (!context.mounted) return;
                        if (args.successRouteUseGo) {
                          context.go(route);
                        } else {
                          context.push(route, extra: args.successRouteExtra);
                        }
                      });
                    }
                  },
                ),
              );
              return;
            }

            final route = args.successRoute;
            if (route != null) {
              if (args.successRouteUseGo) {
                if (args.clearTemporaryAccessOnSuccess) {
                  await ref.read(authControllerProvider.notifier).logout();
                }
                if (!context.mounted) return;
                context.go(route);
              } else {
                context.push(route, extra: args.successRouteExtra);
              }
            }
          }
        } else {
          final latestState = ref.read(authControllerProvider);
          if (isDeviceVerificationFlow) {
            AppSnackbar.show(
              latestState.errorMessage ??
                  'Verification failed. Please login again.',
            );
            if (context.mounted) {
              context.go(RouteConstants.login);
            }
          } else {
            if (isAuthConnectivityError(latestState.errorMessage)) {
              errorText.value = latestState.errorMessage;
            } else {
              otpShake.shake();
              codeError.value = authInvalidOtpMessage;
            }
          }
        }
        return;
      }

      final otp = otpController.text.trim();
      if (otp.length < _otpLength) {
        errorText.value = 'Please enter the $_otpLength-digit OTP.';
        return;
      }

      errorText.value = null;
      codeError.value = null;
      final success = await ref
          .read(authControllerProvider.notifier)
          .verifyOtp(otp: otp, mobile: args.phoneNumber);
      if (success) {
        if (context.mounted) {
          if (!args.hasCustomSuccessFlow) {
            context.go(RouteConstants.otpSuccess);
            return;
          }

          if ((args.successDialogTitle?.isNotEmpty ?? false) ||
              (args.successDialogMessage?.isNotEmpty ?? false)) {
            await KDialog.instance.openDialog(
              barrierDismissible: false,
              dialog: _OtpCustomSuccessDialog(
                title: args.successDialogTitle ?? 'Verified successfully',
                message: args.successDialogMessage ?? '',
                buttonLabel: args.successButtonLabel ?? 'Continue',
                onContinue: () {
                  Navigator.of(context, rootNavigator: true).pop();
                  final route = args.successRoute;
                  if (route != null) {
                    Future.microtask(() {
                      if (!context.mounted) return;
                      context.push(route, extra: args.successRouteExtra);
                    });
                  }
                },
              ),
            );
            return;
          }

          final route = args.successRoute;
          if (route != null) {
            context.push(route, extra: args.successRouteExtra);
          }
        }
      } else {
        final latestState = ref.read(authControllerProvider);
        if (isAuthConnectivityError(latestState.errorMessage)) {
          errorText.value = latestState.errorMessage;
        } else {
          otpShake.shake();
          codeError.value = authInvalidOtpMessage;
        }
      }
    }

    Future<void> handleResend() async {
      if (showIdentityVariant) {
        await sendTemporaryBlockOtp(showToast: true);
        return;
      }

      final resolvedMobile = args.phoneNumber ?? authState.pendingMobile;
      if (resolvedMobile == null || resolvedMobile.isEmpty) {
        AppSnackbar.show('Missing mobile number. Please try again.');
        return;
      }

      final flow = await ref
          .read(authControllerProvider.notifier)
          .checkLogin(mobile: resolvedMobile);
      if (flow != null) {
        remainingSeconds.value = 60;
        errorText.value = null;
        codeError.value = null;
        startTimer();
        AppSnackbar.show(
          args.resendSuccessMessage ?? 'OTP resent to $resolvedMobile',
        );
      } else {
        final latestState = ref.read(authControllerProvider);
        AppSnackbar.show(
          latestState.errorMessage ?? 'Unable to resend OTP. Please try again.',
        );
      }
    }

    Future<void> handleEmailResend() async {
      if (showIdentityVariant) {
        await sendTemporaryBlockOtp(showToast: true);
        return;
      }

      emailRemainingSeconds.value = 60;
      startEmailTimer();
      AppSnackbar.show('OTP resent to your registered email');
    }

    void applyOtpCode(String code) {
      final digits = code.replaceAll(RegExp(r'\D'), '');
      if (digits.isEmpty) return;
      final trimmed =
          digits.length > _otpLength ? digits.substring(0, _otpLength) : digits;
      if (kDebugMode) {
        debugPrint('OTP autofill received: $trimmed');
      }
      otpController.text = trimmed;
      otpFocusNode.unfocus();
      autoFilledCode.value = trimmed;
      errorText.value = null;
      codeError.value = null;
    }

    useEffect(() {
      var isDisposed = false;
      final autoFill = SmsAutoFill();
      if (kDebugMode) {
        debugPrint('init SMS autofill');
      }
      final sub = autoFill.code.listen((code) {
        if (isDisposed) return;
        if (kDebugMode) {
          debugPrint('OTP SMS code stream: $code');
        }
        applyOtpCode(code);
      });

      () async {
        try {
          final signature = await autoFill.getAppSignature;
          if (kDebugMode) {
            debugPrint(
              'SMS Retriever app signature: ${signature.isEmpty ? "<empty>" : signature}',
            );
          }
          await autoFill.listenForCode(
            smsCodeRegexPattern: '\\d{$_otpLength}',
          );
          if (kDebugMode) {
            debugPrint('listenForCode started');
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint(
              'OTP autofill init failed',
            );
          }
        }
      }();

      return () {
        isDisposed = true;
        sub.cancel();
        autoFill.unregisterListener();
        if (kDebugMode) {
          debugPrint('dispose SMS autofill');
        }
        for (final controller in mobileOtpControllers) {
          controller.dispose();
        }
        for (final node in mobileOtpFocusNodes) {
          node.dispose();
        }
        for (final controller in emailOtpControllers) {
          controller.dispose();
        }
        for (final node in emailOtpFocusNodes) {
          node.dispose();
        }
      };
    }, const []);

    if (!showIdentityVariant) {
      final otpComplete = otpController.text.length == _otpLength;
      return Scaffold(
        backgroundColor: Colors.white,
        body: OtpVerifyStep(
          otpLength: _otpLength,
          otpController: otpController,
          otpFocusNode: otpFocusNode,
          phoneNumber: args.phoneNumber ?? authState.pendingMobile ?? '',
          label: args.heading,
          description: args.description,
          timerText: timerText,
          canResend: remainingSeconds.value == 0,
          onResend: handleResend,
          onVerify: otpComplete ? handleVerify : null,
          isSubmitting: authState.isSubmitting,
          buttonLabel: args.primaryButtonLabel ?? 'Verify',
          errorText: errorText.value,
          codeErrorText: codeError.value,
          onBack: () => context.canPop()
              ? context.pop()
              : context.go(RouteConstants.login),
          onChangeNumber: () => context.go(RouteConstants.login),
          onOtpChanged: (_) {
            errorText.value = null;
            codeError.value = null;
          },
          onOtpCompleted: (_) => handleVerify(),
          shakeController: otpShake,
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: AuthIdentityOtpStep(
        title: args.heading,
        description: args.description ??
            'Enter the OTPs sent to your registered mobile number and email address to verify your identity.',
        otpLength: _otpLength,
        mobileOtpController: mobileOtpInput,
        emailOtpController: emailOtpInput,
        mobileOtpFocusNode: mobileOtpInputFocus,
        emailOtpFocusNode: emailOtpInputFocus,
        mobileTimerText: timerText,
        emailTimerText: emailTimerText,
        canResendMobile: remainingSeconds.value == 0,
        canResendEmail: emailRemainingSeconds.value == 0,
        onResendMobile: handleResend,
        onResendEmail: handleEmailResend,
        onVerify: handleVerify,
        onBack: () => context.pop(),
        buttonLabel: authState.isSubmitting
            ? 'Verifying...'
            : (args.primaryButtonLabel ?? 'Verify & Continue'),
        errorText: errorText.value,
        codeErrorText: codeError.value,
        isSubmitting: authState.isSubmitting,
        shakeController: otpShake,
        onMobileOtpChanged: (value) {
          syncOtpDigits(value, mobileOtpControllers);
          errorText.value = null;
          codeError.value = null;
        },
        onEmailOtpChanged: (value) {
          syncOtpDigits(value, emailOtpControllers);
          errorText.value = null;
          codeError.value = null;
        },
      ),
    );
  }
}

class _OtpCustomSuccessDialog extends StatelessWidget {
  const _OtpCustomSuccessDialog({
    required this.title,
    required this.message,
    required this.buttonLabel,
    required this.onContinue,
  });

  final String title;
  final String message;
  final String buttonLabel;
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
        padding: EdgeInsets.fromLTRB(20.w, 26.h, 20.w, 18.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72.r,
              height: 72.r,
              decoration: const BoxDecoration(
                color: Color(0xFF1B8E36),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check, color: Colors.white, size: 40.r),
            ),
            SizedBox(height: 18.h),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
            ),
            if (message.isNotEmpty) ...[
              SizedBox(height: 12.h),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textPrimary.withOpacity(0.72),
                      height: 1.45,
                    ),
              ),
            ],
            SizedBox(height: 22.h),
            AuthButtonTheme(
              child: CustomElevatedButton(
                onPressed: onContinue,
                label: buttonLabel,
                showArrow: false,
                height: authButtonHeight(context, fraction: 42 / 360),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
