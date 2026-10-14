import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:sms_autofill/sms_autofill.dart';

import '../../../constants/app_error_messages.dart';
import '../../../services/logger_service.dart';
import '../../../widgets/app_snackbar.dart';
import '../../../widgets/blocking_loading_overlay.dart';
import '../components/auth_reset_mpin_step.dart';
import '../components/auth_feedback.dart';
import '../components/auth_step_parts.dart';
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

    final otpFocus = useFocusNode();
    final newPinFocus = useFocusNode();
    final confirmPinFocus = useFocusNode();

    final errorText = useState<String?>(null);
    final remainingSeconds = useState<int>(0);
    final timerRef = useRef<Timer?>(null);
    final isRequestingOtp = useState(false);
    final loadingMessage = useState('Sending OTP...');
    final otpShake = useAuthShakeController();
    final otpError = useState<String?>(null);

    void applyOtpCode(String code) {
      final digits = code.replaceAll(RegExp(r'\D'), '');
      if (digits.isEmpty) return;
      final trimmed =
          digits.length > _otpLength ? digits.substring(0, _otpLength) : digits;
      otpController.text = trimmed;
      errorText.value = null;
      otpError.value = null;
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
        showAuthKeyboard(otpFocus);
        return;
      }
      if (pin.length != 4 || confirmPin.length != 4) {
        errorText.value = 'Please enter a valid 4-digit MPIN.';
        if (pin.length != 4) {
          showAuthKeyboard(newPinFocus);
        } else {
          showAuthKeyboard(confirmPinFocus);
        }
        return;
      }
      if (pin != confirmPin) {
        errorText.value = 'MPIN does not match.';
        showAuthKeyboard(confirmPinFocus);
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
        final error = ref.read(authControllerProvider).errorMessage;
        if (isAuthConnectivityError(error)) {
          AppSnackbar.show(error!, type: AppSnackbarType.error);
        } else {
          otpShake.shake();
          otpError.value = authInvalidOtpMessage;
        }
      }
    }

    useEffect(() {
      Future.microtask(() => requestOtp(showToastOnSuccess: false));
      return () => timerRef.value?.cancel();
    }, const []);

    final timerText =
        '${(remainingSeconds.value ~/ 60).toString().padLeft(2, '0')}:${(remainingSeconds.value % 60).toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: Colors.white,
      body: BlockingLoadingOverlay(
        isLoading: authState.isSubmitting,
        message: loadingMessage.value,
        child: AuthResetMpinStep(
          otpLength: _otpLength,
          otpController: otpController,
          newPinController: newPinController,
          confirmPinController: confirmPinController,
          otpFocusNode: otpFocus,
          newPinFocusNode: newPinFocus,
          confirmPinFocusNode: confirmPinFocus,
          timerText: timerText,
          canResend: remainingSeconds.value == 0 && !isRequestingOtp.value,
          onResend: handleResendOtp,
          resendLabel: isRequestingOtp.value ? 'Sending...' : 'Resend',
          errorText: errorText.value,
          isSubmitting: authState.isSubmitting,
          onChanged: (_) => errorText.value = null,
          onOtpCompleted: (_) => newPinFocus.requestFocus(),
          onNewPinCompleted: (_) => confirmPinFocus.requestFocus(),
          onConfirmPinCompleted: (_) => handleVerifyAndContinue(),
          onVerify: handleVerifyAndContinue,
          onBack: () => context.pop(),
          shakeController: otpShake,
          codeErrorText: otpError.value,
          onOtpChanged: (_) => otpError.value = null,
        ),
      ),
    );
  }
}
