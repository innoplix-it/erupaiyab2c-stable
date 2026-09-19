import 'package:dio/dio.dart';
import 'package:http_certificate_pinning/http_certificate_pinning.dart';

import '../constants/app_error_messages.dart';

class ErrorMessageUtils {
  ErrorMessageUtils._();

  static String from(
    Object error, {
    String fallback = AppErrorMessages.generic,
  }) {
    if (error is DioException) {
      final apiMessage = fromResponseData(error.response?.data);
      if (apiMessage != null) return apiMessage;

      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return AppErrorMessages.timeout;
        case DioExceptionType.connectionError:
          return AppErrorMessages.network;
        case DioExceptionType.cancel:
          return fallback;
        default:
          break;
      }

      if (error.error is CertificateNotVerifiedException ||
          error.error is CertificateCouldNotBeVerifiedException) {
        return AppErrorMessages.secureConnection;
      }
      if (error.error.toString().contains('SocketException')) {
        return AppErrorMessages.network;
      }
      return fallback;
    }

    final raw = error.toString().trim();
    if (raw.startsWith('Exception: ')) {
      final message = raw.substring('Exception: '.length).trim();
      if (message.isNotEmpty && !_isTechnicalDioMessage(message)) {
        return message;
      }
    }
    if (_isTechnicalDioMessage(raw)) return fallback;
    return fallback;
  }

  static String? fromResponseData(Object? data) {
    if (data is! Map) return null;

    final messages = data['messages'];
    if (messages is Map) {
      final nested = (messages['error'] ?? messages['message'])
          ?.toString()
          .trim();
      if (nested != null && nested.isNotEmpty) return nested;
    }

    final message = data['message']?.toString().trim();
    if (message != null && message.isNotEmpty) return message;

    final error = data['error']?.toString().trim();
    if (error != null && error.isNotEmpty && error.toLowerCase() != 'true') {
      return error;
    }
    return null;
  }

  static bool _isTechnicalDioMessage(String text) {
    final lower = text.toLowerCase();
    return lower.contains('dioexception') ||
        lower.contains('the request connection took longer') ||
        lower.contains('this exception was thrown because the response') ||
        lower.contains('status code of') ||
        lower.contains('xmlhttprequest error') ||
        lower.contains('handshakeexception') ||
        lower.contains('socketexception');
  }
}
