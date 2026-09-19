// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:ui';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:pinput/pinput.dart';
import 'package:sms_autofill/sms_autofill.dart';

import '../../../config/app_env.dart';
import '../../../constants/app_error_messages.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/file_constants.dart';
import '../../../constants/routes_constant.dart';
import '../../../constants/storage_keys.dart';
import '../../../services/logger_service.dart';
import '../../../services/phone_hint_service.dart';
import '../../../services/secure_storage_service.dart';
import '../../../widgets/app_snackbar.dart';
import '../../../widgets/grey_text_form_field.dart';
import '../../profile/controllers/profile_controller.dart';
import '../components/auth_brand_header.dart';
import '../components/otp_verification_card.dart';
import '../components/phone_number_input_card.dart';
import '../controllers/auth_controller.dart';
import '../models/auth_flow.dart';
import '../utils/temporary_block_flow_launcher.dart';
import 'reset_mpin_view.dart';

enum _LoginStep {
  mobile,
  pin,
  otp,
}

void _debugLog(String message) {
  if (!AppEnv.enableLogs || !kDebugMode) return;
  debugPrint(message);
}

class LoginView extends HookConsumerWidget {
  const LoginView({super.key});

  static const int _otpLength = 4;
  static const String _genericErrorMessage = AppErrorMessages.generic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final step = useState(_LoginStep.mobile);
    final phoneController = useTextEditingController();
    final allowConsent = useState(false);
    final referralCode = useState<String?>(null);
    final storage = useMemoized(() => SecureStorageService.instance);

    final pinController = useTextEditingController();
    final pinFocusNode = useFocusNode();

    final otpControllers = useMemoized(
      () => List.generate(_otpLength, (_) => TextEditingController()),
      const [],
    );
    final otpFocusNodes = useMemoized(
        () => List.generate(_otpLength, (_) => FocusNode()), const []);
    final otpErrorText = useState<String?>(null);
    final remainingSeconds = useState(0);
    final timerRef = useRef<Timer?>(null);

    useEffect(() {
      Future<void> applyReferralCode(String code) async {
        final trimmed = code.trim();
        if (trimmed.isEmpty) return;
        referralCode.value = trimmed;
        await storage.write(
          key: StorageKeys.pendingReferralCode,
          value: trimmed,
        );
      }

      Future<void> handleIncomingUri(Uri? uri) async {
        if (uri == null) return;
        final path = uri.path.toLowerCase();
        if (!path.contains('/referral')) return;
        final code = uri.queryParameters['code'] ?? '';
        if (code.isEmpty) return;
        await applyReferralCode(code);
      }

      Future.microtask(() async {
        final stored = await storage.read(key: StorageKeys.pendingReferralCode);
        if (stored != null && stored.trim().isNotEmpty) {
          referralCode.value = stored.trim();
        }
        try {
          final initialUri = await AppLinks().getInitialLink();
          await handleIncomingUri(initialUri);
        } catch (e, stackTrace) {
          logger.error('Failed to resolve initial referral deep link',
              error: e, stackTrace: stackTrace);
        }
      });

      final sub = AppLinks().uriLinkStream.listen(
            (uri) => handleIncomingUri(uri),
            onError: (_) {},
          );
      return () {
        sub.cancel();
        pinController.dispose();
        pinFocusNode.dispose();
        for (final controller in otpControllers) {
          controller.dispose();
        }
        for (final node in otpFocusNodes) {
          node.dispose();
        }
        timerRef.value?.cancel();
      };
    }, const []);

    useEffect(() {
      Future.microtask(() async {
        if (phoneController.text.trim().isNotEmpty) return;
        final hint = await PhoneHintService.getPhoneNumberHint();
        if (hint == null) return;
        final digits = hint.replaceAll(RegExp(r'\D'), '');
        if (digits.isEmpty) return;
        final normalized =
            digits.length > 10 ? digits.substring(digits.length - 10) : digits;
        if (normalized.length != 10) return;
        if (phoneController.text.trim().isNotEmpty) return;
        phoneController.text = normalized;
      });
      return null;
    }, const []);

