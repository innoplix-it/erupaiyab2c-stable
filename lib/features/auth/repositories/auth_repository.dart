import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../constants/api_constants.dart';
import '../../../constants/storage_keys.dart';
import '../../../services/dio_service.dart';
import '../../../services/logger_service.dart';
import '../../../services/login_device_context_service.dart';
import '../../../services/push_notification_service.dart';
import '../../../services/secure_storage_service.dart';
import '../models/auth_login_result.dart';
import '../models/auth_flow.dart';

class AuthRepository {
  AuthRepository({
    Dio? dio,
    FlutterSecureStorage? secureStorage,
  })  : _dio = dio ?? DioService.instance.client,
        _secureStorage = secureStorage ?? SecureStorageService.instance;

  final Dio _dio;
  final FlutterSecureStorage _secureStorage;

  FlutterSecureStorage get secureStorage => _secureStorage;

  void _debugPrint(String message) {
    debugPrint('[AuthRepository] $message');
  }

  String _maskValue(String? value, {int visibleEnd = 4}) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return '<empty>';
    if (text.length <= visibleEnd) return text;
    return '${'*' * (text.length - visibleEnd)}${text.substring(text.length - visibleEnd)}';
  }

  bool _readBoolFlag(Map<String, dynamic>? payload, List<String> keys) {
    if (payload == null) return false;
    for (final key in keys) {
      final raw = payload[key];
      if (raw == true || raw == 1) return true;
      final text = raw?.toString().trim().toLowerCase();
      if (text == 'true' || text == '1') return true;
    }
    return false;
  }

  Never _throwApiMessage(DioException e, {String fallback = 'Request failed'}) {
    final data = e.response?.data;
    if (data is Map) {
      final message = data['message'];
      if (message is String && message.trim().isNotEmpty) {
        throw Exception(message.trim());
      }
    }
    throw Exception(fallback);
  }

  Future<AuthFlow> checkLogin({
    required String mobile,
    String? appHash,
  }) async {
    try {
      final deviceToken =
          (await PushNotificationService.ensureTokenReady())?.trim();
      final hasDeviceToken = deviceToken != null &&
          deviceToken.isNotEmpty &&
          deviceToken.toLowerCase() != 'null';
      if (!hasDeviceToken) {
        logger.error(
            'FCM token unavailable for check-login; continuing without device_token');
      }

      final deviceContext = await const LoginDeviceContextService().collect();
      final requestPayload = <String, dynamic>{
        'mobile': mobile,
        if (appHash != null && appHash.trim().isNotEmpty)
          'appHash': _maskValue(appHash, visibleEnd: 3),
        if (hasDeviceToken)
          'device_token': _maskValue(deviceToken, visibleEnd: 6),
        ...deviceContext,
      };
      _debugPrint(
        'checkLogin request -> endpoint=${ApiConstants.checkLoginEndpoint}, payload=$requestPayload',
      );
      final response = await _dio.post(
        ApiConstants.checkLoginEndpoint,
        options: Options(
          contentType: Headers.jsonContentType,
          extra: const {
            'skipAuth': true,
            'skipAuthRefresh': true,
          },
        ),
        data: {
          'mobile': mobile,
          if (appHash != null && appHash.trim().isNotEmpty)
            'appHash': appHash.trim(),
          if (hasDeviceToken) 'device_token': deviceToken,
          ...deviceContext,
        },
      );
      _debugPrint(
        'checkLogin response -> statusCode=${response.statusCode}, data=${response.data}',
      );

      final payload = response.data as Map<String, dynamic>?;
      final success = payload?['success'] == true;
      if (!success) {
        final message = payload?['message'] as String? ?? 'Request failed';
        throw Exception(message);
      }

      final data = payload?['data'] as Map<String, dynamic>? ?? {};
      final flowValue = payload?['flow'] ?? data['flow'];
      final flow = authFlowFromApi(flowValue);
      if (flow == null) {
        throw Exception('Invalid response');
      }

      final userId = data['user_id'] ?? data['id'];
      if (userId != null) {
        await _secureStorage.write(key: 'userId', value: userId.toString());
      }

      return flow;
    } on DioException catch (e) {
      _debugPrint(
        'checkLogin dio error -> type=${e.type}, statusCode=${e.response?.statusCode}, response=${e.response?.data}, message=${e.message}',
      );
      if (e.type == DioExceptionType.badResponse) {
        _throwApiMessage(e, fallback: 'Unable to continue');
      }
      logger.error(
        'Check login failed: ${e.toString()}',
        error: e,
      );
      rethrow;
    } catch (e) {
      _debugPrint('checkLogin unexpected error -> $e');
      logger.error(
        'Check login failed: ${e.toString()}',
        error: e,
      );
      rethrow;
    }
  }

  Future<String?> verifyOtp({
    required String mobile,
    required String otp,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.verifyOtpEndpoint,
        options: Options(
          contentType: Headers.jsonContentType,
          extra: const {
            'skipAuth': true,
            'skipAuthRefresh': true,
          },
        ),
        data: {
          'mobile': mobile,
          'otp': otp,
        },
      );

      final payload = response.data as Map<String, dynamic>?;
      final success = payload?['success'] == true;
      if (!success) {
        final message =
            payload?['message'] as String? ?? 'OTP verification failed';
        throw Exception(message);
      }
      final data = payload?['data'] as Map<String, dynamic>? ?? {};
      final userId = data['user_id'] ?? data['id'];
      if (userId != null) {
        await _secureStorage.write(key: 'userId', value: userId.toString());
      }
      final postOtpToken = (data['post_otp_token'] ?? '').toString().trim();
      return postOtpToken.isEmpty ? null : postOtpToken;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.badResponse) {
        _throwApiMessage(e, fallback: 'OTP verification failed');
      }
      logger.error(
        'OTP verification failed: ${e.toString()}',
        error: e,
      );
      rethrow;
    } catch (e) {
      logger.error(
        'OTP verification failed: ${e.toString()}',
        error: e,
      );
      rethrow;
    }
  }

  Future<String> setPin({
    required String postOtpToken,
    required String pin,
  }) async {
    try {
      final installationId =
          (await _secureStorage.read(key: StorageKeys.guestInstallationId))
                  ?.trim() ??
              '';
      if (installationId.isEmpty) {
        throw Exception('Missing installation ID.');
      }

      final response = await _dio.post(
        ApiConstants.setPinEndpoint,
        options: Options(
          contentType: Headers.jsonContentType,
          extra: const {
            'skipAuth': true,
            'skipAuthRefresh': true,
          },
        ),
        data: {
          'post_otp_token': postOtpToken,
          'pin': pin,
          'installation_id': installationId,
        },
      );

      final payload = response.data as Map<String, dynamic>?;
      final success = payload?['success'] == true;
      if (!success) {
        final message = payload?['message'] as String? ?? 'Set PIN failed';
        throw Exception(message);
      }
      final message = payload?['message'] as String? ?? 'PIN set successfully.';
      return message;
    } catch (e) {
      logger.error(
        'Set PIN failed: ${e.toString()}',
        error: e,
      );
      rethrow;
    }
  }

  Future<AuthLoginResult> login({
    required String mobile,
    required String pin,
  }) async {
    try {
      final deviceToken =
          (await PushNotificationService.ensureTokenReady())?.trim();
      final hasDeviceToken = deviceToken != null &&
          deviceToken.isNotEmpty &&
          deviceToken.toLowerCase() != 'null';
      if (!hasDeviceToken) {
        logger.error(
            'FCM token unavailable for login; continuing without device_token');
      }

      final deviceContext = await const LoginDeviceContextService().collect();

      final response = await _dio.post(
        ApiConstants.loginEndpoint,
        options: Options(
          contentType: Headers.jsonContentType,
          extra: const {
            // Auth is not required for login; avoid attaching stale tokens.
            'skipAuth': true,
            'skipAuthRefresh': true,
          },
        ),
        data: {
          'mobile': mobile,
          'pin': pin,
          if (hasDeviceToken) 'device_token': deviceToken,
          ...deviceContext,
        },
      );

      final payload = response.data as Map<String, dynamic>?;
      final success = payload?['success'] == true;
      if (!success) {
        final message = payload?['message'] as String? ?? 'Login failed';
        final requiresDeviceVerification = _readBoolFlag(payload, const [
          'device_verification_required',
          'show_popup',
        ]);
        final verificationId =
            (payload?['verification_id'] ?? '').toString().trim();
        if (requiresDeviceVerification && verificationId.isNotEmpty) {
          return AuthLoginResult.deviceVerificationRequired(
            verificationId: verificationId,
            showPopup: _readBoolFlag(payload, const ['show_popup']),
            message: message,
          );
        }
        final tempAccessToken =
            (payload?['temp_access_token'] ?? '').toString().trim();
        if (tempAccessToken.isNotEmpty &&
            message.trim().toLowerCase() == 'account is suspected.') {
          final rawKycStatus = payload?['kyc_status'];
          final isKycVerified = rawKycStatus == 1 ||
              rawKycStatus == true ||
              rawKycStatus?.toString().trim() == '1' ||
              rawKycStatus?.toString().trim().toLowerCase() == 'true';
          await _clearPrimarySession();
          await _secureStorage.write(
            key: StorageKeys.tempAccessToken,
            value: tempAccessToken,
          );
          await _secureStorage.write(key: 'mobile', value: mobile);
          return AuthLoginResult.suspected(
            tempAccessToken: tempAccessToken,
            isKycVerified: isKycVerified,
            message: message,
          );
        }
        throw Exception(message);
      }

      final requiresDeviceVerification = _readBoolFlag(payload, const [
        'device_verification_required',
      ]);
      final verificationId =
          (payload?['verification_id'] ?? '').toString().trim();
      if (requiresDeviceVerification && verificationId.isNotEmpty) {
        return AuthLoginResult.deviceVerificationRequired(
          verificationId: verificationId,
          showPopup: _readBoolFlag(payload, const ['show_popup']),
          message: payload?['message'] as String? ?? 'New device detected.',
        );
      }

      final data = payload?['data'] as Map<String, dynamic>? ?? {};
      final accessToken = data['access_token'] as String?;
      final refreshToken = data['refresh_token'] as String?;
      final tokenType = data['token_type'] as String?;
      final expiresIn = data['expires_in'] as int?;
      final userId = (data['user_id'] ?? data['id'])?.toString();

      if (accessToken == null || refreshToken == null || expiresIn == null) {
        throw Exception('Invalid login response');
      }

      final expiresAt =
          DateTime.now().add(Duration(seconds: expiresIn)).toIso8601String();
      final refreshExpiry = _resolveRefreshExpiry(data);

      await _secureStorage.write(key: 'accessToken', value: accessToken);
      await _secureStorage.write(key: 'refreshToken', value: refreshToken);
      await _secureStorage.write(
        key: 'tokenType',
        value: tokenType ?? 'Bearer',
      );
      await _secureStorage.write(key: 'tokenExpiresAt', value: expiresAt);
      if (refreshExpiry != null) {
        await _secureStorage.write(
          key: 'refreshTokenExpiresAt',
          value: refreshExpiry.toIso8601String(),
        );
      }
      if (userId != null && userId.isNotEmpty) {
        await _secureStorage.write(key: 'userId', value: userId);
      }
      await _secureStorage.write(key: 'mobile', value: mobile);
      await _secureStorage.delete(key: StorageKeys.tempAccessToken);
      return const AuthLoginResult.success();
    } on DioException catch (e) {
      if (e.type == DioExceptionType.badResponse) {
        _throwApiMessage(e, fallback: 'Login failed');
      }
      logger.error(
        'Login failed: ${e.toString()}',
        error: e,
      );
      rethrow;
    } catch (e) {
      logger.error(
        'Login failed: ${e.toString()}',
        error: e,
      );
      rethrow;
    }
  }

  Future<void> _clearPrimarySession() async {
    await _secureStorage.delete(key: 'accessToken');
    await _secureStorage.delete(key: 'refreshToken');
    await _secureStorage.delete(key: 'tokenType');
    await _secureStorage.delete(key: 'tokenExpiresAt');
    await _secureStorage.delete(key: 'refreshTokenExpiresAt');
    await _secureStorage.delete(key: 'userId');
  }

  Future<String> pinLock({
    required String mobile,
    required String pin,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.pinLockEndpoint,
        data: {
          'mobile': mobile,
          'pin': pin,
        },
      );

      final payload = response.data as Map<String, dynamic>?;
      final success = payload?['success'] == true;
      if (!success) {
        final message =
            payload?['message'] as String? ?? 'PIN validation failed';
        throw Exception(message);
      }

      return payload?['message'] as String? ?? 'Login successful';
    } on DioException catch (e) {
      if (e.type == DioExceptionType.badResponse) {
        _throwApiMessage(e, fallback: 'PIN validation failed');
      }
      logger.error(
        'PIN lock failed: ${e.toString()}',
        error: e,
      );
      rethrow;
    } catch (e) {
      logger.error(
        'PIN lock failed: ${e.toString()}',
        error: e,
      );
      rethrow;
    }
  }

  Future<String> requestForgotPinOtp({
    required String mobile,
    required String appHash,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.requestForgotPinOtpEndpoint,
        options: Options(
          contentType: Headers.jsonContentType,
          extra: const {
            'skipAuth': true,
            'skipAuthRefresh': true,
          },
        ),
        data: {
          'mobile': mobile,
          'appHash': appHash.trim(),
        },
      );

      final payload = response.data as Map<String, dynamic>?;
      final success = payload?['success'] == true;
      if (!success) {
        final message =
            payload?['message'] as String? ?? 'Failed to request OTP';
        throw Exception(message);
      }
      return payload?['message'] as String? ??
          'OTP sent to registered mobile number.';
    } on DioException catch (e) {
      if (e.type == DioExceptionType.badResponse) {
        _throwApiMessage(e, fallback: 'Failed to request OTP');
      }
      logger.error(
        'Request forgot PIN OTP failed: ${e.toString()}',
        error: e,
      );
      rethrow;
    } catch (e) {
      logger.error(
        'Request forgot PIN OTP failed: ${e.toString()}',
        error: e,
      );
      rethrow;
    }
  }

  Future<String> forgotPin({
    required String mobile,
    required String otp,
    required String pin,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.forgotPinEndpoint,
        options: Options(
          contentType: Headers.jsonContentType,
          extra: const {
            'skipAuth': true,
            'skipAuthRefresh': true,
          },
        ),
        data: {
          'mobile': mobile,
          'otp': otp,
          'pin': pin,
        },
      );

      final payload = response.data as Map<String, dynamic>?;
      final success = payload?['success'] == true;
      if (!success) {
        final message = payload?['message'] as String? ?? 'Failed to reset PIN';
        throw Exception(message);
      }
      return payload?['message'] as String? ?? 'PIN reset successfully.';
    } on DioException catch (e) {
      if (e.type == DioExceptionType.badResponse) {
        _throwApiMessage(e, fallback: 'Failed to reset PIN');
      }
      logger.error(
        'Forgot PIN failed: ${e.toString()}',
        error: e,
      );
      rethrow;
    } catch (e) {
      logger.error(
        'Forgot PIN failed: ${e.toString()}',
        error: e,
      );
      rethrow;
    }
  }

  Future<String> sendAccountRecoveryOtp() async {
    try {
      final response =
          await _dio.post(ApiConstants.accountRecoverySendOtpEndpoint);

      final payload = response.data as Map<String, dynamic>?;
      final success = payload?['success'] == true;
      if (!success) {
        final message = payload?['message'] as String? ?? 'Failed to send OTP';
        throw Exception(message);
      }
      return payload?['message'] as String? ?? 'OTP sent successfully';
    } on DioException catch (e) {
      if (e.type == DioExceptionType.badResponse) {
        _throwApiMessage(e, fallback: 'Failed to send OTP');
      }
      logger.error(
        'Account recovery send OTP failed: ${e.toString()}',
        error: e,
      );
      rethrow;
    } catch (e) {
      logger.error(
        'Account recovery send OTP failed: ${e.toString()}',
        error: e,
      );
      rethrow;
    }
  }

  Future<String> sendDeviceOtp({required String verificationId}) async {
    try {
      final response = await _dio.post(
        ApiConstants.sendDeviceOtpEndpoint,
        data: {
          'verification_id': verificationId,
        },
        options: Options(
          extra: const {
            'skipAuth': true,
            'skipAuthRefresh': true,
          },
        ),
      );

      final payload = response.data as Map<String, dynamic>?;
      final success = payload?['success'] == true;
      if (!success) {
        final message = payload?['message'] as String? ?? 'Failed to send OTP';
        throw Exception(message);
      }
      return payload?['message'] as String? ?? 'OTP sent successfully';
    } on DioException catch (e) {
      if (e.type == DioExceptionType.badResponse) {
        _throwApiMessage(e, fallback: 'Failed to send OTP');
      }
      logger.error('Device OTP send failed: ${e.toString()}', error: e);
      rethrow;
    } catch (e) {
      logger.error('Device OTP send failed: ${e.toString()}', error: e);
      rethrow;
    }
  }

  Future<String> verifyDeviceOtp({
    required String verificationId,
    required String mobileOtp,
    required String emailOtp,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.verifyDeviceOtpEndpoint,
        data: {
          'verification_id': verificationId,
          'mobile_otp': mobileOtp,
          'email_otp': emailOtp,
        },
        options: Options(
          extra: const {
            'skipAuth': true,
            'skipAuthRefresh': true,
          },
        ),
      );

      final payload = response.data as Map<String, dynamic>?;
      final success = payload?['success'] == true;
      if (!success) {
        final message =
            payload?['message'] as String? ?? 'Device verification failed';
        throw Exception(message);
      }
      return payload?['message'] as String? ?? 'Device verified successfully';
    } on DioException catch (e) {
      if (e.type == DioExceptionType.badResponse) {
        _throwApiMessage(e, fallback: 'Device verification failed');
      }
      logger.error('Device OTP verify failed: ${e.toString()}', error: e);
      rethrow;
    } catch (e) {
      logger.error('Device OTP verify failed: ${e.toString()}', error: e);
      rethrow;
    }
  }

  Future<void> verifyAccountRecoveryOtp({
    required String mobileOtp,
    required String emailOtp,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.accountRecoveryVerifyOtpEndpoint,
        data: {
          'mobile_otp': mobileOtp,
          'email_otp': emailOtp,
        },
      );

      final payload = response.data as Map<String, dynamic>?;
      final success = payload?['success'] == true;
      if (!success) {
        final message =
            payload?['message'] as String? ?? 'OTP verification failed';
        throw Exception(message);
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.badResponse) {
        _throwApiMessage(e, fallback: 'OTP verification failed');
      }
      logger.error(
        'Account recovery verify OTP failed: ${e.toString()}',
        error: e,
      );
      rethrow;
    } catch (e) {
      logger.error(
        'Account recovery verify OTP failed: ${e.toString()}',
        error: e,
      );
      rethrow;
    }
  }

  Future<String> verifyAccountRecoveryKyc({
    required String panNo,
    required String aadhaar,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.accountRecoveryVerifyKycEndpoint,
        data: {
          'pan_no': panNo,
          'aadhaar': aadhaar,
        },
      );

      final payload = response.data as Map<String, dynamic>?;
      final success = payload?['success'] == true;
      if (!success) {
        final message =
            payload?['message'] as String? ?? 'KYC verification failed';
        throw Exception(message);
      }
      return payload?['message'] as String? ??
          'Existing KYC verified successfully';
    } on DioException catch (e) {
      if (e.type == DioExceptionType.badResponse) {
        _throwApiMessage(e, fallback: 'KYC verification failed');
      }
      logger.error(
        'Account recovery verify KYC failed: ${e.toString()}',
        error: e,
      );
      rethrow;
    } catch (e) {
      logger.error(
        'Account recovery verify KYC failed: ${e.toString()}',
        error: e,
      );
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      final refreshToken = await _secureStorage.read(key: 'refreshToken');
      if (refreshToken != null) {
        await _dio.post(
          ApiConstants.logoutEndpoint,
          data: {'refresh_token': refreshToken},
        );
      }
    } catch (e) {
      logger.error('Logout API call failed: $e', error: e);
    } finally {
      await _secureStorage.delete(key: 'accessToken');
      await _secureStorage.delete(key: 'refreshToken');
      await _secureStorage.delete(key: 'tokenType');
      await _secureStorage.delete(key: 'tokenExpiresAt');
      await _secureStorage.delete(key: 'userId');
      await _secureStorage.delete(key: 'mobile');
      await _secureStorage.delete(key: StorageKeys.tempAccessToken);
    }
  }

  Future<bool> hasTemporaryAccess() async {
    final token = await _secureStorage.read(key: StorageKeys.tempAccessToken);
    return token != null && token.trim().isNotEmpty;
  }

  Future<bool> refreshSession() async {
    try {
      final refreshToken = await _secureStorage.read(key: 'refreshToken');
      if (refreshToken == null || refreshToken.isEmpty) {
        return false;
      }

      final response = await _dio.post(
        ApiConstants.refreshTokenEndpoint,
        options: Options(
          extra: const {
            'skipAuth': true,
            'skipAuthRefresh': true,
            'isRefresh': true,
          },
        ),
        data: {'refresh_token': refreshToken},
      );

      final payload = response.data as Map<String, dynamic>?;
      final success = payload?['success'] == true;
      if (!success) {
        return false;
      }

      final data = payload?['data'] as Map<String, dynamic>? ?? {};
      final accessToken = data['access_token'] as String?;
      final nextRefreshToken = data['refresh_token'] as String?;
      final tokenType = data['token_type'] as String?;
      final expiresIn = data['expires_in'] as int?;

      if (accessToken == null || expiresIn == null) {
        return false;
      }

      final expiresAt =
          DateTime.now().add(Duration(seconds: expiresIn)).toIso8601String();
      final refreshExpiry = _resolveRefreshExpiry(data);

      await _secureStorage.write(key: 'accessToken', value: accessToken);
      if (nextRefreshToken != null && nextRefreshToken.isNotEmpty) {
        await _secureStorage.write(
            key: 'refreshToken', value: nextRefreshToken);
      }
      await _secureStorage.write(
        key: 'tokenType',
        value: tokenType ?? 'Bearer',
      );
      await _secureStorage.write(key: 'tokenExpiresAt', value: expiresAt);
      if (refreshExpiry != null) {
        await _secureStorage.write(
          key: 'refreshTokenExpiresAt',
          value: refreshExpiry.toIso8601String(),
        );
      }
      return true;
    } catch (e, stackTrace) {
      logger.error(
        'Refresh token failed: ${e.toString()}',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }
}

DateTime? _resolveRefreshExpiry(Map<String, dynamic> data) {
  final refreshExpiresAt = data['refresh_expires_at'];
  if (refreshExpiresAt is String && refreshExpiresAt.isNotEmpty) {
    return DateTime.tryParse(refreshExpiresAt);
  }
  final refreshExpiresIn =
      data['refresh_expires_in'] ?? data['refresh_token_expires_in'];
  if (refreshExpiresIn is int) {
    return DateTime.now().add(Duration(seconds: refreshExpiresIn));
  }
  if (refreshExpiresIn is String) {
    final parsed = int.tryParse(refreshExpiresIn);
    if (parsed != null) {
      return DateTime.now().add(Duration(seconds: parsed));
    }
  }
  return null;
}
