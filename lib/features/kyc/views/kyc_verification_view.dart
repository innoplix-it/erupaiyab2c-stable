// ignore_for_file: deprecated_member_use
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/file_constants.dart';
import '../../../helpers/kyc_helpers.dart';
import '../../../services/device_id_service.dart';
import '../../../utils/utils.dart';
import '../../../widgets/app_snackbar.dart';
import '../../../widgets/custom_elevated_button.dart';
import '../../../widgets/k_dialog.dart';
import '../../auth/components/pin_input_row.dart';
import '../../profile/controllers/profile_controller.dart';
import '../../refer_and_earn/views/add_bank_account_view.dart';
import '../repositories/kyc_repository.dart';

class KycVerificationView extends HookConsumerWidget {
  const KycVerificationView({
    super.key,
    this.startFromAadhaar = false,
  });

  final bool startFromAadhaar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = useMemoized(() => KycRepository());
    final deviceIdService = useMemoized(() => const DeviceIdService());
    final step = useState(
      startFromAadhaar ? _KycStep.aadhaar : _KycStep.pan,
    );
    final panDone = useState(startFromAadhaar);
    final aadhaarDone = useState(false);
    final otpSent = useState(false);

    final panController = useTextEditingController();
    final aadhaarController = useTextEditingController();
    final otpControllers = useMemoized(
      () => List.generate(6, (_) => TextEditingController()),
      const [],
    );
    final otpFocusNodes = useMemoized(
      () => List.generate(6, (_) => FocusNode()),
      const [],
    );

    final isVerifyingPan = useState(false);
    final isSendingOtp = useState(false);
    final isVerifyingOtp = useState(false);

    final referenceId = useState('');
    final maskedAadhaar = useState('');
    final timerSeconds = useState(0);
    final timerTick = useRef<Timer?>(null);
    final successDialogShown = useState(false);

