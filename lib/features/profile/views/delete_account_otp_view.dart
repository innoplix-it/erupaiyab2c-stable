import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';

import '../../../widgets/app_snackbar.dart';
import '../../auth/components/auth_feedback.dart';
import '../../auth/components/auth_step_parts.dart';
import '../../auth/components/otp_verify_step.dart';
import '../repositories/settings_repository.dart';

/// Full-screen Enter OTP page for the Delete Account flow. Reuses the auth
/// Verify OTP screen ([OtpVerifyStep]) instead of the old popup dialog.
/// Verification logic is unchanged: it still calls
/// [SettingsRepository.verifyDeleteAccountOtp] and pops with `true` on success
/// so the caller can log out, exactly like the popup's onSubmit did.
class DeleteAccountOtpView extends HookWidget {
  const DeleteAccountOtpView({
    super.key,
    required this.repository,
    this.phoneNumber = '',
  });

  static const int _otpLength = 6;

  final SettingsRepository repository;
  final String phoneNumber;

  @override
  Widget build(BuildContext context) {
    final otpController = useTextEditingController();
    final otpFocusNode = useFocusNode();
    final otpShake = useAuthShakeController();
    final isSubmitting = useState(false);
    final errorText = useState<String?>(null);
    final codeError = useState<String?>(null);
    final remainingSeconds = useState(60);
    final timerRef = useRef<Timer?>(null);

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

    useEffect(() {
      startTimer();
      return () => timerRef.value?.cancel();
    }, const []);

    final timerText =
        '${(remainingSeconds.value ~/ 60).toString().padLeft(2, '0')}:${(remainingSeconds.value % 60).toString().padLeft(2, '0')}';

    Future<void> handleVerify() async {
      if (isSubmitting.value) return;
      final otp = otpController.text.trim();
      if (otp.length < _otpLength) {
        errorText.value = 'Please enter the $_otpLength-digit OTP.';
        return;
      }
      errorText.value = null;
      codeError.value = null;
      isSubmitting.value = true;
      final result = await repository.verifyDeleteAccountOtp(otp);
      if (!context.mounted) return;
      isSubmitting.value = false;
      if (result.message.isNotEmpty) {
        AppSnackbar.show(result.message);
      }
      if (!result.success) {
        otpShake.shake();
        codeError.value = authInvalidOtpMessage;
        return;
      }
      showAuthKeyboard(otpFocusNode);
      Navigator.of(context).pop(true);
    }

    Future<void> handleResend() async {
      final result = await repository.sendDeleteAccountOtp();
      if (result.message.isNotEmpty) {
        AppSnackbar.show(result.message);
      }
      if (!result.success || !context.mounted) return;
      otpController.clear();
      errorText.value = null;
      codeError.value = null;
      remainingSeconds.value = 60;
      startTimer();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: OtpVerifyStep(
        otpLength: _otpLength,
        otpController: otpController,
        otpFocusNode: otpFocusNode,
        phoneNumber: phoneNumber,
        title: 'Delete Account',
        label: 'Enter OTP',
        description:
            'Enter the OTP sent to your registered number to confirm deletion.',
        timerText: timerText,
        canResend: remainingSeconds.value == 0,
        onResend: handleResend,
        onVerify: handleVerify,
        isSubmitting: isSubmitting.value,
        buttonLabel: 'Verify OTP',
        errorText: errorText.value,
        codeErrorText: codeError.value,
        shakeController: otpShake,
        onBack: () => context.pop(),
        // No number to change in the delete flow; hides the "Change" link.
        onChangeNumber: null,
        onOtpChanged: (_) {
          errorText.value = null;
          codeError.value = null;
        },
        onOtpCompleted: (_) => handleVerify(),
      ),
    );
  }
}
