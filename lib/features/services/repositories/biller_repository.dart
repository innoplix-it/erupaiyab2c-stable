import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

import '../../../constants/api_constants.dart';
import '../../../services/dio_service.dart';
import '../../../services/logger_service.dart';
import '../../../services/payment_device_context_service.dart';
import '../models/bill_response_model.dart';
import '../models/biller_detail_model.dart';
import '../models/biller_model.dart';
import '../models/recharge_status_result.dart';
import '../models/service_payment_order_result.dart';

class BillerRepository {
  BillerRepository({Dio? dio}) : _dio = dio ?? DioService.instance.client;

  final Dio _dio;
  final Random _random = Random.secure();

  Never _throwApiMessage(DioException e, {String fallback = 'Request failed'}) {
    final data = e.response?.data;
    if (data is Map) {
      final direct = data['message']?.toString().trim();
      if (direct != null && direct.isNotEmpty) {
        throw Exception(direct);
      }
      final messages = data['messages'];
      if (messages is Map) {
        final nested =
            (messages['error'] ?? messages['message'] ?? '').toString().trim();
        if (nested.isNotEmpty) {
          throw Exception(nested);
        }
      }
    }
    throw Exception(fallback);
  }

  Future<BillerListResponse> fetchBillers({
    required String categoryName,
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.billersEndpoint,
        queryParameters: {
          'category_name': categoryName,
          'page': page,
          'limit': limit,
          if (search != null && search.trim().isNotEmpty)
            'search': search.trim(),
        },
      );
      final payload = response.data as Map<String, dynamic>? ?? {};
      return BillerListResponse.fromJson(payload);
    } catch (e) {
      logger.error('Failed to fetch billers: $e', error: e);
      rethrow;
    }
  }

  Future<BillerDetail> fetchBillerDetails({
    required String billerId,
    String? categoryName,
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.billerParamsEndpoint,
        queryParameters: {
          'biller_id': billerId,
          if (categoryName != null && categoryName.trim().isNotEmpty)
            'category_name': categoryName.trim(),
        },
      );
      final payload = response.data as Map<String, dynamic>? ?? {};
      return BillerDetail.fromJson(payload);
    } catch (e) {
      logger.error('Failed to fetch biller details: $e', error: e);
      rethrow;
    }
  }

  Future<BillResponse> fetchBill({
    required String billerId,
    required Map<String, String> customerParams,
    required String planMdmRequirement,
  }) async {
    try {
      final data = <String, dynamic>{
        'billerid': billerId,
        'planMdmRequirement': planMdmRequirement,
      };
      for (final entry in customerParams.entries) {
        final rawKey = entry.key.trim();
        if (rawKey.toLowerCase() == 'service_name') {
          data['service_name'] = entry.value;
          continue;
        }
        final key = _buildCustomerParamKey(entry.key);
        if (key.isNotEmpty) {
          data[key] = entry.value;
        }
      }
      final response = await _dio.post(
        ApiConstants.fetchBillEndpoint,
        data: data,
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          validateStatus: (status) => status != null && status < 600,
        ),
      );
      final payload = response.data as Map<String, dynamic>? ?? {};
      final status = (payload['status'] ?? '').toString().toUpperCase();
      if (status != 'SUCCESS') {
        final note = (payload['note'] ?? '').toString().trim();
        throw BillerApiException(
          _extractBillFetchErrorMessage(payload),
          note: note,
        );
      }
      return BillResponse.fromJson(payload);
    } catch (e) {
      logger.error('Failed to fetch bill: $e', error: e);
      rethrow;
    }
  }

  // Deprecated: old API `api/bill/pay` is no longer used.
  // Use `createPayAllServicesOrder(...)` + `fetchRechargeStatus(...)`.
  // Future<BillPayResponse> payBill({...}) async { ... }

  Future<ServicePaymentOrderResult> createPayAllServicesOrder({
    required String billerId,
    required Map<String, String> customerParams,
    required String maskedIdentifier,
    required String amount,
    required String refId,
    required String fetchRefId,
    required List<String> paymentModes,
    required String billerName,
    required String paymentType,
    bool useWallet = false,
    String accountHolderName = '',
    String dueDate = '',
  }) async {
    try {
      Map<String, dynamic> deviceContext = const <String, dynamic>{};
      try {
        deviceContext = await const PaymentDeviceContextService().collect();
      } catch (_) {
        deviceContext = const <String, dynamic>{};
      }
      final data = <String, dynamic>{
        'payment_type': paymentType,
        'biller_name': billerName,
        'billerid': billerId,
        'amount': amount,
        'ref_id': refId,
        'fetch_ref_id': fetchRefId,
        'arr_bill_payment_modes': paymentModes.join(','),
        'masked_identifier': maskedIdentifier,
        'use_wallet': useWallet ? 1 : 0,
        'idempotency_key': _generateUuid(),
        if (accountHolderName.trim().isNotEmpty) ...{
          'accountHolderName': accountHolderName.trim(),
          'account_holder_name': accountHolderName.trim(),
        },
        if (dueDate.trim().isNotEmpty) ...{
          'dueDate': dueDate.trim(),
          'due_date': dueDate.trim(),
        },
        ...deviceContext,
      };

      for (final entry in customerParams.entries) {
        final key = _buildCustomerParamKey(entry.key);
        if (key.isNotEmpty) {
          data[key] = entry.value;
        }
      }

      if (kDebugMode) {
        logger.info('Pay-allservices order request payload: $data');
      }

      final response = await _dio.post(
        ApiConstants.payBillAllServicesEndpoint,
        data: data,
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
        ),
      );
      final payload = response.data as Map<String, dynamic>? ?? {};
      return ServicePaymentOrderResult.fromJson(payload);
    } on DioException catch (e, stackTrace) {
      if (e.type == DioExceptionType.badResponse) {
        _throwApiMessage(e,
            fallback: 'Failed to create order. Please try again.');
      }
      logger.error(
        'Failed to create pay-allservices order',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    } catch (e, stackTrace) {
      logger.error(
        'Failed to create pay-allservices order',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  String _generateUuid() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    String toHex(int value) => value.toRadixString(16).padLeft(2, '0');
    final hex = bytes.map(toHex).toList();

    return '${hex.sublist(0, 4).join()}'
        '${hex.sublist(4, 6).join()}-'
        '${hex.sublist(6, 8).join()}-'
        '${hex.sublist(8, 10).join()}-'
        '${hex.sublist(10, 16).join()}';
  }

  Future<RechargeStatusResult> fetchRechargeStatus({
    required String transactionId,
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.rechargeStatusEndpoint(transactionId),
        options: Options(
          validateStatus: (status) => status != null && status < 600,
        ),
      );
      final payload = response.data as Map<String, dynamic>? ?? {};
      return RechargeStatusResult.fromJson(payload);
    } catch (e, stackTrace) {
      logger.error(
        'Failed to fetch recharge status',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  String _buildCustomerParamKey(String paramName) {
    final trimmed = paramName.trim();
    if (trimmed.isEmpty) return '';
    if (trimmed.toLowerCase().endsWith('parameter')) {
      return trimmed;
    }
    return '${trimmed}_parameter';
  }

  String _extractBillFetchErrorMessage(Map<String, dynamic> payload) {
    final body = payload['payload'] as Map<String, dynamic>? ?? {};
    final topLevelMessage = payload['message']?.toString().trim();
    if (topLevelMessage != null && topLevelMessage.isNotEmpty) {
      return topLevelMessage;
    }
    final message = body['message']?.toString().trim();
    if (message != null && message.isNotEmpty) return message;
    final errors = body['errors'];
    if (errors is List && errors.isNotEmpty) {
      final first = errors.first;
      if (first is Map) {
        final reason = first['reason']?.toString().trim();
        if (reason != null && reason.isNotEmpty) return reason;
        final fallback = first['message']?.toString().trim();
        if (fallback != null && fallback.isNotEmpty) return fallback;
      }
    }
    final code = payload['code']?.toString();
    if (code != null && code.isNotEmpty) {
      return 'Failed to fetch bill (code $code).';
    }
    return 'Failed to fetch bill. Please try again.';
  }
}

class BillerApiException implements Exception {
  BillerApiException(this.message, {this.note});

  final String message;
  final String? note;

  @override
  String toString() => message;
}