    void startTimer() {
      timerTick.value?.cancel();
      timerSeconds.value = 60;
      timerTick.value = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (timerSeconds.value <= 1) {
          timerSeconds.value = 0;
          timer.cancel();
          timerTick.value = null;
          return;
        }
        timerSeconds.value -= 1;
      });
    }

    useEffect(() {
      return () {
        timerTick.value?.cancel();
        for (final controller in otpControllers) {
          controller.dispose();
        }
        for (final node in otpFocusNodes) {
          node.dispose();
        }
      };
    }, const []);

    useEffect(() {
      if (!otpSent.value) {
        timerTick.value?.cancel();
        timerTick.value = null;
        timerSeconds.value = 0;
      }
      return null;
    }, [otpSent.value]);

    Future<void> verifyPan() async {
      final pan = panController.text.trim().toUpperCase();
      final panRegExp = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$');
      if (!panRegExp.hasMatch(pan)) {
        AppSnackbar.show('Please enter a valid PAN number.');
        return;
      }
      final deviceId = await deviceIdService.getDeviceId();
      if (deviceId == null || deviceId.isEmpty) {
        AppSnackbar.show('Unable to identify this device. Please try again.');
        return;
      }
      try {
        isVerifyingPan.value = true;
        final response = await repository.verifyPan(
          panNumber: pan,
          deviceId: deviceId,
        );
        if (!response.valid) {
          AppSnackbar.show(
            response.message.isEmpty
                ? 'PAN verification failed.'
                : response.message,
          );
          return;
        }
        panDone.value = true;
        step.value = _KycStep.aadhaar;
      } catch (e) {
        AppSnackbar.show('Unable to verify PAN. Please try again.');
      } finally {
        isVerifyingPan.value = false;
      }
    }

    Future<void> sendAadhaarOtp() async {
      final aadhaar = aadhaarController.text.replaceAll(RegExp(r'\s+'), '');
      if (aadhaar.length != 12) {
        AppSnackbar.show('Please enter a valid 12 digit Aadhaar number.');
        return;
      }
      final userId = await Utils.getUserId();
      if (userId == null || userId.isEmpty) {
        AppSnackbar.show('Missing user session. Please login again.');
        return;
      }
      final deviceId = await deviceIdService.getDeviceId();
      if (deviceId == null || deviceId.isEmpty) {
        AppSnackbar.show('Unable to identify this device. Please try again.');
        return;
      }
      try {
        isSendingOtp.value = true;
        final response = await repository.sendAadhaarOtp(
          userId: userId,
          aadhaar: aadhaar,
          deviceId: deviceId,
        );
        if (!response.success || response.referenceId.isEmpty) {
          AppSnackbar.show(
            response.message.isEmpty
                ? 'Unable to send OTP. Please try again.'
                : response.message,
          );
          return;
        }
        referenceId.value = response.referenceId;
        maskedAadhaar.value = response.maskedAadhaar;
        otpSent.value = true;
        startTimer();
      } catch (e) {
        AppSnackbar.show('Unable to send OTP. Please try again.');
      } finally {
        isSendingOtp.value = false;
      }
    }

    Future<void> verifyOtp() async {
      final otp = otpControllers.map((c) => c.text).join();
      if (otp.length != 6) {
        AppSnackbar.show('Please enter valid OTP.');
        return;
      }
      try {
        isVerifyingOtp.value = true;
        final userId = await Utils.getUserId();
        if (userId == null || userId.isEmpty) {
          AppSnackbar.show('Missing user session. Please login again.');
          return;
        }
        final response = await repository.verifyAadhaarOtp(
          userId: userId,
          referenceId: referenceId.value,
          otp: otp,
        );
        if (!response.success) {
          AppSnackbar.show(
            response.message.isEmpty
                ? 'OTP verification failed.'
                : response.message,
          );
          return;
        }
        await ref.read(profileControllerProvider.notifier).fetchProfile();
        aadhaarDone.value = true;
        step.value = _KycStep.complete;
        if (!successDialogShown.value) {
          successDialogShown.value = true;
          await KDialog.instance.openDialog(
            barrierDismissible: false,
            dialog: _KycSuccessDialog(
              onNotNow: () => navigatorKey.currentState?.pop(),
              onAddBankAccount: () {
                navigatorKey.currentState?.pop();
                navigatorKey.currentState?.push(
                  MaterialPageRoute(
                    builder: (_) => const AddBankAccountView(
                      redirectToHomeOnSuccess: true,
                    ),
                  ),
                );
              },
            ),
          );
        }
      } catch (e) {
        AppSnackbar.show('OTP verification failed. Please try again.');
      } finally {
        isVerifyingOtp.value = false;
      }
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
          step.value == _KycStep.complete
              ? 'KYC Completed'
              : 'Identity Verification',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.help_outline, color: AppColors.textPrimary),
          ),
        ],
      ),
      bottomNavigationBar: step.value == _KycStep.complete
          ? SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(16.w, 0.h, 16.w, 18.h),
                child: CustomElevatedButton(
                  label: 'Back To Home',
                  uppercaseLabel: false,
                  height: 42.h,
                  onPressed: () async {
                    await ref
                        .read(profileControllerProvider.notifier)
                        .fetchProfile();
                    navigatorKey.currentState
                        ?.popUntil((route) => route.isFirst);
                  },
                ),
              ),
            )
          : SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(16.w, 0.h, 16.w, 18.h),
                child: CustomElevatedButton(
                  label: step.value == _KycStep.pan
                      ? 'Verify PAN'
                      : otpSent.value
                          ? 'Verify OTP'
                          : 'Verify Aadhaar',
                  uppercaseLabel: false,
                  height: 42.h,
                  onPressed: (isVerifyingPan.value ||
                          isSendingOtp.value ||
                          isVerifyingOtp.value)
                      ? null
                      : step.value == _KycStep.pan
                          ? verifyPan
                          : otpSent.value
                              ? verifyOtp
                              : sendAadhaarOtp,
                ),
              ),
            ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (step.value != _KycStep.complete) ...[
                _KycStepHeader(
                  currentStep: step.value,
                  panDone: panDone.value,
                  aadhaarDone: aadhaarDone.value,
                ),
                SizedBox(height: 18.h),
              ],
              if (step.value == _KycStep.pan)
                _PanStep(
                  controller: panController,
                  loading: isVerifyingPan.value,
                ),
              if (step.value == _KycStep.aadhaar)
                _AadhaarStep(
                  controller: aadhaarController,
                  loading: isSendingOtp.value,
                  showOtp: otpSent.value,
                  secondsRemaining: timerSeconds.value,
                  onResend: timerSeconds.value == 0 ? sendAadhaarOtp : null,
                  onChangeAadhaar: () {
                    for (final controller in otpControllers) {
                      controller.clear();
                    }
                    otpSent.value = false;
                    timerTick.value?.cancel();
                    timerTick.value = null;
                    timerSeconds.value = 0;
                  },
                  otpControllers: otpControllers,
                  otpFocusNodes: otpFocusNodes,
                  verifyLoading: isVerifyingOtp.value,
                ),
              if (step.value == _KycStep.complete)
                _CompleteStep(
                  panNumber: panController.text,
                  aadhaarNumber: maskedAadhaar.value.isNotEmpty
                      ? maskedAadhaar.value
                      : aadhaarController.text,
                ),
              if (step.value != _KycStep.complete) ...[
                SizedBox(height: 12.h),
                _ConsentRow(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

enum _KycStep { pan, aadhaar, complete }

class _KycStepHeader extends HookWidget {
  const _KycStepHeader({
    required this.currentStep,
    required this.panDone,
    required this.aadhaarDone,
  });

  final _KycStep currentStep;
  final bool panDone;
  final bool aadhaarDone;

  @override
  Widget build(BuildContext context) {
    final stepIndex = _stepIndex(currentStep);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _StepIndicator(
          label: 'PAN',
          active: stepIndex >= 0,
          completed: panDone,
          index: 1,
        ),
        _StepLine(active: stepIndex >= 1),
        _StepIndicator(
          label: 'Aadhaar',
          active: stepIndex >= 1,
          completed: aadhaarDone,
          index: 2,
        ),
        _StepLine(active: stepIndex >= 2),
        _StepIndicator(
          label: 'Complete',
          active: stepIndex >= 2,
          completed: currentStep == _KycStep.complete,
          index: 3,
        ),
      ],
    );
  }
}

