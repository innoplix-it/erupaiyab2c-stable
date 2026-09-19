// ignore_for_file: deprecated_member_use

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:pinput/pinput.dart';
import 'package:sms_autofill/sms_autofill.dart';

import '../../../constants/app_error_messages.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/file_constants.dart';
import '../../../services/logger_service.dart';
import '../../../widgets/app_snackbar.dart';
import '../../../widgets/blocking_loading_overlay.dart';
import '../../../widgets/custom_elevated_button.dart';
import '../controllers/auth_controller.dart';

class ResetMpinView extends HookConsumerWidget {
  const ResetMpinView({
    super.key,
    this.mobile,
  });

  static const int _otpLength = 6;
  static const String _genericErrorMessage = AppErrorMessages.generic;
  final String? mobile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);

    final otpController = useTextEditingController();
    final newPinController = useTextEditingController();
    final confirmPinController = useTextEditingController();

    useListenable(otpController);

    final otpFocus = useFocusNode();
    final newPinFocus = useFocusNode();
    final confirmPinFocus = useFocusNode();

    final errorText = useState<String?>(null);
    final remainingSeconds = useState<int>(0);
    final timerRef = useRef<Timer?>(null);
    final isRequestingOtp = useState(false);
    final loadingMessage = useState('Sending OTP...');

    void applyOtpCode(String code) {
      final digits = code.replaceAll(RegExp(r'\D'), '');
      if (digits.isEmpty) return;
      final trimmed =
          digits.length > _otpLength ? digits.substring(0, _otpLength) : digits;
      otpController.text = trimmed;
      errorText.value = null;
      if (trimmed.length == _otpLength) {
        otpFocus.unfocus();
        newPinFocus.requestFocus();
      }
    }

    useEffect(() {
      var isDisposed = false;
      final autoFill = SmsAutoFill();
      final sub = autoFill.code.listen((code) {
        if (isDisposed) return;
        applyOtpCode(code);
      });

      () async {
        try {
          await autoFill.listenForCode(
            smsCodeRegexPattern: '\\d{$_otpLength}',
          );
        } catch (e, stackTrace) {
          logger.error(
            'Failed to start OTP autofill listener in reset MPIN view',
            error: e,
            stackTrace: stackTrace,
          );
        }
      }();

      return () {
        isDisposed = true;
        sub.cancel();
        autoFill.unregisterListener();
      };
    }, const []);

    void startTimer() {
      timerRef.value?.cancel();
      timerRef.value = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (remainingSeconds.value <= 1) {
          remainingSeconds.value = 0;
          timer.cancel();
          timerRef.value = null;
        } else {
          remainingSeconds.value -= 1;
        }
      });
    }

    Future<void> requestOtp({bool showToastOnSuccess = true}) async {
      if (isRequestingOtp.value) return;
      isRequestingOtp.value = true;
      loadingMessage.value = 'Sending OTP...';
      final message = await ref
          .read(authControllerProvider.notifier)
          .requestForgotPinOtp(mobile: mobile);
      isRequestingOtp.value = false;
      if (!context.mounted) return;
      if (message != null) {
        if (showToastOnSuccess) AppSnackbar.show(message);
        remainingSeconds.value = 60;
        startTimer();
        return;
      }
      AppSnackbar.show(
        ref.read(authControllerProvider).errorMessage ?? _genericErrorMessage,
        type: AppSnackbarType.error,
      );
    }

    Future<void> handleResendOtp() async {
      if (remainingSeconds.value > 0) return;
      await requestOtp();
    }

    Future<void> handleVerifyAndContinue() async {
      final otp = otpController.text.trim();
      final pin = newPinController.text.trim();
      final confirmPin = confirmPinController.text.trim();

      if (otp.length != _otpLength) {
        errorText.value = 'Please enter a valid $_otpLength-digit OTP.';
        otpFocus.requestFocus();
        return;
      }
      if (pin.length != 4 || confirmPin.length != 4) {
        errorText.value = 'Please enter a valid 4-digit MPIN.';
        if (pin.length != 4) {
          newPinFocus.requestFocus();
        } else {
          confirmPinFocus.requestFocus();
        }
        return;
      }
      if (pin != confirmPin) {
        errorText.value = 'MPIN does not match.';
        confirmPinFocus.requestFocus();
        return;
      }

      errorText.value = null;
      loadingMessage.value = 'Resetting your MPIN...';
      final message = await ref
          .read(authControllerProvider.notifier)
          .forgotPin(otp: otp, pin: pin);
      if (!context.mounted) return;

      if (message != null) {
        AppSnackbar.show(message);
        context.pop();
      } else {
        AppSnackbar.show(
          ref.read(authControllerProvider).errorMessage ?? _genericErrorMessage,
          type: AppSnackbarType.error,
        );
      }
    }

    useEffect(() {
      Future.microtask(() => requestOtp(showToastOnSuccess: false));
      return () {
        otpController.dispose();
        newPinController.dispose();
        confirmPinController.dispose();
        otpFocus.dispose();
        newPinFocus.dispose();
        confirmPinFocus.dispose();
        timerRef.value?.cancel();
      };
    }, const []);

    final otpVerified = otpController.text.trim().length == _otpLength;

    final otpTheme = PinTheme(
      width: 52.w,
      height: 52.w,
      textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: otpVerified ? AppColors.green : const Color(0xFFD6D6D6),
        ),
      ),
    );

    final mpinTheme = PinTheme(
      width: 52.w,
      height: 52.w,
      textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: const Color(0xFFD6D6D6),
        ),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: BlockingLoadingOverlay(
        isLoading: authState.isSubmitting,
        message: loadingMessage.value,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.fromLTRB(8.w, 6.h, 16.w, 6.h),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFE8E8E8)),
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      color: AppColors.textPrimary,
                      onPressed: () => context.pop(),
                    ),
                    Text(
                      'Reset MPIN',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const Spacer(),
                    Image.asset(
                      FileConstants.bharatConnectColor,
                      height: 18.h,
                      fit: BoxFit.contain,
                    ),
                    SizedBox(width: 6.w),
                    IconButton(
                      icon: const Icon(Icons.help_outline),
                      color: AppColors.textPrimary,
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12.h),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.asset(
                        FileConstants.resetPinIcon,
                        height: 50.h,
                        fit: BoxFit.contain,
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        'Reset Your MPIN',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'Enter the $_otpLength-digit OTP sent to your mobile number.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textPrimary.withOpacity(0.7),
                              height: 1.4,
                            ),
                      ),
                      SizedBox(height: 18.h),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(14.w),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(
                            color: const Color(0xFFE8E8E8),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Pinput(
                              controller: otpController,
                              focusNode: otpFocus,
                              length: _otpLength,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              autofocus: true,
                              onChanged: (_) => errorText.value = null,
                              onCompleted: (_) => newPinFocus.requestFocus(),
                              defaultPinTheme: otpTheme,
                              focusedPinTheme: otpTheme.copyWith(
                                decoration: otpTheme.decoration?.copyWith(
                                  border: Border.all(
                                    color: AppColors.green,
                                    width: 1.4,
                                  ),
                                ),
                              ),
                            ),
                            if (otpVerified) ...[
                              SizedBox(height: 10.h),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 10.w,
                                  vertical: 6.h,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.green.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.verified,
                                      color: AppColors.green,
                                      size: 16,
                                    ),
                                    SizedBox(width: 6.w),
                                    Text(
                                      'OTP Verified',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: AppColors.green,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            SizedBox(height: 10.h),
                            Row(
                              children: [
                                const Icon(
                                  Icons.access_time,
                                  size: 18,
                                  color: AppColors.textPrimary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${(remainingSeconds.value ~/ 60).toString().padLeft(2, '0')}:${(remainingSeconds.value % 60).toString().padLeft(2, '0')}',
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
                                  onPressed: remainingSeconds.value == 0 &&
                                          !isRequestingOtp.value
                                      ? handleResendOtp
                                      : null,
                                  style: TextButton.styleFrom(
                                    foregroundColor: remainingSeconds.value == 0
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
                            SizedBox(height: 10.h),
                            Divider(
                              color: AppColors.textPrimary.withOpacity(0.1),
                            ),
                            SizedBox(height: 10.h),
                            Text(
                              'Create New MPIN',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            SizedBox(height: 10.h),
                            Pinput(
                              controller: newPinController,
                              focusNode: newPinFocus,
                              length: 4,
                              obscureText: true,
                              obscuringCharacter: '●',
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              onChanged: (_) => errorText.value = null,
                              onCompleted: (_) =>
                                  confirmPinFocus.requestFocus(),
                              defaultPinTheme: mpinTheme,
                            ),
                            SizedBox(height: 16.h),
                            Text(
                              'Confirm MPIN',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            SizedBox(height: 10.h),
                            Pinput(
                              controller: confirmPinController,
                              focusNode: confirmPinFocus,
                              length: 4,
                              obscureText: true,
                              obscuringCharacter: '●',
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              onChanged: (_) => errorText.value = null,
                              onCompleted: (_) => handleVerifyAndContinue(),
                              defaultPinTheme: mpinTheme,
                            ),
                            if (errorText.value != null &&
                                errorText.value!.isNotEmpty) ...[
                              SizedBox(height: 10.h),
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
                          ],
                        ),
                      ),
                      SizedBox(height: 26.h),
                      CustomElevatedButton(
                        onPressed: authState.isSubmitting
                            ? null
                            : handleVerifyAndContinue,
                        label: 'Verify & Continue',
                        uppercaseLabel: false,
                        showArrow: false,
                        height: 44.h,
                      ),
                      SizedBox(height: 8.h),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
