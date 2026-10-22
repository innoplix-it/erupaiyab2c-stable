// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:ui';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:sms_autofill/sms_autofill.dart';

import '../../../config/app_env.dart';
import '../../../constants/app_error_messages.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/file_constants.dart';
import '../../../constants/routes_constant.dart';
import '../../../constants/storage_keys.dart';
import '../../../services/logger_service.dart';
import '../../../services/secure_storage_service.dart';
import '../hooks/use_login_phone_hint.dart';
import '../../../widgets/app_snackbar.dart';
import '../../profile/controllers/profile_controller.dart';
import '../components/auth_brand_header.dart';
import '../components/auth_mobile_step.dart';
import '../components/auth_feedback.dart';
import '../components/auth_step_parts.dart';
import '../components/auth_pin_step.dart';
import '../components/otp_verification_card.dart';
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

  static const int _pinLength = 4;
  static const int _otpLength = 6;
  static const String _genericErrorMessage = AppErrorMessages.generic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSubmitting = ref.watch(
      authControllerProvider.select((state) => state.isSubmitting),
    );
    final step = useState(_LoginStep.mobile);
    final phoneController = useTextEditingController();
    final mobileFocusNode = useFocusNode();
    final allowConsent = useState(false);
    final referralCode = useState<String?>(null);
    final storage = useMemoized(() => SecureStorageService.instance);

    final pinController = useTextEditingController();
    final pinFocusNode = useFocusNode();
    final pinShake = useAuthShakeController();
    final pinError = useState<String?>(null);

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
        for (final controller in otpControllers) {
          controller.dispose();
        }
        for (final node in otpFocusNodes) {
          node.dispose();
        }
        timerRef.value?.cancel();
      };
    }, const []);

    final onEmptyPhoneFieldTap = useLoginPhoneHint(
      phoneController: phoneController,
      mobileFocusNode: mobileFocusNode,
      enabled: step.value == _LoginStep.mobile,
    );

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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted || step.value != _LoginStep.mobile) return;
        showAuthKeyboard(mobileFocusNode);
      });
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
      pinError.value = null;
      pinController.clear();
      for (final controller in otpControllers) {
        controller.clear();
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted || step.value != _LoginStep.mobile) return;
        showAuthKeyboard(mobileFocusNode);
      });
    }

    Future<void> handleMobileContinue() async {
      final phone = phoneController.text.trim();
      _debugLog('[LoginView] Continue tapped -> mobile=$phone');
      if (phone.isEmpty || phone.length != 10) {
        _debugLog('[LoginView] Continue blocked -> invalid mobile');
        AppSnackbar.show('Enter a valid 10-digit mobile number');
        return;
      }
      // Figma mobile step uses Terms/Privacy footer links (no checkbox).
      allowConsent.value = true;
      final flow = await ref
          .read(authControllerProvider.notifier)
          .checkLogin(mobile: phone);
      _debugLog('[LoginView] checkLogin completed -> flow=$flow');
      if (flow == null) {
        final latestState = ref.read(authControllerProvider);
        _debugLog(
          '[LoginView] checkLogin returned null -> error=${latestState.errorMessage}',
        );
        AppSnackbar.show(
          latestState.errorMessage ?? _genericErrorMessage,
          type: AppSnackbarType.error,
        );
        return;
      }
      if (flow == AuthFlow.login) {
        _debugLog('[LoginView] Navigating to PIN step');
        step.value = _LoginStep.pin;
      } else {
        _debugLog('[LoginView] Navigating to OTP route -> mobile=$phone');
        resetToMobile();
        if (!context.mounted) return;
        // Push without unfocusing — keypad stays up into Verify OTP.
        context.push(RouteConstants.otp, extra: phone);
      }
    }

    Future<void> handlePinLogin() async {
      if (ref.read(authControllerProvider).isSubmitting) return;
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
        if (isAuthConnectivityError(result.message)) {
          AppSnackbar.show(
            result.message ?? _genericErrorMessage,
            type: AppSnackbarType.error,
          );
        } else {
          pinShake.shake();
          pinError.value = authInvalidPinMessage;
        }
        pinController.clear();
        showAuthKeyboard(pinFocusNode);
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
          // Keep focus so Verify does not drop the lifted layout.
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
            isVerifying: isSubmitting,
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
              child: Icon(
                Icons.redeem,
                size: 14.r,
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

    final onMobile = step.value == _LoginStep.mobile;
    final onPin = step.value == _LoginStep.pin;
    final referralBanner = (referralCode.value?.isNotEmpty ?? false)
        ? buildReferralBanner()
        : null;

    Widget buildMobileStep() {
      return AuthMobileStep(
        controller: phoneController,
        isLoading: isSubmitting && onMobile,
        layoutActive: onMobile,
        onContinue: isSubmitting ? null : handleMobileContinue,
        referralBanner: referralBanner,
        focusNode: mobileFocusNode,
        onEmptyPhoneFieldTap: onEmptyPhoneFieldTap,
      );
    }

    Widget buildPinStep() {
      return AuthPinStep(
        mobileController: phoneController,
        pinController: pinController,
        pinFocusNode: pinFocusNode,
        shakeController: pinShake,
        errorText: pinError.value,
        onPinChanged: (value) {
          if (value.isNotEmpty) pinError.value = null;
        },
        pinLength: _pinLength,
        isLoading: isSubmitting && onPin,
        layoutActive: onPin,
        onContinue: handlePinLogin,
        onEditMobile: resetToMobile,
        onForgotPin: () {
          final mobile = phoneController.text.trim();
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => ResetMpinView(mobile: mobile),
            ),
          );
        },
        referralBanner: referralBanner,
      );
    }

    Widget buildContentCard() {
      // The mobile and PIN steps are laid out full-bleed on the auth artwork;
      // OTP keeps the white card treatment.
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          buildReferralBanner(),
          if (referralCode.value != null && referralCode.value!.isNotEmpty)
            SizedBox(height: 10.h),
          buildOtpCard(),
        ],
      );
    }

    Widget buildLoggingInOverlay() {
      return Positioned.fill(
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
                      'Logging In...',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: AppColors.textPrimary.withOpacity(0.8),
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    Widget buildLoginBody() {
      if (step.value == _LoginStep.otp) {
        return LayoutBuilder(
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
                  bottom: 126,
                  child: buildContentCard(),
                ),
              ],
            );
          },
        );
      }

      return IndexedStack(
        index: onPin ? 1 : 0,
        sizing: StackFit.expand,
        children: [
          TickerMode(
            enabled: onMobile,
            child: RepaintBoundary(
              child: buildMobileStep(),
            ),
          ),
          TickerMode(
            enabled: onPin,
            child: RepaintBoundary(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  buildPinStep(),
                  if (isSubmitting && onPin) buildLoggingInOverlay(),
                ],
              ),
            ),
          ),
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
        // Body paints the peach gradient. The region under the keyboard
        // (resizeToAvoidBottomInset) is the Scaffold color — solid
        // loginPeachCoral (#DD5428) showed as an orange strip. White matches
        // the form band that sits above the keyboard.
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: true,
        body: buildLoginBody(),
      ),
    );
  }
}