int _stepIndex(_KycStep step) {
  switch (step) {
    case _KycStep.pan:
      return 0;
    case _KycStep.aadhaar:
      return 1;
    case _KycStep.complete:
      return 2;
  }
}

class _StepIndicator extends HookWidget {
  const _StepIndicator({
    required this.label,
    required this.active,
    required this.completed,
    required this.index,
  });

  final String label;
  final bool active;
  final bool completed;
  final int index;

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFFE85A2C);
    final borderColor = completed || active ? activeColor : Colors.black12;
    final textColor = completed || active
        ? AppColors.textPrimary
        : AppColors.textPrimary.withOpacity(0.45);
    return Column(
      children: [
        Container(
          width: 26.w,
          height: 26.w,
          decoration: BoxDecoration(
            color: completed ? activeColor : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: borderColor),
          ),
          alignment: Alignment.center,
          child: completed
              ? Icon(Icons.check, size: 14.r, color: Colors.white)
              : Text(
                  index.toString(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: active ? activeColor : textColor,
                        fontWeight: FontWeight.w700,
                      ),
                ),
        ),
        SizedBox(height: 6.h),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

class _StepLine extends HookWidget {
  const _StepLine({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 2.h,
        color: active ? const Color(0xFFE85A2C) : Colors.black12,
      ),
    );
  }
}

class _PanStep extends HookWidget {
  const _PanStep({required this.controller, required this.loading});

  final TextEditingController controller;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PanLogoRow(controller: controller),
        if (loading) ...[
          SizedBox(height: 10.h),
          const _LoadingDots(),
        ],
      ],
    );
  }
}

class _AadhaarStep extends HookWidget {
  const _AadhaarStep({
    required this.controller,
    required this.loading,
    required this.showOtp,
    required this.secondsRemaining,
    required this.onResend,
    required this.onChangeAadhaar,
    required this.otpControllers,
    required this.otpFocusNodes,
    required this.verifyLoading,
  });

