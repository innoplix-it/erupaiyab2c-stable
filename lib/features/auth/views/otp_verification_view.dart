// ignore_for_file: deprecated_member_use

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:pinput/pinput.dart';
import 'package:sms_autofill/sms_autofill.dart';

import '../../../config/temporary_block_debug_config.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/file_constants.dart';
import '../../../constants/routes_constant.dart';
import '../../../widgets/app_snackbar.dart';
import '../../../widgets/custom_elevated_button.dart';
import '../../../widgets/k_dialog.dart';
import '../components/pin_input_row.dart';
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

    useListenable(otpController);

    final remainingSeconds = useState(0);
    final emailRemainingSeconds = useState(59);
    final errorText = useState<String?>(null);
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

    final timerText = showIdentityVariant
        ? remainingSeconds.value.toString()
        : '${(remainingSeconds.value ~/ 60).toString().padLeft(2, '0')}:${(remainingSeconds.value % 60).toString().padLeft(2, '0')}';
    final emailTimerText = showIdentityVariant
        ? emailRemainingSeconds.value.toString()
        : '${(emailRemainingSeconds.value ~/ 60).toString().padLeft(2, '0')}:${(emailRemainingSeconds.value % 60).toString().padLeft(2, '0')}';

    Future<void> handleVerify() async {
      if (showIdentityVariant) {
        final mobileOtp = mobileOtpControllers.map((c) => c.text).join();
        final emailOtp = emailOtpControllers.map((c) => c.text).join();
        if (mobileOtp.length < _otpLength || emailOtp.length < _otpLength) {
          errorText.value = 'Please enter both $_otpLength-digit OTPs.';
          return;
        }
        errorText.value = null;
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
            errorText.value = latestState.errorMessage ??
                "Oops! That OTP doesn't seem right. Please check and re-enter.";
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
        errorText.value = latestState.errorMessage ??
            "Oops! That OTP doesn't seem right. Please check and re-enter.";
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

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.only(bottom: 24.h),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(8.w, 6.h, 16.w, 0.h),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back),
                            color: AppColors.textPrimary,
                            onPressed: () => context.pop(),
                          ),

                          // Expanded(
                          //   child: Text(
                          //     "",
                          //     style: Theme.of(context)
                          //         .textTheme
                          //         .titleMedium
                          //         ?.copyWith(
                          //           fontWeight: FontWeight.w600,
                          //           color: AppColors.textPrimary,
                          //         ),
                          //   ),
                          // ),
                          // Image.asset(
                          //   FileConstants.bharatConnectColor,
                          //   height: 22.h,
                          //   fit: BoxFit.contain,
                          // ),
                        ],
                      ),
                    ),
                    Divider(
                      color: AppColors.textPrimary.withOpacity(0.1),
                      thickness: 1,
                    ),
                    SizedBox(height: 16.h),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (showIdentityVariant) ...[
                            Image.asset(
                              FileConstants.resetPinIcon,
                              height: 65.h,
                              fit: BoxFit.contain,
                            ),
                            SizedBox(height: 18.h),
                          ],
                          Text(
                            args.heading,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: showIdentityVariant
                                      ? AppColors.primary
                                      : AppColors.textPrimary,
                                ),
                          ),
                          SizedBox(height: 8.h),
                          if (showIdentityVariant)
                            Text(
                              args.description ??
                                  'Enter the OTPs sent to your registered mobile number and email address to verify your identity.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontSize: 12.sp,
                                    color:
                                        AppColors.textPrimary.withOpacity(0.7),
                                    height: 1.45,
                                  ),
                            )
                          else
                            RichText(
                              text: TextSpan(
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: AppColors.textPrimary
                                          .withOpacity(0.7),
                                    ),
                                children: [
                                  TextSpan(
                                    text: args.description ??
                                        'Sent to ${args.phoneNumber ?? authState.pendingMobile ?? ''} ',
                                  ),
                                  TextSpan(
                                    text: 'Change',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: AppColors.textPrimary,
                                          decoration: TextDecoration.underline,
                                          fontWeight: FontWeight.w600,
                                        ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () =>
                                          context.go(RouteConstants.login),
                                  ),
                                ],
                              ),
                            ),
                          SizedBox(height: 18.h),
                          if (showIdentityVariant) ...[
                            _IdentityOtpSection(
                              title: 'Mobile OTP',
                              subtitle:
                                  'Enter the 6 digit OTP sent to your registered mobile number.',
                              controllers: mobileOtpControllers,
                              focusNodes: mobileOtpFocusNodes,
                              timerText: timerText,
                              canResend: remainingSeconds.value == 0,
                              onResend: handleResend,
                              onChanged: (_) => errorText.value = null,
                            ),
                            SizedBox(height: 20.h),
                            _IdentityOtpSection(
                              title: 'Email OTP',
                              subtitle:
                                  'Enter the 6 digit OTP sent to your registered email address.',
                              controllers: emailOtpControllers,
                              focusNodes: emailOtpFocusNodes,
                              timerText: emailTimerText,
                              canResend: emailRemainingSeconds.value == 0,
                              onResend: handleEmailResend,
                              onChanged: (_) => errorText.value = null,
                            ),
                          ] else
                            Pinput(
                              length: _otpLength,
                              controller: otpController,
                              focusNode: otpFocusNode,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              autofocus: true,
                              onChanged: (_) => errorText.value = null,
                              onCompleted: (_) => handleVerify(),
                              defaultPinTheme: PinTheme(
                                width: 44.w,
                                height: 44.w,
                                textStyle: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14.r),
                                  border: Border.all(
                                    color: const Color(0xFFD6D6D6),
                                  ),
                                ),
                              ),
                              errorPinTheme: PinTheme(
                                width: 44.w,
                                height: 44.w,
                                textStyle: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14.r),
                                  border: Border.all(color: Colors.red),
                                ),
                              ),
                              errorTextStyle: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Colors.red,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          if (errorText.value != null &&
                              errorText.value!.isNotEmpty) ...[
                            SizedBox(height: 12.h),
                            Text(
                              errorText.value!,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Colors.red,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ],
                          SizedBox(height: showIdentityVariant ? 28.h : 20.h),
                          CustomElevatedButton(
                            onPressed:
                                authState.isSubmitting ? null : handleVerify,
                            label: authState.isSubmitting
                                ? 'Verifying...'
                                : (args.primaryButtonLabel ??
                                    (showIdentityVariant
                                        ? 'Verify & Continue'
                                        : 'Verify')),
                            uppercaseLabel: false,
                            showArrow: false,
                            height: 42.h,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
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
            CustomElevatedButton(
              onPressed: onContinue,
              label: buttonLabel,
              showArrow: false,
              height: 42.h,
            ),
          ],
        ),
      ),
    );
  }
}

