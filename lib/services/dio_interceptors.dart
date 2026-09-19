import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:e_rupaiya/constants/api_constants.dart';
import 'package:e_rupaiya/core/barrel_file.dart';
import 'package:e_rupaiya/features/auth/controllers/auth_controller.dart';
import 'package:e_rupaiya/features/home/controllers/home_controller.dart';
import 'package:e_rupaiya/widgets/k_dialog.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:http_certificate_pinning/http_certificate_pinning.dart';

import '../config/app_env.dart';
import '../config/ssl_pinning_config.dart';
import '../constants/app_error_messages.dart';
import '../constants/storage_keys.dart';
import '../widgets/app_snackbar.dart';
import 'secure_storage_service.dart';

void _debugLog(String message) {
  if (!AppEnv.enableLogs || !kDebugMode) return;
  debugPrint(message);
}

class DioInterceptors extends InterceptorsWrapper {
  final secureStorage = SecureStorageService.instance;
  static Completer<bool>? _refreshCompleter;
  static bool _handlingServerUnavailable = false;

  static const int _maxLogBodyChars = 6000;
  static const Set<String> _sensitiveKeys = {
    'pin',
    'mpin',
    'otp',
    'access_token',
    'refresh_token',
    'token',
    'authorization',
    'pan',
    'pan_number',
    'aadhaar',
    'aadhaar_number',
    'aadhar',
    'aadhar_number',
  };

  Map<String, dynamic> _redactHeaders(Map<String, dynamic> headers) {
    final redacted = <String, dynamic>{};
    headers.forEach((key, value) {
      final lower = key.toLowerCase();
      if (lower == 'authorization' ||
          lower == 'cookie' ||
          lower == 'set-cookie' ||
          lower == 'x-api-key') {
        redacted[key] = '<redacted>';
      } else {
        redacted[key] = value;
      }
    });
    return redacted;
  }

  String _stringify(Object? value) {
    if (value == null) return '';
    try {
      if (value is String) return value;
      if (value is Map || value is List) {
        return const JsonEncoder.withIndent('  ').convert(value);
      }
      return value.toString();
    } catch (_) {
      return value.toString();
    }
  }

  Object? _redactBody(Object? value) {
    if (value is Map) {
      final redacted = <String, dynamic>{};
      value.forEach((key, dynamic nestedValue) {
        final keyText = key.toString();
        if (_sensitiveKeys.contains(keyText.toLowerCase())) {
          redacted[keyText] = '<redacted>';
        } else {
          redacted[keyText] = _redactBody(nestedValue);
        }
      });
      return redacted;
    }
    if (value is List) {
      return value.map(_redactBody).toList(growable: false);
    }
    return value;
  }

  String _truncate(String value) {
    if (value.length <= _maxLogBodyChars) return value;
    return '${value.substring(0, _maxLogBodyChars)}…<truncated>';
  }

  Future<void> _clearSession() async {
    await secureStorage.delete(key: 'accessToken');
    await secureStorage.delete(key: 'refreshToken');
    await secureStorage.delete(key: 'tokenType');
    await secureStorage.delete(key: 'tokenExpiresAt');
    await secureStorage.delete(key: 'refreshTokenExpiresAt');
    await secureStorage.delete(key: 'userId');
    await secureStorage.delete(key: 'mobile');
    await secureStorage.delete(key: StorageKeys.tempAccessToken);
  }