    void startOtpTimer() {
      timerRef.value?.cancel();
      timerRef.value = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (remainingSeconds.value <= 0) {
          timer.cancel();
          timerRef.value = null;
        } else {
          remainingSeconds.value--;
        }
      });
    }

    void resetToMobileStep() {
      step.value = _LoginStep.mobile;
      otpErrorText.value = null;
      remainingSeconds.value = 0;
      timerRef.value?.cancel();
      timerRef.value = null;
      for (final controller in otpControllers) {
        controller.clear();
      }
    }

    useEffect(() {
      if (step.value == _LoginStep.otp) {
        remainingSeconds.value = 59;
        otpErrorText.value = null;
        startOtpTimer();
      } else {
        timerRef.value?.cancel();
        timerRef.value = null;
      }
      return null;
    }, [step.value]);

    void resetToMobile() {
      step.value = _LoginStep.mobile;
      otpErrorText.value = null;
      pinController.clear();
      for (final controller in otpControllers) {
        controller.clear();
      }
    }

    Future<void> handleMobileContinue() async {
      final phone = phoneController.text.trim();
      debugPrint(
        '[LoginView] Continue tapped -> mobile=$phone, consent=${allowConsent.value}',
      );
      if (phone.isEmpty || phone.length != 10) {
        debugPrint('[LoginView] Continue blocked -> invalid mobile');
        AppSnackbar.show('Enter a valid 10-digit mobile number');
        return;
      }
      if (!allowConsent.value) {
        debugPrint('[LoginView] Continue blocked -> consent not allowed');
        AppSnackbar.show('Please allow access to continue');
        return;
      }
      final flow = await ref
          .read(authControllerProvider.notifier)
          .checkLogin(mobile: phone);
      debugPrint('[LoginView] checkLogin completed -> flow=$flow');
      if (flow == null) {
        final latestState = ref.read(authControllerProvider);
        debugPrint(
          '[LoginView] checkLogin returned null -> error=${latestState.errorMessage}',
        );
        AppSnackbar.show(
          latestState.errorMessage ?? _genericErrorMessage,
          type: AppSnackbarType.error,
        );
        return;
      }
      if (flow == AuthFlow.login) {
        debugPrint('[LoginView] Navigating to PIN step');
        step.value = _LoginStep.pin;
      } else {
        debugPrint('[LoginView] Navigating to OTP route -> mobile=$phone');
        resetToMobile();
        if (!context.mounted) return;
        context.push(RouteConstants.otp, extra: phone);
      }
    }

    Future<void> handlePinLogin() async {
      final phone = phoneController.text.trim();
      if (phone.isEmpty || phone.length != 10) {
        AppSnackbar.show('Enter a valid 10-digit mobile number');
        return;
      }
      final pin = pinController.text.trim();
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
        pinController.clear();
        pinFocusNode.requestFocus();
        if (!context.mounted) return;
        await launchNewDeviceVerificationFlow(
          context: context,
          phoneNumber: phone,
          verificationId: result.verificationId ?? '',
        );
      } else if (result.isSuspected) {
        pinController.clear();
        pinFocusNode.requestFocus();
        if (!context.mounted) return;
        await launchTemporaryBlockedFlow(
          context: context,
          phoneNumber: phone,
          isKycVerified: result.isKycVerified == true,
        );
      } else {
        AppSnackbar.show(
          result.message ?? _genericErrorMessage,
          type: AppSnackbarType.error,
        );
        pinController.clear();
        pinFocusNode.requestFocus();
      }
    }

    Future<void> handleOtpVerify() async {
      final otp = otpControllers.map((c) => c.text).join();
      if (otp.length < otpControllers.length) {
        otpErrorText.value = 'Please enter the $_otpLength-digit OTP.';
        return;
      }
      otpErrorText.value = null;
      final success =
          await ref.read(authControllerProvider.notifier).verifyOtp(otp: otp);
      if (success) {
        if (context.mounted) {
          context.go(RouteConstants.otpSuccess);
        }
      } else {
        final latestState = ref.read(authControllerProvider);
        otpErrorText.value = latestState.errorMessage ??
            "Oops! That OTP doesn't seem right. Please check and re-enter.";
      }
    }

    useEffect(() {
      if (step.value != _LoginStep.otp) return null;
      var isDisposed = false;
      final autoFill = SmsAutoFill();
      final sub = autoFill.code.listen((code) {
        if (isDisposed) return;
        final digits = code.replaceAll(RegExp(r'\D'), '');
        if (digits.isEmpty) return;
        final trimmed = digits.length > _otpLength
            ? digits.substring(0, _otpLength)
            : digits;
        for (var i = 0; i < otpControllers.length; i++) {
          otpControllers[i].text = i < trimmed.length ? trimmed[i] : '';
        }
        if (trimmed.length == otpControllers.length) {
          otpFocusNodes.last.unfocus();
          otpErrorText.value = null;
          Future.microtask(handleOtpVerify);
        }
      });

      () async {
        try {
          final signature = await autoFill.getAppSignature;
          _debugLog(
            'SMS Retriever app signature: ${signature.isEmpty ? "<empty>" : signature}',
          );
          await autoFill.listenForCode(
            smsCodeRegexPattern: '\\d{$_otpLength}',
          );
          _debugLog('listenForCode started');
        } catch (e, stackTrace) {
          logger.error('Failed to start OTP autofill listener in login view',
              error: e, stackTrace: stackTrace);
        }
      }();

      return () {
        isDisposed = true;
        sub.cancel();
        autoFill.unregisterListener();
      };
    }, [step.value]);

    Future<void> handleResendOtp() async {
      final mobile = phoneController.text.trim();
      if (mobile.isEmpty || mobile.length != 10) {
        AppSnackbar.show('Enter a valid 10-digit mobile number');
        return;
      }
      final flow = await ref
          .read(authControllerProvider.notifier)
          .checkLogin(mobile: mobile);
      if (flow != null) {
        remainingSeconds.value = 59;
        otpErrorText.value = null;
        startOtpTimer();
        AppSnackbar.show('OTP resent to $mobile');
      } else {
        final latestState = ref.read(authControllerProvider);
        AppSnackbar.show(
          latestState.errorMessage ?? _genericErrorMessage,
          type: AppSnackbarType.error,
        );
      }
    }

    Widget buildCard({required Widget child}) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28.r),
          boxShadow: const [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 30,
              offset: Offset(0, 14),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
          child: child,
        ),
      );
    }

    Widget buildPinCard() {
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
      final pinCursor = Container(
        width: 2.w,
        height: 22.h,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(2.r),
        ),
      );

      return buildCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome Back',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 20.sp,
                    color: AppColors.textPrimary,
                  ),
            ),
            SizedBox(height: 4.h),
            Text(
              'Log in to continue earning rewards.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textPrimary.withOpacity(0.6),
                  ),
            ),
            SizedBox(height: 14.h),
            Text(
              'Enter Mobile Number',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
            ),
            SizedBox(height: 6.h),
            Stack(
              alignment: Alignment.centerRight,
              children: [
                GreyTextFormField(
                  controller: phoneController,
                  enabled: false,
                  isNumber: true,
                ),
                Positioned(
                  right: 8.w,
                  child: IconButton(
                    onPressed: authState.isSubmitting ? null : resetToMobile,
                    icon: Icon(
                      Icons.edit,
                      size: 18.sp,
                      color: AppColors.textPrimary.withOpacity(0.7),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 14.h),
            Text(
              'Enter PIN',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
            ),
            SizedBox(height: 6.h),
            LayoutBuilder(
              builder: (context, constraints) {
                final totalWidth = constraints.maxWidth;
                const gap = 10.0;
                final fieldWidth = (totalWidth - (gap * 3)) / 4;
                final stretchedTheme = pinTheme.copyWith(width: fieldWidth);
                return Pinput(
                  controller: pinController,
                  focusNode: pinFocusNode,
                  length: _otpLength,
                  enabled: !authState.isSubmitting,
                  obscureText: true,
                  obscuringCharacter: '●',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  defaultPinTheme: stretchedTheme,
                  focusedPinTheme: stretchedTheme.copyWith(
                    decoration: stretchedTheme.decoration?.copyWith(
                      border: Border.all(color: AppColors.primary, width: 1.5),
                    ),
                  ),
                  cursor: pinCursor,
                  separatorBuilder: (_) => const SizedBox(width: gap),
                  onCompleted: (_) => handlePinLogin(),
                );
              },
            ),
            SizedBox(height: 8.h),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: authState.isSubmitting
                    ? null
                    : () {
                        final mobile = phoneController.text.trim();
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => ResetMpinView(mobile: mobile),
                          ),
                        );
                      },
                child: Text(
                  'Forgot PIN ?',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    Widget buildOtpCard() {
      final timerText =
          '${(remainingSeconds.value ~/ 60).toString().padLeft(2, '0')}:${(remainingSeconds.value % 60).toString().padLeft(2, '0')}';
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          OtpVerificationCard(
            controllers: otpControllers,
            focusNodes: otpFocusNodes,
            onVerify: handleOtpVerify,
            onResend: remainingSeconds.value == 0 ? handleResendOtp : null,
            timerText: timerText,
            errorMessage: otpErrorText.value,
            isVerifying: authState.isSubmitting,
            canResend: remainingSeconds.value == 0,
            onInputChanged: () => otpErrorText.value = null,
          ),
          SizedBox(height: 12.h),
          const SizedBox.shrink(),
        ],
      );
    }

    Widget buildReferralBanner() {
      final code = referralCode.value;
      if (code == null || code.isEmpty) return const SizedBox.shrink();
      return Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 26.r,
              height: 26.r,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.redeem,
                size: 14,
                color: AppColors.primary,
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                'Referral code applied $code',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
      );
    }

    Widget buildContentCard() {
      final Widget content;
      switch (step.value) {
        case _LoginStep.mobile:
          content = PhoneNumberInputCard(
            controller: phoneController,
            onContinue: authState.isSubmitting ? null : handleMobileContinue,
            isConsentAllowed: allowConsent.value,
            onConsentChanged: (value) => allowConsent.value = value,
            isLoading: authState.isSubmitting,
            helperText: null,
            showHelper: false,
            enabled: !authState.isSubmitting,
          );
          break;
        case _LoginStep.pin:
          content = buildPinCard();
          break;
        case _LoginStep.otp:
          content = buildOtpCard();
          break;
      }
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          buildReferralBanner(),
          if (referralCode.value != null && referralCode.value!.isNotEmpty)
            SizedBox(height: 10.h),
          content,
        ],
      );
    }

    return PopScope(
      canPop: step.value == _LoginStep.mobile,
      onPopInvoked: (didPop) {
        if (didPop) return;
        if (step.value != _LoginStep.mobile) {
          resetToMobileStep();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: true,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final headerHeight = constraints.maxHeight * 0.62;

            return Stack(
              children: [
                Column(
                  children: [
                    Container(
                      height: headerHeight,
                      decoration: const BoxDecoration(
                        gradient: AppColors.authBackgroundGradient,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(20),
                          bottomRight: Radius.circular(20),
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
                  bottom: 126,
                  child: buildContentCard(),
                ),
                if (authState.isSubmitting && step.value == _LoginStep.pin)
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
                                  blurRadius: 18,
                                  offset: const Offset(0, 10),
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
                                  'Logging In...',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                        color: AppColors.textPrimary
                                            .withOpacity(0.8),
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                // SizedBox(height: 10.h),
                                // SizedBox(
                                //   height: 20.h,
                                //   width: 20.h,
                                //   child: const CircularProgressIndicator(
                                //     strokeWidth: 2.4,
                                //   ),
                                // ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