  final TextEditingController controller;
  final bool loading;
  final bool showOtp;
  final int secondsRemaining;
  final VoidCallback? onResend;
  final VoidCallback onChangeAadhaar;
  final List<TextEditingController> otpControllers;
  final List<FocusNode> otpFocusNodes;
  final bool verifyLoading;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AadhaarLogoRow(controller: controller),
        if (showOtp) ...[
          SizedBox(height: 18.h),
          Text(
            'Verify OTP',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          SizedBox(height: 6.h),
          Text(
            'Enter the 6-digit OTP sent to your Aadhaar-linked mobile number.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textPrimary.withOpacity(0.6),
                ),
          ),
          SizedBox(height: 10.h),
          Text(
            'Enter OTP',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          SizedBox(height: 8.h),
          PinInputRow(
            controllers: otpControllers,
            focusNodes: otpFocusNodes,
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Text(
                '00:${secondsRemaining.toString().padLeft(2, '0')}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textPrimary.withOpacity(0.6),
                      fontWeight: FontWeight.w600,
                    ),
              ),
              SizedBox(width: 8.w),
              GestureDetector(
                onTap: onResend,
                child: Text(
                  'Resend OTP',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: onResend == null
                            ? AppColors.textPrimary.withOpacity(0.4)
                            : AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              Text(
                'Entered the wrong Aadhaar number? ',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textPrimary.withOpacity(0.6),
                    ),
              ),
              GestureDetector(
                onTap: onChangeAadhaar,
                child: Text(
                  'Change Aadhaar',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
          if (verifyLoading) ...[
            SizedBox(height: 10.h),
            const _LoadingDots(),
          ],
        ],
        if (loading) ...[
          SizedBox(height: 10.h),
          const _LoadingDots(),
        ],
      ],
    );
  }
}

class _KycSuccessDialog extends StatelessWidget {
  const _KycSuccessDialog({
    required this.onNotNow,
    required this.onAddBankAccount,
  });

  final VoidCallback onNotNow;
  final VoidCallback onAddBankAccount;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28.r),
      ),
      insetPadding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 24.h),
      child: Container(
        padding: EdgeInsets.fromLTRB(20.w, 22.h, 20.w, 24.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28.r),
          gradient: const LinearGradient(
            colors: [Color(0xFFF38A5F), Color(0xFF0B3A73)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 74.r,
              width: 74.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF0A8A40),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Icon(
                Icons.check,
                color: Colors.white,
                size: 36.r,
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'KYC Completed\nSuccessfully 🎉',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
            ),
            SizedBox(height: 12.h),
            Text(
              'Your identity verification is complete.\n'
              'To withdraw your e-Coins rewards,\n'
              'please add your bank account details.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                    height: 1.5,
                  ),
            ),
            SizedBox(height: 20.h),
            Row(
              children: [
                Expanded(
                  child: SizedBox(height: 44.h,
                    child: OutlinedButton(
                      onPressed: onNotNow,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24.r),
                        ),
                      ),
                      child: Text(
                        'Not Now',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: SizedBox(height: 44.h,
                    child: ElevatedButton(
                      onPressed: onAddBankAccount,
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: const Color(0xFFE95A2C),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24.r),
                        ),
                      ),
                      child: Text(
                        'Add Bank',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CompleteStep extends HookWidget {
  const _CompleteStep({
    required this.panNumber,
    required this.aadhaarNumber,
  });

  final String panNumber;
  final String aadhaarNumber;

  @override
  Widget build(BuildContext context) {
    final aadhaarDisplay = aadhaarNumber.contains('X')
        ? aadhaarNumber
        : maskAadhaar(aadhaarNumber);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Column(
            children: [
              Container(
                width: 44.w,
                height: 44.w,
                decoration: const BoxDecoration(
                  color: Color(0xFF1B8E36),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white),
              ),
              SizedBox(height: 8.h),
              Text(
                'Identity Verified',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              SizedBox(height: 6.h),
              Text(
                'Your identity has been verified successfully.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textPrimary.withOpacity(0.6),
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        SizedBox(height: 18.h),
        Text(
          'PAN Card',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
        ),
        SizedBox(height: 8.h),
        _KycCard(
          background: const Color(0xFFE6F1FF),
          leftLogo: FileConstants.nsdl,
          centerLogo: FileConstants.satyamev,
          rightLogo: FileConstants.govtindia,
          label: 'PAN Number',
          value: maskPan(panNumber),
        ),
        SizedBox(height: 16.h),
        Text(
          'Aadhaar Card',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
        ),
        SizedBox(height: 8.h),
        _KycCard(
          background: Colors.white,
          leftLogo: FileConstants.satyamev,
          centerLogo: FileConstants.aadhaar,
          rightLogo: FileConstants.govtindia,
          label: 'Aadhaar Number',
          value: aadhaarDisplay,
        ),
      ],
    );
  }
}

class _KycCard extends HookWidget {
  const _KycCard({
    required this.background,
    required this.leftLogo,
    required this.centerLogo,
    required this.rightLogo,
    required this.label,
    required this.value,
  });

  final Color background;
  final String leftLogo;
  final String centerLogo;
  final String rightLogo;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.lightBorder.withOpacity(0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Image.asset(leftLogo, height: 20.h),
              Image.asset(centerLogo, height: 20.h),
              Image.asset(rightLogo, height: 20.h),
            ],
          ),
          SizedBox(height: 10.h),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textPrimary.withOpacity(0.7),
                  fontWeight: FontWeight.w600,
                ),
          ),
          SizedBox(height: 4.h),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _PanLogoRow extends HookWidget {
  const _PanLogoRow({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: const Color(0xFFE6F1FF),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Image.asset(FileConstants.nsdl, height: 22.h),
              Image.asset(FileConstants.satyamev, height: 22.h),
              Image.asset(FileConstants.govtindia, height: 22.h),
            ],
          ),
          SizedBox(height: 14.h),
          Text(
            'PAN Card Number',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textPrimary.withOpacity(0.7),
                  fontWeight: FontWeight.w600,
                ),
          ),
          SizedBox(height: 6.h),
          TextField(
            controller: controller,
            textCapitalization: TextCapitalization.characters,
            decoration: _inputDecoration('ABCDE1234E'),
          ),
        ],
      ),
    );
  }
}