class _IdentityOtpSection extends StatelessWidget {
  const _IdentityOtpSection({
    required this.title,
    required this.subtitle,
    required this.controllers,
    required this.focusNodes,
    required this.timerText,
    required this.canResend,
    required this.onResend,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final String timerText;
  final bool canResend;
  final VoidCallback onResend;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
        ),
        SizedBox(height: 4.h),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textPrimary.withOpacity(0.7),
              ),
        ),
        SizedBox(height: 10.h),
        PinInputRow(
          controllers: controllers,
          focusNodes: focusNodes,
          onPinChanged: onChanged,
        ),
        SizedBox(height: 10.h),
        Row(
          children: [
            Icon(
              Icons.access_time,
              size: 14.r,
              color: AppColors.textPrimary,
            ),
            SizedBox(width: 4.w),
            Text(
              timerText,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
            ),
            const Spacer(),
            InkWell(
              onTap: canResend ? onResend : null,
              child: Row(
                children: [
                  Icon(
                    Icons.refresh,
                    size: 14.r,
                    color: canResend
                        ? AppColors.textPrimary
                        : AppColors.textPrimary.withOpacity(0.35),
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    'Resend OTP',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: canResend
                              ? AppColors.textPrimary
                              : AppColors.textPrimary.withOpacity(0.35),
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
