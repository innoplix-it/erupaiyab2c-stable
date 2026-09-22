// ignore_for_file: deprecated_member_use

import 'dart:async';

import 'package:e_rupaiya/constants/file_constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:pinput/pinput.dart';

import '../constants/app_colors.dart';
import '../features/profile/models/api_response_model.dart';
import '../features/profile/repositories/profile_repository.dart';
import '../firebase/explicit_firebase_options.dart';
import 'app_snackbar.dart';
import 'custom_elevated_button.dart';

class CompleteProfileDialog extends StatefulWidget {
  const CompleteProfileDialog({
    super.key,
    this.onCompleted,
  });

  final VoidCallback? onCompleted;

  @override
  State<CompleteProfileDialog> createState() => _CompleteProfileDialogState();
}

enum _ProfileStep { details, otp, done }

enum _OtpBannerType { success, error }

class _CompleteProfileDialogState extends State<CompleteProfileDialog> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();

  final _emailFocus = FocusNode();
  final _otpFocus = FocusNode();

  _ProfileStep _step = _ProfileStep.details;
  bool _isSubmitting = false;
  bool _otpVerified = false;
  bool _googleInitialized = false;

  static const int _otpLength = 6;
  static const int _otpResendCooldownSeconds = 59;
  Timer? _otpTimer;
  int _otpSecondsRemaining = 0;
  _OtpBannerType? _otpBannerType;
  String? _otpBannerMessage;

  @override
  void dispose() {
    _otpTimer?.cancel();
    _nameController.dispose();
    _emailController.dispose();
    _otpController.dispose();
    _emailFocus.dispose();
    _otpFocus.dispose();
    super.dispose();
  }

  bool _isValidEmail(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return false;
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(trimmed);
  }

  Future<void> _ensureFirebaseInitialized() async {
    if (Firebase.apps.isNotEmpty) return;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      await Firebase.initializeApp(
        options: ExplicitFirebaseOptions.androidErupiya,
      );
      return;
    }
    await Firebase.initializeApp();
  }

  Future<void> _continueWithGoogle() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      await _ensureFirebaseInitialized();
      if (!mounted) return;
      if (!_googleInitialized) {
        await GoogleSignIn.instance.initialize();
        _googleInitialized = true;
      }

      final googleUser = await GoogleSignIn.instance.authenticate(
        scopeHint: const ['email'],
      );
      if (!mounted) return;

      final idToken = googleUser.authentication.idToken;
      if (idToken == null || idToken.trim().isEmpty) {
        AppSnackbar.show('Unable to fetch Google idToken. Please try again.');
        return;
      }
      final authz = await googleUser.authorizationClient.authorizeScopes(
        const ['email'],
      );
      if (!mounted) return;
      final credential = GoogleAuthProvider.credential(
        accessToken: authz.accessToken,
        idToken: idToken,
      );

      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      if (!mounted) return;
      final user = userCredential.user;
      final name = (user?.displayName ?? '').trim();
      final email = (user?.email ?? '').trim();
      final firebaseIdToken = await user?.getIdToken(true);
      if (!mounted) return;

      if (name.isEmpty || email.isEmpty) {
        AppSnackbar.show(
          'Unable to fetch name/email from Google. Please try again.',
        );
        return;
      }
      if (firebaseIdToken == null || firebaseIdToken.trim().isEmpty) {
        AppSnackbar.show('Unable to fetch idToken. Please try again.');
        return;
      }

      _nameController.text = name;
      _emailController.text = email;

      final repo = ProfileRepository();
      final ApiResponse resp = await repo.completeProfile(
        name: name,
        email: email,
        type: 'google',
        googleToken: firebaseIdToken,
      );
      if (!mounted) return;
      if (!resp.success) {
        AppSnackbar.show(
          resp.message.isNotEmpty ? resp.message : 'Google sign-in failed',
        );
        return;
      }

      setState(() => _step = _ProfileStep.done);
      AppSnackbar.show(
        resp.message.isNotEmpty
            ? resp.message
            : 'Profile completed successfully',
        backgroundColor: AppColors.primary,
        textColor: Colors.white,
      );
    } catch (e) {
      final message = _friendlyGoogleErrorMessage(e);
      if (message != null && message.trim().isNotEmpty) {
        AppSnackbar.show(message);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String? _friendlyGoogleErrorMessage(Object error) {
    if (error is FirebaseAuthException) {
      return (error.message ?? '').trim().isNotEmpty
          ? error.message
          : 'Google sign-in failed. Please try again.';
    }

    if (error is PlatformException) {
      // Common cases: user cancellation / in-progress sign-in.
      final code = (error.code).toLowerCase();
      if (code.contains('canceled') || code.contains('cancelled')) {
        return null; // user backed out: don't show as an error
      }
      if (code.contains('sign_in_canceled') ||
          code.contains('sign_in_cancel')) {
        return null;
      }
      if (code.contains('network') || code.contains('network_error')) {
        return 'Network error during Google sign-in. Please try again.';
      }
      if ((error.message ?? '').trim().isNotEmpty) return error.message;
    }

    return 'Google sign-in failed. Please try again.';
  }

  void _setOtpBanner(_OtpBannerType type, String message) {
    setState(() {
      _otpBannerType = type;
      _otpBannerMessage = message.trim();
    });
  }

  void _clearOtpBanner() {
    if (_otpBannerType == null && (_otpBannerMessage ?? '').isEmpty) return;
    setState(() {
      _otpBannerType = null;
      _otpBannerMessage = null;
    });
  }

  void _startOtpResendTimer() {
    _otpTimer?.cancel();
    setState(() => _otpSecondsRemaining = _otpResendCooldownSeconds);
    _otpTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      if (_otpSecondsRemaining <= 0) {
        timer.cancel();
        return;
      }
      setState(() => _otpSecondsRemaining = _otpSecondsRemaining - 1);
    });
  }

  String _formatOtpTimer(int seconds) {
    final clamped = seconds.clamp(0, 3599);
    final minutes = (clamped ~/ 60).toString().padLeft(2, '0');
    final secs = (clamped % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  Future<void> _sendOtp() async {
    if (_isSubmitting) return;
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    if (name.isEmpty) {
      AppSnackbar.show('Please enter your name');
      return;
    }
    if (!_isValidEmail(email)) {
      AppSnackbar.show('Please enter a valid email');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _otpVerified = false;
    });
    try {
      final repo = ProfileRepository();
      final ApiResponse resp = await repo.completeProfile(
        name: name,
        email: email,
        type: 'manual',
      );
      if (!mounted) return;
      if (!resp.success) {
        AppSnackbar.show(
            resp.message.isNotEmpty ? resp.message : 'Failed to send OTP');
        return;
      }
      setState(() => _step = _ProfileStep.otp);
      _otpController.clear();
      _clearOtpBanner();
      _startOtpResendTimer();
      _otpFocus.requestFocus();
      AppSnackbar.show(
        resp.message.isNotEmpty ? resp.message : 'OTP sent to $email',
        backgroundColor: AppColors.primary,
        textColor: Colors.white,
      );
    } catch (e) {
      AppSnackbar.show('Failed to send OTP. Please try again.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _resendOtp() async {
    if (_isSubmitting) return;
    if (_otpSecondsRemaining > 0) return;
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    if (name.isEmpty || !_isValidEmail(email)) return;

    setState(() {
      _isSubmitting = true;
      _otpVerified = false;
    });
    try {
      final repo = ProfileRepository();
      final ApiResponse resp = await repo.completeProfile(
        name: name,
        email: email,
        type: 'manual',
      );
      if (!mounted) return;
      if (!resp.success) {
        _setOtpBanner(
          _OtpBannerType.error,
          resp.message.isNotEmpty ? resp.message : 'Something Went Wrong',
        );
        return;
      }
      _otpController.clear();
      _clearOtpBanner();
      _startOtpResendTimer();
      _otpFocus.requestFocus();
    } catch (_) {
      if (!mounted) return;
      _setOtpBanner(_OtpBannerType.error, 'Something Went Wrong');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _verifyOtp() async {
    if (_isSubmitting) return;
    final otp = _otpController.text.trim();
    if (otp.length != _otpLength) {
      _setOtpBanner(
          _OtpBannerType.error, 'Please enter the $_otpLength-digit OTP');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final repo = ProfileRepository();
      final ApiResponse resp = await repo.verifyCompleteProfileOtp(otp: otp);
      if (!mounted) return;
      if (!resp.success) {
        _setOtpBanner(
          _OtpBannerType.error,
          resp.message.isNotEmpty ? resp.message : 'Incorrect OTP',
        );
        return;
      }
      setState(() => _otpVerified = true);
      _setOtpBanner(_OtpBannerType.success, 'OTP Verified');

      _otpTimer?.cancel();
      setState(() => _step = _ProfileStep.done);
    } catch (_) {
      if (!mounted) return;
      _setOtpBanner(_OtpBannerType.error, 'Something Went Wrong');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _backToDetailsStep() {
    if (_isSubmitting) return;
    _otpTimer?.cancel();
    _otpController.clear();
    _clearOtpBanner();
    setState(() {
      _otpVerified = false;
      _otpSecondsRemaining = 0;
      _step = _ProfileStep.details;
    });
    _emailFocus.requestFocus();
  }

  Widget _headerIcon() {
    switch (_step) {
      case _ProfileStep.details:
        return Container(
          width: 54.r,
          height: 54.r,
          decoration: const BoxDecoration(
            color: Color(0xFF0B8F3A),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.person, color: Colors.white, size: 30.r),
        );
      case _ProfileStep.otp:
        return Container(
          width: 54.r,
          height: 54.r,
          decoration: BoxDecoration(
            color: const Color(0xFF0B8F3A).withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF0B8F3A), width: 2),
          ),
          child: Padding(
            padding: EdgeInsets.all(10.r),
            child: Image.asset(
              FileConstants.resetPinIcon,
              fit: BoxFit.contain,
            ),
          ),
        );
      case _ProfileStep.done:
        return Container(
          width: 70.r,
          height: 70.r,
          decoration: const BoxDecoration(
            color: Color(0xFF0B8F3A),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.check, color: Colors.white, size: 40.r),
        );
    }
  }

  Widget _dividerOr() {
    return Row(
      children: [
        Expanded(
            child: Divider(color: AppColors.textPrimary.withOpacity(0.18))),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          child: Text(
            'or',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textPrimary.withOpacity(0.55),
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        Expanded(
            child: Divider(color: AppColors.textPrimary.withOpacity(0.18))),
      ],
    );
  }

  Widget _googleButton() {
    return SizedBox(
      width: double.infinity,
      height: 44.h,
      child: OutlinedButton(
        onPressed: _isSubmitting ? null : _continueWithGoogle,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppColors.textPrimary.withOpacity(0.12)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Simple "G" mark without extra assets.
            Image.asset(
              FileConstants.googleLogo,
              width: 18.r,
              height: 18.r,
              fit: BoxFit.contain,
            ),
            SizedBox(width: 10.w),
            Text(
              'Continue with Google',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary.withOpacity(0.7),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Complete Your Profile',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
              ),
        ),
        SizedBox(height: 8.h),
        Text(
          'Please enter your name and\nemail ID to continue.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary.withOpacity(0.8),
                height: 1.25,
              ),
        ),
        SizedBox(height: 18.h),
        Text(
          'Enter Your Name',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
        ),
        SizedBox(height: 8.h),
        _InputBox(
          controller: _nameController,
          enabled: !_isSubmitting,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => _emailFocus.requestFocus(),
          hintText: 'Name',
        ),
        SizedBox(height: 16.h),
        Text(
          'Enter Your Email',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
        ),
        SizedBox(height: 8.h),
        _InputBox(
          controller: _emailController,
          focusNode: _emailFocus,
          enabled: !_isSubmitting,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _sendOtp(),
          hintText: 'email@example.com',
        ),
        SizedBox(height: 18.h),
        CustomElevatedButton(
          onPressed: _isSubmitting ? null : _sendOtp,
          label: _isSubmitting ? 'Please wait...' : 'Continue',
          uppercaseLabel: false,
          height: 44.h,
        ),
        SizedBox(height: 14.h),
        _dividerOr(),
        SizedBox(height: 14.h),
        _googleButton(),
      ],
    );
  }

  Widget _otpStep() {
    final email = _emailController.text.trim();
    final pinTheme = PinTheme(
      width: 58.w,
      height: 52.w,
      textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFF0B8F3A)),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Verify OTP',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
              ),
        ),
        SizedBox(height: 8.h),
        RichText(
          text: TextSpan(
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary.withOpacity(0.8),
                  height: 1.25,
                ),
            children: [
              TextSpan(
                text:
                    'Enter the $_otpLength-digit OTP sent to $email\nemail ID. ',
              ),
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: TextButton(
                  onPressed: _isSubmitting ? null : _backToDetailsStep,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    foregroundColor: AppColors.primary,
                  ),
                  child: Text(
                    'Change email',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 18.h),
        Pinput(
          controller: _otpController,
          focusNode: _otpFocus,
          length: _otpLength,
          enabled: !_isSubmitting,
          keyboardType: TextInputType.number,
          defaultPinTheme: pinTheme,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onCompleted: (_) => _verifyOtp(),
          onChanged: (_) {
            if (_otpVerified) setState(() => _otpVerified = false);
            if (_otpBannerType == _OtpBannerType.error) _clearOtpBanner();
          },
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            Icon(Icons.access_time, size: 20.r, color: Colors.black),
            SizedBox(width: 10.w),
            Text(
              _formatOtpTimer(_otpSecondsRemaining),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
            ),
            const Spacer(),
            InkWell(
              onTap: (_otpSecondsRemaining == 0 && !_isSubmitting)
                  ? _resendOtp
                  : null,
              borderRadius: BorderRadius.circular(10.r),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 6.h, horizontal: 6.w),
                child: Row(
                  children: [
                    Icon(
                      Icons.refresh,
                      size: 18.r,
                      color: (_otpSecondsRemaining == 0 && !_isSubmitting)
                          ? AppColors.textPrimary.withOpacity(0.65)
                          : AppColors.textPrimary.withOpacity(0.25),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'Resend OTP',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: (_otpSecondsRemaining == 0 && !_isSubmitting)
                                ? AppColors.textPrimary.withOpacity(0.55)
                                : AppColors.textPrimary.withOpacity(0.25),
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        if (_otpBannerType != null &&
            (_otpBannerMessage ?? '').trim().isNotEmpty)
          _OtpBanner(
            type: _otpBannerType!,
            message: _otpBannerMessage!.trim(),
          ),
        SizedBox(height: 18.h),
        CustomElevatedButton(
          onPressed: _isSubmitting ? null : _verifyOtp,
          label: _isSubmitting ? 'Verifying...' : 'Verify OTP',
          uppercaseLabel: false,
          height: 44.h,
        ),
      ],
    );
  }

  Widget _doneStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Profile setup is\ncompleted',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
        ),
        SizedBox(height: 10.h),
        Text(
          'Your details have been verified successfully.\nYou can now continue using the app.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary.withOpacity(0.7),
                height: 1.25,
              ),
        ),
        SizedBox(height: 18.h),
        CustomElevatedButton(
          onPressed: () {
            widget.onCompleted?.call();
            Navigator.of(context).pop();
          },
          label: 'Continue',
          uppercaseLabel: false,
          height: 44.h,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final Widget content;
    switch (_step) {
      case _ProfileStep.details:
        content = _detailsStep();
        break;
      case _ProfileStep.otp:
        content = _otpStep();
        break;
      case _ProfileStep.done:
        content = _doneStep();
        break;
    }

    return WillPopScope(
      onWillPop: () async => false,
      child: Dialog(
        insetPadding: EdgeInsets.symmetric(horizontal: 18.w),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(22.r)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22.r),
          child: Container(
            padding: EdgeInsets.fromLTRB(22.w, 18.h, 22.w, 18.h),
            color: Colors.white,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: _step == _ProfileStep.done
                      ? Alignment.center
                      : Alignment.centerLeft,
                  child: _headerIcon(),
                ),
                SizedBox(height: 12.h),
                content,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OtpBanner extends StatelessWidget {
  const _OtpBanner({
    required this.type,
    required this.message,
  });

  final _OtpBannerType type;
  final String message;

  @override
  Widget build(BuildContext context) {
    final isSuccess = type == _OtpBannerType.success;
    final bgColor = isSuccess
        ? const Color(0xFF0B8F3A).withOpacity(0.1)
        : const Color(0xFFFFE7DE);
    final fgColor =
        isSuccess ? const Color(0xFF0B8F3A) : const Color(0xFFE54800);
    final icon = isSuccess ? Icons.verified : Icons.error;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: fgColor, size: 18.r),
          SizedBox(width: 6.w),
          Flexible(
            child: Text(
              message,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: fgColor,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InputBox extends StatelessWidget {
  const _InputBox({
    required this.controller,
    this.focusNode,
    required this.enabled,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.hintText,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final bool enabled;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final String? hintText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide:
              BorderSide(color: AppColors.textPrimary.withOpacity(0.12)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide:
              BorderSide(color: AppColors.textPrimary.withOpacity(0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
        ),
      ),
    );
  }
}