class _AadhaarLogoRow extends HookWidget {
  const _AadhaarLogoRow({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.lightBorder.withOpacity(0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Image.asset(FileConstants.satyamev, height: 20.h),
              Image.asset(FileConstants.govt, height: 20.h),
              Image.asset(FileConstants.aadhaar, height: 20.h),
            ],
          ),
          SizedBox(height: 14.h),
          Text(
            'Enter 12 Digit Aadhaar Number',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textPrimary.withOpacity(0.7),
                  fontWeight: FontWeight.w600,
                ),
          ),
          SizedBox(height: 6.h),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: _inputDecoration('1234 5678 9012'),
          ),
        ],
      ),
    );
  }
}

class _ConsentRow extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final isChecked = useState(false);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => isChecked.value = !isChecked.value,
          borderRadius: BorderRadius.circular(4.r),
          child: Container(
            width: 16.w,
            height: 16.w,
            margin: EdgeInsets.only(top: 2.h),
            decoration: BoxDecoration(
              color: isChecked.value ? const Color(0xFFE85A2C) : Colors.white,
              borderRadius: BorderRadius.circular(4.r),
              border: Border.all(
                color: isChecked.value
                    ? const Color(0xFFE85A2C)
                    : AppColors.lightBorder,
              ),
            ),
            child: isChecked.value
                ? Icon(Icons.check, size: 12.r, color: Colors.white)
                : null,
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: InkWell(
            onTap: () => isChecked.value = !isChecked.value,
            child: Text(
              'By entering the details, you allow e-Rupaiya to verify your Aadhaar on your behalf.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textPrimary.withOpacity(0.6),
                  ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LoadingDots extends HookWidget {
  const _LoadingDots();

  @override
  Widget build(BuildContext context) {
    final active = useState(0);
    useEffect(() {
      final timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
        active.value = (active.value + 1) % 3;
      });
      return timer.cancel;
    }, const []);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        3,
        (index) => Container(
          margin: EdgeInsets.symmetric(horizontal: 4.w),
          width: 6.w,
          height: 6.w,
          decoration: BoxDecoration(
            color: active.value == index
                ? const Color(0xFFE85A2C)
                : Colors.black12,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

InputDecoration _inputDecoration(String hint) {
  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(
      color: AppColors.textPrimary.withOpacity(0.4),
      fontWeight: FontWeight.w600,
    ),
    filled: true,
    fillColor: Colors.white,
    contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.r),
      borderSide: BorderSide(color: AppColors.lightBorder.withOpacity(0.7)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.r),
      borderSide: const BorderSide(color: Color(0xFFE85A2C)),
    ),
  );
}
