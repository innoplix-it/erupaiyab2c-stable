import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:sms_autofill/sms_autofill.dart';

import '../../../constants/app_error_messages.dart';
import '../../../constants/storage_keys.dart';
import '../../../services/logger_service.dart';
import '../../../utils/error_message_utils.dart';
import '../../../utils/utils.dart';
import '../../refer_and_earn/repositories/referral_repository.dart';
import '../models/auth_login_result.dart';
import '../models/auth_flow.dart';
import '../models/auth_state.dart';
import '../repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(),
);

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) => AuthController(
    repository: ref.watch(authRepositoryProvider),
  ),
);

class AuthController extends StateNotifier<AuthState> {
  AuthController({
    required AuthRepository repository,
    bool shouldCheckInitialAuth = true,
  })  : _repository = repository,
        super(AuthState.initial()) {
    if (shouldCheckInitialAuth) {
      _checkInitialAuth();
    } else {
      state = state.copyWith(isLoading: false);
    }
  }

  final AuthRepository _repository;

  void _debugPrint(String message) {
    debugPrint('[AuthController] $message');
  }

  String _messageFromException(Object error, String fallback) {
    return ErrorMessageUtils.from(
      error,
      fallback: fallback.isNotEmpty ? fallback : AppErrorMessages.generic,
    );
  }

  Future<void> _checkInitialAuth() async {
    try {
      final isAuthenticated = await Utils.checkAuthentication().timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          return false;
        },
      );
      if (isAuthenticated) {
        state = state.copyWith(
          isAuthenticated: true,
          isLoading: false,
          isSubmitting: false,
          errorMessage: null,
        );
        return;
      }