  Dio _buildPinnedRefreshClient() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );
    final host = Uri.tryParse(ApiConstants.baseUrl)?.host.trim().toLowerCase();
    final shouldEnablePinning =
        (!SslPinningConfig.enableInProductionOnly || AppEnv.isProduction) &&
            !kIsWeb &&
            host != null &&
            host.isNotEmpty &&
            SslPinningConfig.allowedHosts.contains(host) &&
            SslPinningConfig.sha256Fingerprints.isNotEmpty;
    if (shouldEnablePinning) {
      dio.interceptors.add(
        CertificatePinningInterceptor(
          allowedSHAFingerprints: SslPinningConfig.sha256Fingerprints,
          timeout: 50,
        ),
      );
    }
    return dio;
  }

  Future<bool> _refreshAccessToken() async {
    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }
    _refreshCompleter = Completer<bool>();
    try {
      final refreshToken = await secureStorage.read(key: 'refreshToken');
      if (refreshToken == null || refreshToken.isEmpty) {
        _refreshCompleter!.complete(false);
        return _refreshCompleter!.future;
      }

      final dio = _buildPinnedRefreshClient();
      final response = await dio.post(
        ApiConstants.refreshTokenEndpoint,
        data: {'refresh_token': refreshToken},
      );
      final payload = response.data as Map<String, dynamic>?;
      final success = payload?['success'] == true;
      final data = payload?['data'] as Map<String, dynamic>? ?? {};
      final accessToken = data['access_token'] as String?;
      final nextRefreshToken = data['refresh_token'] as String?;
      final tokenType = data['token_type'] as String?;
      final expiresIn = data['expires_in'] as int?;

      if (!success || accessToken == null || expiresIn == null) {
        _refreshCompleter!.complete(false);
        return _refreshCompleter!.future;
      }

      final expiresAt =
          DateTime.now().add(Duration(seconds: expiresIn)).toIso8601String();
      await secureStorage.write(key: 'accessToken', value: accessToken);
      if (nextRefreshToken != null && nextRefreshToken.isNotEmpty) {
        await secureStorage.write(key: 'refreshToken', value: nextRefreshToken);
      }
      await secureStorage.write(
        key: 'tokenType',
        value: tokenType ?? 'Bearer',
      );
      await secureStorage.write(key: 'tokenExpiresAt', value: expiresAt);
      final refreshExpiry = _resolveRefreshExpiry(data);
      if (refreshExpiry != null) {
        await secureStorage.write(
          key: 'refreshTokenExpiresAt',
          value: refreshExpiry.toIso8601String(),
        );
      }
      _refreshCompleter!.complete(true);
      return _refreshCompleter!.future;
    } catch (_) {
      _refreshCompleter?.complete(false);
      return _refreshCompleter!.future;
    } finally {
      _refreshCompleter = null;
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

  Future<bool> _refreshAccessTokenWithRetry() async {
    final refreshed = await _refreshAccessToken();
    if (refreshed) return true;
    await Future.delayed(const Duration(milliseconds: 300));
    return _refreshAccessToken();
  }

  Future<bool?> _isRefreshTokenExpired() async {
    final refreshTokenExpiry = await Utils.getRefreshTokenExpiry();
    if (refreshTokenExpiry == null) {
      final storedRefresh = await secureStorage.read(key: 'refreshToken');
      if (storedRefresh == null || storedRefresh.isEmpty) return true;
      return null;
    }
    return refreshTokenExpiry.isBefore(DateTime.now());
  }

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final skipAuth = options.extra['skipAuth'] == true;
    if (!skipAuth && options.extra['skipAuthRefresh'] != true) {
      final expiresAt = await Utils.getAccessTokenExpiry();
      if (expiresAt != null &&
          expiresAt.isBefore(DateTime.now().add(const Duration(minutes: 1)))) {
        await _refreshAccessToken();
      }
    }
    if (!skipAuth) {
      final accessToken = await Utils.getAccessToken();
      final tempAccessToken = await Utils.getTemporaryAccessToken();
      final tokenType = await Utils.getTokenType();
      final resolvedToken = accessToken ??
          ((tempAccessToken?.trim().isNotEmpty ?? false)
              ? tempAccessToken
              : null);
      if (resolvedToken != null) {
        options.headers['Authorization'] =
            '${tokenType ?? 'Bearer'} $resolvedToken';
      }
    }

    final url = options.uri.toString();
    final safeHeaders = _redactHeaders(options.headers);
    final payload = _truncate(_stringify(_redactBody(options.data)));
    final query = options.queryParameters.isNotEmpty
        ? _truncate(_stringify(_redactBody(options.queryParameters)))
        : '';

    logger.info('Request: ${options.method} $url');
    if (AppEnv.enableNetworkPayloadLogs) {
      _debugLog(
        '${options.method} $url\nheaders=${_truncate(_stringify(safeHeaders))}'
        '${query.isNotEmpty ? '\nquery=$query' : ''}'
        '${payload.isNotEmpty ? '\nbody=$payload' : ''}',
      );
      logger.info('Request headers: $safeHeaders');
      if (payload.isNotEmpty) logger.info('Request payload: $payload');
      if (query.isNotEmpty) logger.info('Request query: $query');
    }
    super.onRequest(options, handler);
  }

  @override
  void onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) {
    final url = response.requestOptions.uri.toString();
    final dataText = _truncate(_stringify(_redactBody(response.data)));
    logger.info('Response: ${response.statusCode} $url');
    if (AppEnv.enableNetworkPayloadLogs) {
      _debugLog(
        'RESPONSE ${response.statusCode} $url\n$dataText',
      );
      logger.info('Response payload: $dataText');
    }
    super.onResponse(response, handler);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final url = err.requestOptions.uri.toString();
    final status = err.response?.statusCode;
    final dataText = _truncate(_stringify(_redactBody(err.response?.data)));
    if (AppEnv.enableNetworkPayloadLogs) {
      _debugLog(
        'ERROR ${status ?? '-'} $url\n${err.message ?? ''}'
        '${dataText.isNotEmpty ? '\n$dataText' : ''}',
      );
    }
    logger.error(
      'Error: ${err.message}',
      error: err,
      stackTrace: err.stackTrace,
    );
    final skipAuth = err.requestOptions.extra['skipAuth'] == true;
    if (err.response?.statusCode == 503) {
      await _handleServerUnavailable();
    } else if (err.response?.statusCode == 401 && !skipAuth) {
      final alreadyRetried = err.requestOptions.extra['retried'] == true;
      final isRefreshCall = err.requestOptions.extra['isRefresh'] == true;
      if (!alreadyRetried && !isRefreshCall) {
        final refreshed = await _refreshAccessTokenWithRetry();
        if (refreshed) {
          final options = err.requestOptions;
          options.extra['retried'] = true;
          final response = await DioService.instance.client.fetch(options);
          handler.resolve(response);
          return;
        }
      }
      final refreshExpired = await _isRefreshTokenExpired();
      if (refreshExpired == true) {
        _showAppError(AppErrorMessages.sessionExpired);
        final context = navigatorKey.currentContext;
        if (context != null) {
          try {
            // ignore: use_build_context_synchronously
            await ProviderScope.containerOf(context)
                .read(authControllerProvider.notifier)
                .logout();
          } catch (_) {
            await _clearSession();
          }
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!context.mounted) return;
            context.go(RouteConstants.login);
          });
        } else {
          await _clearSession();
        }
      } else {
        _showAppError(AppErrorMessages.sessionRefreshFailed);
      }
    } else if (err.response?.statusCode == 404) {
      _showAppError(AppErrorMessages.sessionExpired);
      final context = navigatorKey.currentContext;
      if (context != null) {
        try {
          await ProviderScope.containerOf(context)
              .read(authControllerProvider.notifier)
              .logout();
        } catch (_) {
          await _clearSession();
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          context.go(RouteConstants.login);
        });
      } else {
        await _clearSession();
      }
    } else if (err.error is CertificateNotVerifiedException ||
        err.error is CertificateCouldNotBeVerifiedException) {
      _showAppError(AppErrorMessages.secureConnection);
    }
    super.onError(err, handler);
  }

  void _showAppError(String message) {
    AppSnackbar.show(
      message,
      type: AppSnackbarType.error,
    );
  }

  Future<void> _handleServerUnavailable() async {
    if (_handlingServerUnavailable) return;
    _handlingServerUnavailable = true;
    try {
      final context = navigatorKey.currentContext;
      if (context == null) return;

      final container = ProviderScope.containerOf(context);
      container.read(homeControllerProvider.notifier).showServerUnavailable();

      final authState = container.read(authControllerProvider);
      if (!authState.isAuthenticated && !authState.hasTemporaryAccess) {
        _showAppError(AppErrorMessages.serverUnavailable);
        return;
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        final router = GoRouter.maybeOf(context);
        router?.go(RouteConstants.home);
      });
    } finally {
      Future<void>.delayed(const Duration(milliseconds: 800), () {
        _handlingServerUnavailable = false;
      });
    }
  }
}