      final refreshed = await _repository.refreshSession().timeout(
        const Duration(seconds: 12),
        onTimeout: () {
          logger.error('refreshSession timed out');
          return false;
        },
      );
      final hasTemporaryAccess =
          !refreshed && await _repository.hasTemporaryAccess();
      state = state.copyWith(
        isAuthenticated: refreshed,
        hasTemporaryAccess: hasTemporaryAccess,
        isLoading: false,
        isSubmitting: false,
        errorMessage: null,
      );
    } catch (e) {
      logger.error('Initial auth check failed: $e', error: e);
      state = state.copyWith(
        isAuthenticated: false,
        hasTemporaryAccess: false,
        isLoading: false,
        isSubmitting: false,
        errorMessage: null,
      );
    }
  }

  Future<AuthFlow?> checkLogin({
    required String mobile,
  }) async {
    _debugPrint('checkLogin called -> mobile=$mobile');
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    try {
      String? appHash;
      try {
        final signature = await SmsAutoFill()
            .getAppSignature
            .timeout(const Duration(seconds: 2), onTimeout: () => '');
        if (signature.trim().isNotEmpty) appHash = signature.trim();
        _debugPrint(
          'checkLogin appHash resolved -> ${appHash == null || appHash.isEmpty ? "<empty>" : "***${appHash.substring(appHash.length >= 3 ? appHash.length - 3 : 0)}"}',
        );
      } catch (e, stackTrace) {
        logger.error('Failed to generate app hash for check-login',
            error: e, stackTrace: stackTrace);
      }
      final flow = await _repository.checkLogin(
        mobile: mobile,
        appHash: appHash,
      );
      _debugPrint('checkLogin success -> flow=$flow');
      state = state.copyWith(
        isSubmitting: false,
        pendingMobile: mobile,
        errorMessage: null,
      );
      return flow;
    } catch (e) {
      _debugPrint('checkLogin failed -> error=$e');
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: _messageFromException(
          e,
          'Failed to continue. Please try again.',
        ),
      );
      return null;
    }
  }

  Future<AuthLoginResult> login({
    required String mobile,
    required String pin,
  }) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    try {
      final result = await _repository.login(mobile: mobile, pin: pin);
      if (result.isSuspected) {
        state = state.copyWith(
          isAuthenticated: false,
          hasTemporaryAccess: true,
          isSubmitting: false,
          errorMessage: null,
        );
        return result;
      }
      if (result.requiresDeviceVerification) {
        state = state.copyWith(
          isAuthenticated: false,
          hasTemporaryAccess: false,
          isSubmitting: false,
          errorMessage: null,
        );
        return result;
      }
      state = state.copyWith(
        isAuthenticated: true,
        hasTemporaryAccess: false,
        isSubmitting: false,
        pendingMobile: null,
        postOtpToken: null,
        errorMessage: null,
      );
      await _handlePendingReferral();
      return result;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: _messageFromException(
          e,
          'Login failed. Please try again.',
        ),
      );
      return AuthLoginResult.failure(message: state.errorMessage);
    }
  }

  Future<bool> pinLock({
    required String mobile,
    required String pin,
  }) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    try {
      await _repository.pinLock(mobile: mobile, pin: pin);
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: _messageFromException(
          e,
          'PIN validation failed. Please try again.',
        ),
      );
      return false;
    }
  }

  Future<bool> verifyOtp({
    required String otp,
    String? mobile,
  }) async {
    final storedMobile = await _repository.secureStorage.read(key: 'mobile');
    final resolvedMobile = mobile ?? state.pendingMobile ?? storedMobile ?? '';
    if (resolvedMobile.isEmpty) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Missing mobile number. Please try again.',
      );
      return false;
    }

    state = state.copyWith(isSubmitting: true, errorMessage: null);
    try {
      final postOtpToken = await _repository.verifyOtp(
        mobile: resolvedMobile,
        otp: otp,
      );
      state = state.copyWith(
        isSubmitting: false,
        pendingMobile: resolvedMobile,
        postOtpToken: postOtpToken,
        errorMessage: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: _messageFromException(
          e,
          'OTP verification failed. Please try again.',
        ),
      );
      return false;
    }
  }

  Future<String?> setPin({
    required String pin,
    String? mobile,
  }) async {
    final postOtpToken = state.postOtpToken?.trim() ?? '';
    if (postOtpToken.isEmpty) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Missing verification token. Please verify OTP again.',
      );
      return null;
    }

    state = state.copyWith(isSubmitting: true, errorMessage: null);
    try {
      final message = await _repository.setPin(
        postOtpToken: postOtpToken,
        pin: pin,
      );
      state = state.copyWith(
        isSubmitting: false,
        pendingMobile: null,
        postOtpToken: null,
        errorMessage: null,
      );
      await _handlePendingReferral();
      return message;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: _messageFromException(
          e,
          'Failed to set PIN. Please try again.',
        ),
      );
      return null;
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = state.copyWith(
      isAuthenticated: false,
      hasTemporaryAccess: false,
      pendingMobile: null,
      postOtpToken: null,
      errorMessage: null,
    );
  }

  Future<String?> _getAppHash() async {
    try {
      final signature = await SmsAutoFill()
          .getAppSignature
          .timeout(const Duration(seconds: 2), onTimeout: () => '');
      final trimmed = signature.trim();
      if (trimmed.isNotEmpty) return trimmed;
    } catch (e, stackTrace) {
      logger.error('Failed to generate app hash for forgot PIN OTP',
          error: e, stackTrace: stackTrace);
    }
    return null;
  }

  Future<String?> requestForgotPinOtp({
    String? mobile,
  }) async {
    final storedMobile = await _repository.secureStorage.read(key: 'mobile');
    final resolvedMobile = mobile ?? state.pendingMobile ?? storedMobile ?? '';
    if (resolvedMobile.isEmpty) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Missing mobile number. Please try again.',
      );
      return null;
    }

    state = state.copyWith(isSubmitting: true, errorMessage: null);
    try {
      final appHash = await _getAppHash();
      final message = await _repository.requestForgotPinOtp(
        mobile: resolvedMobile,
        appHash: appHash ?? '',
      );
      state = state.copyWith(isSubmitting: false, errorMessage: null);
      return message;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: _messageFromException(
          e,
          'Failed to request OTP. Please try again.',
        ),
      );
      return null;
    }
  }

  Future<String?> forgotPin({
    required String otp,
    required String pin,
    String? mobile,
  }) async {
    final storedMobile = await _repository.secureStorage.read(key: 'mobile');
    final resolvedMobile = mobile ?? state.pendingMobile ?? storedMobile ?? '';
    if (resolvedMobile.isEmpty) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Missing mobile number. Please try again.',
      );
      return null;
    }

    state = state.copyWith(isSubmitting: true, errorMessage: null);
    try {
      final message = await _repository.forgotPin(
        mobile: resolvedMobile,
        otp: otp,
        pin: pin,
      );
      state = state.copyWith(isSubmitting: false, errorMessage: null);
      return message;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: _messageFromException(
          e,
          'Failed to reset PIN. Please try again.',
        ),
      );
      return null;
    }
  }

  Future<String?> sendAccountRecoveryOtp() async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    try {
      final message = await _repository.sendAccountRecoveryOtp();
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: null,
      );
      return message;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: _messageFromException(
          e,
          'Failed to send OTP. Please try again.',
        ),
      );
      return null;
    }
  }

  Future<bool> verifyAccountRecoveryOtp({
    required String mobileOtp,
    required String emailOtp,
  }) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    try {
      await _repository.verifyAccountRecoveryOtp(
        mobileOtp: mobileOtp,
        emailOtp: emailOtp,
      );
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: _messageFromException(
          e,
          'OTP verification failed. Please try again.',
        ),
      );
      return false;
    }
  }

  Future<String?> sendDeviceOtp({required String verificationId}) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    try {
      final message =
          await _repository.sendDeviceOtp(verificationId: verificationId);
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: null,
      );
      return message;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: _messageFromException(
          e,
          'Failed to send OTP. Please try again.',
        ),
      );
      return null;
    }
  }

  Future<String?> verifyDeviceOtp({
    required String verificationId,
    required String mobileOtp,
    required String emailOtp,
  }) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    try {
      final message = await _repository.verifyDeviceOtp(
        verificationId: verificationId,
        mobileOtp: mobileOtp,
        emailOtp: emailOtp,
      );
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: null,
      );
      return message;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: _messageFromException(
          e,
          'Device verification failed. Please try again.',
        ),
      );
      return null;
    }
  }

  Future<String?> verifyAccountRecoveryKyc({
    required String panNo,
    required String aadhaar,
  }) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    try {
      final message = await _repository.verifyAccountRecoveryKyc(
        panNo: panNo,
        aadhaar: aadhaar,
      );
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: null,
      );
      return message;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: _messageFromException(
          e,
          'KYC verification failed. Please try again.',
        ),
      );
      return null;
    }
  }

  Future<void> _handlePendingReferral() async {
    try {
      final code = await _repository.secureStorage
          .read(key: StorageKeys.pendingReferralCode);
      if (code == null || code.trim().isEmpty) {
        logger.debug('Referral: no pending code');
        return;
      }
      final userId = await _repository.secureStorage.read(key: 'userId');
      if (userId == null || userId.trim().isEmpty) {
        logger.debug('Referral: missing userId, skip register');
        return;
      }
      logger.debug('Referral: registering pending code=$code userId=$userId');
      final response = await ReferralRepository().registerReferral(
        newUserId: userId,
        referralCode: code.trim(),
      );
      logger.debug(
        'Referral: register response status=${response.status} message=${response.message}',
      );
      if (response.status) {
        await _repository.secureStorage.delete(
          key: StorageKeys.pendingReferralCode,
        );
        logger.debug('Referral: cleared pending code');
      }
    } catch (e, stackTrace) {
      logger.error('Failed to register pending referral',
          error: e, stackTrace: stackTrace);
    }
  }
}
